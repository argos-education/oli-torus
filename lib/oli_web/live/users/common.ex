defmodule OliWeb.Users.Common do
  use OliWeb, :surface_component

  alias Oli.Accounts

  def render(assigns) do
    ~F"""
    <div>nothing</div>
    """
  end

  def render_email_column(
        assigns,
        %{
          email: email,
          email_confirmed_at: email_confirmed_at,
          invitation_accepted_at: invitation_accepted_at,
          locked_at: locked_at
        } = row,
        _
      ) do
    checkmark =
      case row do
        %{independent_learner: false} ->
          nil

        _ ->
          cond do
            Accounts.user_confirmation_pending?(row) ->
              ~F"""
              <span data-toggle="tooltip" data-html="true" title={"<b>Confirmation Pending</b> sent to #{email}"}>
                <i class="las la-paper-plane text-secondary"></i>
              </span>
              """

            not is_nil(email_confirmed_at) ->
              ~F"""
              <span data-toggle="tooltip" data-html="true" title={"<b>Email Confirmed</b> on #{date(email_confirmed_at)}"}>
                <i class="las la-check text-success"></i>
              </span>
              """

            not is_nil(invitation_accepted_at) ->
              ~F"""
              <span data-toggle="tooltip" data-html="true" title={"<b>Invitation Accepted</b> on #{date(invitation_accepted_at)}"}>
                <i class="las la-check text-success"></i>
              </span>
              """

            true ->
              ~F"""
              <span data-toggle="tooltip" data-html="true" title={"<b>Invitation Pending</b> sent to #{email}"}>
                <i class="las la-paper-plane text-secondary"></i>
              </span>
              """
          end
      end

    ~F"""
      <div class="d-flex flex-row">
       {email} <div class="flex-grow-1"></div> {checkmark}
      </div>
      <div>
        {#if !is_nil(locked_at)}
          <span class="badge badge-warning"><i class="las la-user-lock"></i> Account Locked</span>
        {/if}
      </div>
    """
  end
end