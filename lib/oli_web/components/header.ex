defmodule OliWeb.Components.Header do
  use OliWeb, :html

  import Phoenix.HTML.Link
  import OliWeb.ViewHelpers, only: [brand_logo: 1]

  import OliWeb.Components.Delivery.Utils

  alias OliWeb.Router.Helpers, as: Routes
  alias OliWeb.Components.Delivery.UserAccount
  alias OliWeb.Components.Delivery.Buttons
  alias OliWeb.Breadcrumb.BreadcrumbTrailLive
  alias OliWeb.Common.SessionContext

  attr(:ctx, SessionContext, required: true)

  def header(assigns) do
    assigns = assign(assigns, :is_system_admin, assigns[:is_system_admin] || false)

    ~H"""
    <nav class="navbar py-1 bg-delivery-header dark:bg-delivery-header-dark shadow-sm">
      <div class="container mx-auto flex flex-row">
        <a
          class="navbar-brand torus-logo my-1 mr-auto"
          href={
            case assigns[:logo_link] do
              nil ->
                logo_link_path(assigns)

              logo_link ->
                logo_link
            end
          }
        >
          <%= brand_logo(Map.merge(assigns, %{class: "d-inline-block align-top mr-2"})) %>
        </a>

        <%= if not is_preview_mode?(assigns) do %>
          <div class="inline-flex items-center mr-2">
            <Buttons.help_button />
          </div>
        <% end %>

        <%= cond do %>
          <% assigns[:hide_user] == true -> %>
          <% is_preview_mode?(assigns) -> %>
            <div class="dropdown relative">
              <button
                class="
                  dropdown-toggle
                  px-6
                  py-2.5
                  font-medium
                  text-sm
                  leading-tight
                  transition
                  duration-150
                  ease-in-out
                  flex
                  items-center
                  whitespace-nowrap
                "
                type="button"
                data-bs-toggle="dropdown"
                aria-expanded="false"
              >
                <div class="block lg:inline-block lg:mt-0 text-grey-darkest mr-4">
                  <div class="username">
                    Preview
                  </div>
                </div>
                <div class="user-icon">
                  <%= user_icon(%{}) %>
                </div>
              </button>
            </div>
          <% user_signed_in?(assigns) -> %>
            <div class="max-w-[400px] my-auto">
              <UserAccount.menu id="user-account-menu" ctx={@ctx} is_system_admin={@is_system_admin} />
            </div>
          <% true -> %>
            <div class="inline-flex items-center">
              <%= link to: Routes.pow_session_path(OliWeb.Endpoint, :new), class: "btn btn-primary btn-sm mr-2 inline-flex items-center" do %>
                <span class="hidden sm:inline">Learner/Educator Sign In</span>
                <span class="inline sm:hidden">Sign In</span>
              <% end %>
            </div>
        <% end %>
      </div>
    </nav>
    <.delivery_breadcrumb
      breadcrumbs={assigns[:breadcrumbs]}
      socket_or_conn={socket_or_conn(assigns)}
    />
    """
  end

  def delivery_header(assigns) do
    ~H"""
    <nav class="bg-primary-24 h-[111px] flex items-center pl-4 pr-10">
      <a class="navbar-brand torus-logo my-1 mr-auto" href={~p"/"}>
        <%= brand_logo(Map.merge(assigns, %{class: "d-inline-block align-top mr-2"})) %>
      </a>
      <.sign_in_button href="/session/new" request_path={assigns.conn.request_path}>
        For Instructors
      </.sign_in_button>
      <.sign_in_button href="/authoring/session/new" request_path={assigns.conn.request_path}>
        For Course Authors
      </.sign_in_button>
      <.button
        id="support-button"
        href="#"
        class="pt-[12px] text-high-24 hover:text-high-24 hover:underline hover:underline-offset-8"
        onclick="window.showHelpModal();"
        phx-click={JS.dispatch("maybe_add_underline_classes", to: "#help-modal")}
      >
        Support
      </.button>
    </nav>
    """
  end

  attr :href, :string, required: true
  attr :request_path, :string, required: true

  slot :inner_block, required: true

  def sign_in_button(assigns) do
    ~H"""
    <.button
      href={@href}
      class={"pt-[12px] text-high-24 hover:text-high-24 hover:underline hover:underline-offset-8" <> maybe_add_underlined_classes(@request_path, @href)}
    >
      <%= render_slot(@inner_block) %>
    </.button>
    """
  end

  attr(:breadcrumbs, :list, required: true)
  attr(:socket_or_conn, :any, required: true)

  def delivery_breadcrumb(assigns) do
    ~H"""
    <%= if delivery_breadcrumbs?(assigns) do %>
      <div class="container mx-auto my-2">
        <nav class="breadcrumb-bar d-flex align-items-center mt-3 mb-1">
          <div class="flex-1">
            <%= live_render(@socket_or_conn, BreadcrumbTrailLive,
              id: "breadcrumb-trail",
              session: %{"breadcrumbs" => @breadcrumbs}
            ) %>
          </div>
        </nav>
      </div>
    <% end %>
    """
  end

  defp maybe_add_underlined_classes(path, path), do: " underline underline-offset-8"
  defp maybe_add_underlined_classes(_request_path, _href), do: ""
end
