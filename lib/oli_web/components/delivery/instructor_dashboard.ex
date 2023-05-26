defmodule OliWeb.Components.Delivery.InstructorDashboard do
  use Phoenix.Component

  import OliWeb.ViewHelpers, only: [brand_logo: 1]

  alias OliWeb.Router.Helpers, as: Routes
  alias Oli.Accounts.User
  alias Oli.Delivery.Sections.Section
  alias OliWeb.Components.Delivery.UserAccountMenu
  alias OliWeb.Components.Header

  attr(:current_user, User)
  attr(:section, Section)
  attr(:breadcrumbs, :list, required: true)
  attr(:socket_or_conn, :any, required: true)
  attr(:preview_mode, :boolean, default: false)
  attr(:view, :atom, required: true)

  def main_layout(assigns) do
    ~H"""
      <div class="flex-1 flex flex-col h-screen">
        <.header socket_or_conn={@socket_or_conn} view={@view} current_user={@current_user} section={@section} preview_mode={@preview_mode} />
        <.section_details_header section={@section}/>
        <Header.delivery_breadcrumb {assigns} />

        <div class="relative flex-1 flex flex-col pt-4 pb-[60px]">

          <%= render_slot(@inner_block) %>

          <%= Phoenix.View.render OliWeb.LayoutView, "_delivery_footer.html", assigns %>
        </div>
      </div>
    """
  end

  defmodule TabLink do
    defstruct [
      :label,
      :path,
      :badge,
      :active
    ]

    @type t() :: %__MODULE__{
            label: String.t() | Function.t(),
            path: String.t(),
            badge: Integer.t(),
            active: Boolean.t()
          }
  end

  attr(:tabs, :list, required: true)

  def tabs(assigns) do
    ~H"""
      <div class="container mx-auto my-4">
        <ul class="nav nav-tabs flex flex-col md:flex-row flex-wrap list-none border-b-0 pl-0 mb-4" id="tabs-tab"
          role="tablist">

          <%= for %TabLink{label: label, path: path, badge: badge, active: active} <- @tabs do %>
            <li class="nav-item" role="presentation">
              <.link patch={path}
                class={"
                  block
                  border-x-0 border-t-0 border-b-2
                  px-3
                  py-3
                  my-2
                  text-body-color
                  dark:text-body-color-dark
                  bg-transparent
                  hover:no-underline
                  hover:text-body-color
                  hover:border-delivery-primary-200
                  focus:border-delivery-primary-200
                  #{if active, do: "!border-delivery-primary active", else: "border-transparent"}
                "}>
                <%= if is_function(label), do: label.(), else: label %>
                  <%= if badge do %>
                  <span class="text-xs inline-block py-1 px-2 ml-2 leading-none text-center whitespace-nowrap align-baseline font-bold bg-delivery-primary text-white rounded"><%= badge %></span>
                  <% end %>
              </.link>
            </li>
          <% end %>

        </ul>
      </div>
    """
  end

  defp logo_link(nil, _), do: Routes.delivery_path(OliWeb.Endpoint, :open_and_free_index)

  defp logo_link(section, preview_mode) do
    if preview_mode do
      Routes.instructor_dashboard_path(OliWeb.Endpoint, :preview, section.slug, :content)
    else
      Routes.page_delivery_path(OliWeb.Endpoint, :index, section.slug)
    end
  end

  attr(:path, :string, required: true)
  attr(:active, :boolean, default: false)
  slot(:inner_block)

  defp header_link(assigns) do
    ~H"""
      <.link
        href={@path}
        class={"
          flex
          flex-col
          justify-center
          px-2
          text-white
          hover:text-white
          hover:no-underline
          cursor-pointer
          border-b-4
          #{if @active, do: "!border-white/75", else: "border-transparent"}
          hover:border-white/50
        "}>
        <div class="mx-2"><%= render_slot(@inner_block) %></div>
      </.link>
    """
  end

  defp header_link_path(_socket_or_conn, %Section{slug: slug}, view, _preview_mode = true) do
    Routes.instructor_dashboard_path(OliWeb.Endpoint, :preview, slug, view)
  end

  defp header_link_path(socket_or_conn, %Section{slug: slug}, view, _preview_mode) do
    Routes.live_path(
      socket_or_conn,
      OliWeb.Delivery.InstructorDashboard.InstructorDashboardLive,
      slug,
      view
    )
  end

  defp is_active?(current_view, view), do: current_view == view

  attr(:current_user, User)
  attr(:section, Section)
  attr(:preview_mode, :boolean, default: false)
  attr(:socket_or_conn, :any, required: true)
  attr(:view, :atom, required: true)

  def header(assigns) do
    ~H"""
      <div class="w-full bg-delivery-header text-white border-b border-slate-600">
        <div class="container mx-auto flex flex-row">
          <div class="flex items-center">
            <a class="navbar-brand dark torus-logo my-1 mr-auto" href={logo_link(@section, @preview_mode)}>
              <%= brand_logo(Map.merge(assigns, %{class: "d-inline-block align-top mr-2"})) %>
            </a>
          </div>

          <div class="flex flex-1 flex-row justify-center">
            <.header_link path={header_link_path(@socket_or_conn, @section, :overview, @preview_mode)} active={is_active?(@view, :overview)}>Overview</.header_link>
            <.header_link path={header_link_path(@socket_or_conn, @section, :reports, @preview_mode)} active={is_active?(@view, :reports)}>Reports</.header_link>
            <.header_link path={header_link_path(@socket_or_conn, @section, :manage, @preview_mode)} active={is_active?(@view, :manage)}>Manage</.header_link>
            <.header_link path={header_link_path(@socket_or_conn, @section, :discussions, @preview_mode)} active={is_active?(@view, :discussions)}>Discussion Activity</.header_link>
          </div>

          <div>
            <%= if @preview_mode do %>
              <UserAccountMenu.preview_user />
            <% else %>
              <UserAccountMenu.menu current_user={@current_user} />
            <% end %>
          </div>

          <div class="flex items-center border-l border-slate-300 my-2">
            <button
              class="
                btn
                rounded
                ml-4
                no-underline
                text-slate-100
                hover:no-underline
                hover:bg-delivery-header-700
                active:bg-delivery-header-600
              "
              data-bs-toggle="modal"
              data-bs-target="#help-modal">
              <i class="fa-regular fa-circle-question fa-lg"></i>
            </button>
          </div>
        </div>
      </div>
    """
  end

  attr(:section, Section)

  def section_details_header(%{section: nil}), do: nil

  def section_details_header(assigns) do
    ~H"""
    <div class="w-full bg-delivery-header text-white py-8">
      <div class="container mx-auto flex flex-row justify-between">
        <div class="flex-1 flex items-center text-[1.5em]">
          <div class="font-bold text-slate-300">
            <%= @section.title %>
          </div>
          <%!-- <div class="border-l border-white ml-4 pl-4">
            Section 2360
          </div> --%>
          <%!-- <div class="font-thin border-l border-white ml-4 pl-4">
            Mon/Wed 12:00 PM
          </div> --%>
        </div>
      </div>
    </div>
    """
  end
end