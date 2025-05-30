defmodule OliWeb.InviteController do
  use OliWeb, :controller

  alias Lti_1p3.Roles.ContextRoles
  alias Oli.Repo
  alias Oli.Accounts
  alias Oli.Accounts.AuthorToken
  alias Oli.Accounts.UserToken
  alias Oli.Delivery.Sections
  alias Oli.{Email, Mailer}
  alias OliWeb.UserSessionController
  alias OliWeb.AuthorSessionController

  def index(conn, _params) do
    render_invite_page(conn, "index.html", title: "Invite")
  end

  def create(conn, %{"email" => email} = params) do
    g_recaptcha_response = Map.get(params, "g-recaptcha-response", "")

    case Oli.Utils.Recaptcha.verify(g_recaptcha_response) do
      {:success, true} ->
        if is_nil(Accounts.get_author_by_email(email)) do
          invite_author(conn, email)
        else
          conn
          |> put_flash(:error, "Author with email #{email} already exists.")
          |> redirect(to: Routes.invite_path(conn, :index))
        end

      {:success, false} ->
        conn
        |> put_flash(:error, "reCaptcha failed, please try again")
        |> redirect(to: Routes.invite_path(conn, :index))
    end
  end

  @doc """
  After a user accepts an intivation we log the user in and redirects him to the section.
  """
  def accept_user_invitation(conn, %{"email" => email, "section_slug" => section_slug} = params) do
    params =
      params
      |> put_in(["user", "email"], email)
      |> put_in(["user", "request_path"], ~p"/sections/#{section_slug}")

    UserSessionController.create(conn, params, flash_message: nil)
  end

  @doc """
  After an author accepts a collaboration intivation we log the author in and redirect him to the project.
  """
  def accept_collaborator_invitation(
        conn,
        %{"email" => email, "project_slug" => project_slug} = params
      ) do
    params =
      params
      |> put_in(["author", "email"], email)
      |> put_in(
        ["author", "request_path"],
        ~p"/workspaces/course_author/#{project_slug}/overview"
      )

    AuthorSessionController.create(conn, params, flash_message: nil)
  end

  @doc """
  After an author accepts an intivation we log the author in and redirect him to admin page.
  """
  def accept_author_invitation(conn, %{"email" => email} = params) do
    params =
      params
      |> put_in(["author", "email"], email)
      |> put_in(["author", "request_path"], ~p"/workspaces/course_author/")

    AuthorSessionController.create(conn, params, flash_message: nil)
  end

  @doc """
  Bulk invite users to a section, considering the different cases of users:

  - Users that are not in the system (non_existing_users_emails): create them, enroll them, create invitation token and send email invitation
  - Users that are in the system but not enrolled (not_enrolled_users_emails): enroll them, create invitation token, send email invitation
  - Users that are in the system with status "pending_confirmation", "rejected" or "suspended" (not_active_enrolled_users_emails):
    - update their status to "pending_confirmation"
    - create user token (remove previous ones if any - this invalidates previous email invitations)
    - send email invitation
  """
  def create_bulk(conn, %{
        "non_existing_users_emails" => non_existing_users_emails,
        "not_enrolled_users_emails" => not_enrolled_users_emails,
        "not_active_enrolled_users_emails" => not_active_enrolled_users_emails,
        "role" => role,
        "section_slug" => section_slug,
        "inviter" => inviter
      }) do
    non_existing_users_emails = Jason.decode!(non_existing_users_emails)
    not_enrolled_users_emails = Jason.decode!(not_enrolled_users_emails)
    not_active_enrolled_users_emails = Jason.decode!(not_active_enrolled_users_emails)

    section = Sections.get_section_by_slug(section_slug)

    inviter_struct =
      if inviter == "author", do: conn.assigns.current_author, else: conn.assigns.current_user

    Ecto.Multi.new()
    |> Ecto.Multi.run(:new_users, fn _repo, _changes ->
      case Accounts.bulk_create_invited_users(non_existing_users_emails, inviter_struct) do
        {:error, reason} ->
          {:error, reason}

        {count, new_users} ->
          {:ok, {count, new_users}}
      end
    end)
    |> Ecto.Multi.run(:not_enrolled_users, fn _repo, _changes ->
      {:ok, Accounts.get_users_by_email(not_enrolled_users_emails)}
    end)
    |> Ecto.Multi.run(:not_active_enrolled_users, fn _repo, _changes ->
      {:ok, Accounts.get_users_by_email(not_active_enrolled_users_emails)}
    end)
    |> Ecto.Multi.run(:enroll_users, fn _repo,
                                        %{
                                          new_users: {_, new_users},
                                          not_enrolled_users: not_enrolled_users
                                        } ->
      do_section_enrollment(new_users ++ not_enrolled_users, section, role)
    end)
    |> Ecto.Multi.run(:update_enrollments, fn _repo, _ ->
      {:ok,
       Sections.bulk_update_enrollment_status(
         section_slug,
         not_active_enrolled_users_emails,
         :pending_confirmation
       )}
    end)
    |> Ecto.Multi.run(:remove_previous_invitations, fn _repo, _ ->
      {:ok,
       Accounts.delete_enrollment_invitation_tokens(
         section_slug,
         not_active_enrolled_users_emails
       )}
    end)
    |> Ecto.Multi.run(:email_data, fn _repo,
                                      %{
                                        new_users: {_, new_users},
                                        not_enrolled_users: not_enrolled_users,
                                        not_active_enrolled_users: not_active_enrolled_users
                                      } ->
      bulk_create_invitation_tokens(
        new_users ++ not_enrolled_users ++ not_active_enrolled_users,
        section_slug
      )
    end)
    |> Ecto.Multi.run(:send_invitations, fn _repo, %{email_data: email_data} ->
      case send_email_invitations(email_data, inviter_struct.name, role, section.title) do
        :ok ->
          {:ok, :ok}

        {:error, reason} ->
          {:error, reason}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Users were invited successfully")
        |> redirect(
          to:
            ~p"/sections/#{section_slug}/instructor_dashboard/overview/students?filter_by=pending_confirmation"
        )

      {:error, _} ->
        conn
        |> put_flash(:error, "An error occurred while inviting users")
        |> redirect(to: ~p"/sections/#{section_slug}/instructor_dashboard/overview/students")
    end
  end

  defp do_section_enrollment(users, section, role) do
    context_identifier = contextualize_role(role)
    context_role = ContextRoles.get_role(context_identifier)
    user_ids = Enum.map(users, & &1.id)

    Sections.enroll(user_ids, section.id, [context_role], :pending_confirmation)
  end

  defp bulk_create_invitation_tokens(users, section_slug) do
    now = Oli.DateTime.utc_now() |> DateTime.truncate(:second)

    %{email_data: email_data, user_tokens: user_tokens} =
      users
      |> Enum.reduce(%{email_data: [], user_tokens: []}, fn user, acc ->
        {non_hashed_token, user_token} =
          UserToken.build_email_token(user, "enrollment_invitation:#{section_slug}")

        user_token =
          %{
            user_id: user_token.user_id,
            token: user_token.token,
            context: user_token.context,
            sent_to: user_token.sent_to,
            inserted_at: now
          }

        %{
          acc
          | email_data: [
              %{sent_to: user_token.sent_to, token: non_hashed_token} | acc.email_data
            ],
            user_tokens: [user_token | acc.user_tokens]
        }
      end)

    {_count, _user_tokens} = Repo.insert_all(UserToken, user_tokens)

    {:ok, email_data}
  end

  defp send_email_invitations(email_data, inviter_name, role, section_title) do
    Enum.each(email_data, fn data ->
      Email.create_email(
        data.sent_to,
        "You were invited as #{if role == "instructor", do: "an instructor", else: "a student"} to \"#{section_title}\"",
        :enrollment_invitation,
        %{
          inviter: inviter_name,
          url: url(OliWeb.Endpoint, ~p"/users/invite/#{data.token}"),
          role: role,
          section_title: section_title,
          button_label: "Go to invitation"
        }
      )
      |> Mailer.deliver()
    end)
  end

  defp contextualize_role("instructor"), do: :context_instructor
  defp contextualize_role(_role), do: :context_learner

  defp render_invite_page(conn, page, keywords) do
    render(conn, page, Keyword.put_new(keywords, :active, :invite))
  end

  defp invite_author(conn, email) do
    with {:ok, author} <- Accounts.create_invited_author(email),
         {:ok, email_data} <- create_author_invitation_token(author),
         {:ok, _mail} <-
           deliver_author_invitation_email(email_data, conn.assigns.current_author.name) do
      conn
      |> put_flash(:info, "Author invitation sent successfully.")
      |> redirect(to: Routes.invite_path(conn, :index))
    else
      {:error, message} ->
        conn
        |> put_flash(:error, "We couldn't invite #{email}. #{message}")
        |> redirect(to: Routes.invite_path(conn, :index))
    end
  end

  defp create_author_invitation_token(author) do
    {non_hashed_token, author_token} =
      AuthorToken.build_email_token(author, "author_invitation")

    Oli.Repo.insert!(author_token)

    {:ok, %{sent_to: author_token.sent_to, token: non_hashed_token}}
  end

  defp deliver_author_invitation_email(email_data, invited_by) do
    Email.create_email(
      email_data.sent_to,
      "You were invited to create an authoring account",
      :author_invitation,
      %{
        url: url(OliWeb.Endpoint, ~p"/authors/invite/#{email_data.token}"),
        invited_by: invited_by
      }
    )
    |> Mailer.deliver()
  end
end
