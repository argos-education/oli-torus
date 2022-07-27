defmodule OliWeb.InstitutionControllerTest do
  use OliWeb.ConnCase

  import ExUnit.CaptureLog

  alias Oli.Repo
  alias Oli.Accounts
  alias Oli.Accounts.Author
  alias Oli.Institutions
  alias Oli.Institutions.Institution
  alias Oli.Lti.Tool.Registration
  alias Oli.Lti.Tool.Deployment
  alias Oli.Institutions.PendingRegistration

  @create_attrs %{
    country_code: "some country_code",
    institution_email: "some institution_email",
    institution_url: "some institution_url",
    name: "some name"
  }
  @update_attrs %{
    country_code: "some updated country_code",
    institution_email: "some updated institution_email",
    institution_url: "some updated institution_url",
    name: "some updated name"
  }
  @invalid_attrs %{
    country_code: nil,
    institution_email: nil,
    institution_url: nil,
    name: nil
  }

  setup [:create_institution]

  describe "index" do
    test "lists all institutions", %{conn: conn} do
      conn = get(conn, Routes.institution_path(conn, :index))
      assert html_response(conn, 200) =~ "some name"
    end
  end

  describe "new institution" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.institution_path(conn, :new))
      assert html_response(conn, 200) =~ "Register Institution"
    end
  end

  describe "create institution" do
    test "redirects to page index when data is valid", %{conn: conn} do
      conn = post(conn, Routes.institution_path(conn, :create), institution: @create_attrs)

      assert redirected_to(conn) == Routes.institution_path(conn, :index)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.institution_path(conn, :create), institution: @invalid_attrs)
      assert html_response(conn, 200) =~ "Register Institution"
    end
  end

  describe "show institution" do
    test "renders institution details", %{conn: conn, institution: institution} do
      conn = get(conn, Routes.institution_path(conn, :show, institution))
      assert html_response(conn, 200) =~ "some name"

      assert html_response(conn, 200) =~
               "href=\"#{Routes.discount_path(OliWeb.Endpoint, :institution, institution.id)}\""
    end

    test "renders institution registration details", %{conn: conn, institution: institution} do
      jwk = jwk_fixture()

      %Registration{id: registration_id} = registration_fixture(%{tool_jwk_id: jwk.id})

      %Deployment{deployment_id: deployment_id} =
        deployment_fixture(%{institution_id: institution.id, registration_id: registration_id})

      conn = get(conn, Routes.institution_path(conn, :show, institution))
      assert html_response(conn, 200) =~ deployment_id
    end
  end

  describe "edit institution" do
    test "renders form for editing chosen institution", %{conn: conn, institution: institution} do
      conn = get(conn, Routes.institution_path(conn, :edit, institution))
      assert html_response(conn, 200) =~ "Edit Institution"
    end
  end

  describe "update institution" do
    test "redirects when data is valid", %{conn: conn, author: author, institution: institution} do
      conn =
        put(conn, Routes.institution_path(conn, :update, institution), institution: @update_attrs)

      assert redirected_to(conn) == Routes.institution_path(conn, :show, institution)

      conn =
        recycle(conn)
        |> Pow.Plug.assign_current_user(author, OliWeb.Pow.PowHelpers.get_pow_config(:author))

      conn = get(conn, Routes.institution_path(conn, :show, institution))
      assert html_response(conn, 200) =~ "some updated country_code"
    end

    test "renders errors when data is invalid", %{conn: conn, institution: institution} do
      conn =
        put(conn, Routes.institution_path(conn, :update, institution), institution: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Institution"
    end
  end

  describe "delete institution" do
    test "deletes chosen institution", %{conn: conn, institution: institution} do
      conn = delete(conn, Routes.institution_path(conn, :delete, institution))
      assert redirected_to(conn) == Routes.institution_path(conn, :index)

      institution_id = institution.id

      assert %Institution{id: ^institution_id} =
               Institutions.get_institution_by!(%{status: :deleted})
    end
  end

  describe "approve registration" do
    test "approves the chosen registration", %{conn: conn} do
      pending_registration = pending_registration_fixture()

      pending_registration_attrs =
        %{}
        |> Map.merge(PendingRegistration.institution_attrs(pending_registration))
        |> Map.merge(PendingRegistration.registration_attrs(pending_registration))

      assert capture_log(fn ->
               conn =
                 put(conn, Routes.institution_path(conn, :approve_registration), %{
                   "pending_registration" => pending_registration_attrs
                 })

               assert redirected_to(conn) ==
                        Routes.institution_path(conn, :index) <> "#pending-registrations"

               assert Institutions.count_pending_registrations() == 0
             end) =~ "This message cannot be sent because SLACK_WEBHOOK_URL is not configured"
    end

    test "displays pending registration data", context do
      {:ok, conn: conn, context: session_context} = set_timezone(context)

      pending_registration = pending_registration_fixture()

      conn = get(conn, Routes.institution_path(conn, :index))

      assert html_response(conn, 200) =~ pending_registration.name
      assert html_response(conn, 200) =~ pending_registration.institution_url
      assert html_response(conn, 200) =~ pending_registration.institution_email

      assert html_response(conn, 200) =~
               OliWeb.Common.Utils.render_date(
                 pending_registration,
                 :inserted_at,
                 session_context
               )

      assert html_response(conn, 200) =~ "Decline"
    end
  end

  defp create_institution(%{conn: conn}) do
    {:ok, author} =
      Author.noauth_changeset(%Author{}, %{
        email: "test@test.com",
        given_name: "First",
        family_name: "Last",
        provider: "foo",
        system_role_id: Accounts.SystemRole.role_id().admin
      })
      |> Repo.insert()

    create_attrs = Map.put(@create_attrs, :author_id, author.id)
    {:ok, institution} = create_attrs |> Institutions.create_institution()

    conn =
      Pow.Plug.assign_current_user(conn, author, OliWeb.Pow.PowHelpers.get_pow_config(:author))

    {:ok, conn: conn, author: author, institution: institution}
  end
end
