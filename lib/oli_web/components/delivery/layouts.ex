defmodule OliWeb.Components.Delivery.Layouts do
  @moduledoc """
  This module contains the layout components for the delivery UI.
  """
  use OliWeb, :html
  use OliWeb, :verified_routes

  import OliWeb.Components.Utils

  alias Phoenix.LiveView.JS
  alias OliWeb.Common.SessionContext
  alias Oli.Authoring.Course.Project
  alias Oli.Delivery.Sections.Section
  alias Oli.Delivery.Sections.SectionResourceDepot
  alias Oli.Accounts.{User, Author}
  alias Oli.Branding
  alias OliWeb.Components.Delivery.UserAccount
  alias OliWeb.Icons
  alias Oli.Resources.Collaboration.CollabSpaceConfig
  alias OliWeb.Delivery.Student.Utils
  alias OliWeb.Workspaces.Utils, as: WorkspaceUtils

  attr(:breadcrumbs, :list, default: [])
  attr(:socket, :map, required: true)

  def breadcrumb_trail(%{breadcrumbs: breadcrumbs} = assigns) when not is_nil(breadcrumbs) do
    ~H"""
    <nav class="breadcrumb-bar flex flex-row align-items-center border-gray-300 dark:border-neutral-800">
      <%= live_render(@socket, OliWeb.Breadcrumb.BreadcrumbTrailWorkspaceLive,
        id: "breadcrumb-trail",
        session: %{"breadcrumbs" => @breadcrumbs}
      ) %>
    </nav>
    """
  end

  attr(:ctx, SessionContext)
  attr(:is_admin, :boolean, required: true)
  attr(:active_workspace, :atom, default: nil)
  attr(:section, Section, default: nil)
  attr(:project, Project, default: nil)
  attr(:preview_mode, :boolean)
  attr(:resource_title, :string, default: nil)

  attr(:sidebar_enabled, :boolean,
    default: false,
    doc:
      "Shows a mobile menu button on small form factors to trigger the sidebar navigation menu if the sidebar is enabled. Otherwise, only show the user account menu."
  )

  attr(:sidebar_expanded, :boolean, default: true)
  attr(:include_logo, :boolean, default: false)

  def header(assigns) do
    ~H"""
    <div
      id="header"
      class="sticky top-0 z-50 w-full py-2.5 h-14 flex flex-row gap-6 bg-delivery-header dark:bg-black border-b border-[#0F0D0F]/5 dark:border-[#0F0D0F]"
    >
      <.link
        :if={@include_logo}
        id="header_logo_button"
        class="w-48"
        navigate={logo_link_path(@preview_mode, @section, @ctx.user, @sidebar_expanded, @is_admin)}
      >
        <.logo_img section={@section} />
      </.link>
      <div class="flex flex-row flex-1 justify-end md:justify-between">
        <div class="flex hidden md:flex items-center flex-grow-1 dark:text-[#BAB8BF] text-base font-medium font-['Roboto']">
          <.title
            resource_title={@resource_title}
            section={@section}
            project={@project}
            preview_mode={@preview_mode}
          />
        </div>
        <div class="justify-end items-center flex shrink-0">
          <div class={[
            "justify-center items-center",
            if(@sidebar_enabled, do: "hidden md:flex", else: "")
          ]}>
            <%= if @active_workspace do %>
              <UserAccount.workspace_menu
                id="workspace-user-menu"
                ctx={@ctx}
                is_admin={@is_admin}
                active_workspace={@active_workspace}
              />
            <% else %>
              <UserAccount.menu
                id="user-account-menu"
                ctx={@ctx}
                is_admin={@is_admin}
                section={@section}
                show_support_link={!@sidebar_enabled}
              />
            <% end %>
          </div>
        </div>
        <div class="flex items-center p-2">
          <button
            class={[
              "py-1.5 px-3 rounded border border-transparent hover:border-gray-300 active:bg-gray-100",
              if(@sidebar_enabled, do: "md:hidden", else: "hidden")
            ]}
            phx-click={JS.toggle(to: "#mobile-nav-menu", display: "flex")}
          >
            <i class="fa-solid fa-bars"></i>
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr(:section, Section, default: nil)
  attr(:project, Project, default: nil)
  attr(:resource_title, :string, default: nil)
  attr(:preview_mode, :boolean)

  attr :rest, :global, include: ~w(class)

  def title(assigns) do
    ~H"""
    <span :if={@resource_title} class={["text-2xl text-bold", @rest[:class]]}>
      <%= @resource_title %>
    </span>
    <span :if={@section} class={["text-2xl text-bold", @rest[:class]]}>
      <%= @section.title %><%= if @preview_mode, do: " (Preview Mode)" %>
    </span>
    <span :if={@project} class={["text-2xl text-bold", @rest[:class]]}>
      <%= @project.title %>
    </span>
    """
  end

  attr(:ctx, SessionContext)
  attr(:is_admin, :boolean, required: true)
  attr(:section, Section, default: nil)
  attr(:active_tab, :atom)
  attr(:sidebar_expanded, :boolean, default: true)
  attr(:notes_enabled, :boolean, default: false)
  attr(:discussions_enabled, :boolean, default: false)
  attr(:preview_mode, :boolean)
  attr(:has_scheduled_resources?, :boolean, required: true)
  attr :notification_badges, :map, default: %{}

  def sidebar_nav(assigns) do
    ~H"""
    <div class="sticky top-0">
      <nav id="desktop-nav-menu" class={["
        transition-all
        duration-100
        z-50
        w-full
        hidden
        h-[100vh]
        scrollbar-hide
        md:flex
        flex-col
        justify-between
        md:w-[200px]
        shadow-sm
        bg-delivery-navbar
        dark:bg-delivery-navbar-dark
        overflow-hidden
      ", if(!@sidebar_expanded, do: "md:!w-[60px]")]} aria-expanded={"#{@sidebar_expanded}"}>
        <div class="w-full">
          <div
            class={[
              "h-14 w-48 py-2 flex shrink-0 border-b border-[#0F0D0F]/5 dark:border-[#0F0D0F]",
              if(!@sidebar_expanded, do: "w-14")
            ]}
            tab-index="0"
          >
            <.link
              id="logo_button"
              navigate={
                logo_link_path(
                  @preview_mode,
                  @section,
                  @ctx.user,
                  @sidebar_expanded,
                  @is_admin
                )
              }
            >
              <.logo_img section={@section} />
            </.link>
          </div>
          <.sidebar_toggler
            active={@active_tab}
            section={@section}
            preview_mode={@preview_mode}
            sidebar_expanded={@sidebar_expanded}
          />
          <.sidebar_links
            active_tab={@active_tab}
            section={@section}
            preview_mode={@preview_mode}
            sidebar_expanded={@sidebar_expanded}
            notes_enabled={@notes_enabled}
            discussions_enabled={@discussions_enabled}
            notification_badges={@notification_badges}
            has_scheduled_resources?={@has_scheduled_resources?}
          />
        </div>
        <div class="p-2 flex-col justify-center items-center gap-4 inline-flex">
          <.tech_support_button id="tech_support_sidebar_nav" show_text={@sidebar_expanded} />
          <.exit_course_button
            :if={is_independent_learner?(@ctx.user)}
            sidebar_expanded={@sidebar_expanded}
          />
        </div>
      </nav>
      <nav
        id="mobile-nav-menu"
        class="
        fixed
        z-50
        w-full
        mt-14
        hidden
        md:hidden
        flex-col
        shadow-sm
        bg-delivery-navbar
        dark:bg-delivery-navbar-dark
      "
        phx-click-away={JS.hide()}
      >
        <div class="px-4 py-2 flex flex-row items-center align-center justify-between border-b border-gray-300 dark:border-gray-800">
          <div class="flex items-center">
            <.tech_support_button id="mobile-tech-support" />
          </div>
          <UserAccount.menu
            id="mobile-user-account-menu-sidebar"
            ctx={@ctx}
            is_admin={@is_admin}
            section={@section}
            dropdown_class="absolute right-0 border"
          />
        </div>
        <.sidebar_links
          active_tab={@active_tab}
          section={@section}
          preview_mode={@preview_mode}
          notes_enabled={@notes_enabled}
          discussions_enabled={@discussions_enabled}
          has_scheduled_resources?={@has_scheduled_resources?}
        />
      </nav>
    </div>
    """
  end

  attr(:section, Section, default: nil)
  attr(:active, :atom, required: true, doc: "The current selected menu link")
  attr(:preview_mode, :boolean)
  attr(:notification_badges, :map, default: %{})
  attr(:sidebar_expanded, :boolean, default: true)

  def sidebar_toggler(assigns) do
    ~H"""
    <button
      role="toggle sidebar"
      phx-click={
        JS.patch(path_for(@active, @section, @preview_mode, !@sidebar_expanded))
        |> JS.dispatch("click", to: "button[role='update sidebar state on React']")
      }
      title={if @sidebar_expanded, do: "Minimize", else: "Expand"}
      class="flex items-center justify-center ml-auto w-6 h-6 bg-zinc-400 bg-opacity-20 hover:bg-opacity-40 rounded-tl-[52px] rounded-bl-[52px]"
    >
      <div class={if !@sidebar_expanded, do: "rotate-180"}>
        <Icons.left_chevron />
      </div>
    </button>
    """
  end

  attr(:preview_mode, :boolean)
  attr(:sidebar_expanded, :boolean)
  attr(:active_workspace, :atom)
  attr(:active_view, :atom, default: nil)
  attr(:resource_slug, :string, default: nil)
  attr(:uri, :string, default: "")

  def workspace_sidebar_toggler(assigns) do
    ~H"""
    <button
      role="toggle sidebar"
      phx-click={
        JS.patch(toggled_workspace_path(@sidebar_expanded, @uri))
        |> JS.hide(to: "div[role='expandable_submenu']")
        |> JS.dispatch("click", to: "button[role='update sidebar state on React']")
      }
      title={if @sidebar_expanded, do: "Minimize", else: "Expand"}
      class="flex items-center justify-center ml-auto w-6 h-6 bg-zinc-400 bg-opacity-20 hover:bg-opacity-40 rounded-tl-[52px] rounded-bl-[52px]"
    >
      <div class={if !@sidebar_expanded, do: "rotate-180"}>
        <Icons.left_chevron />
      </div>
    </button>
    """
  end

  attr(:ctx, SessionContext)
  attr(:is_admin, :boolean, required: true)
  attr(:active_workspace, :atom)
  attr(:active_view, :atom, default: nil)
  attr(:sidebar_expanded, :boolean)
  attr(:preview_mode, :boolean)
  attr(:resource_title, :string)
  attr(:resource_slug, :string)
  attr(:active_tab, :atom)
  attr(:uri, :string, default: "")

  def workspace_sidebar_nav(assigns) do
    ~H"""
    <div class="sticky top-0">
      <nav
        id="desktop-workspace-nav-menu"
        style="--header-height: 56px; --toggler-button-height: 24px; --main-links-height: 190px; --footer-buttons-height: 110px; "
        class={["
        transition-all
        duration-100
        z-50
        w-full
        hidden
        h-[100vh]
        scrollbar-hide
        md:flex
        flex-col
        justify-between
        md:w-[200px]
        shadow-sm
        bg-delivery-navbar
        dark:bg-delivery-navbar-dark
      ", if(!@sidebar_expanded, do: "md:!w-[60px]")]}
        aria-expanded={"#{@sidebar_expanded}"}
      >
        <div class="w-full">
          <div
            class={[
              "h-[var(--header-height)] w-48 py-2 flex shrink-0 border-b border-[#0F0D0F]/5 dark:border-[#0F0D0F]",
              if(!@sidebar_expanded, do: "w-14")
            ]}
            tab-index="0"
          >
            <.link
              id="logo_button"
              navigate={logo_link_path(@preview_mode, nil, @ctx.user, @sidebar_expanded, @is_admin)}
            >
              <.logo_img />
            </.link>
          </div>
          <.workspace_sidebar_toggler
            active_workspace={@active_workspace}
            active_view={@active_view}
            preview_mode={@preview_mode}
            sidebar_expanded={@sidebar_expanded}
            resource_slug={@resource_slug}
            uri={@uri}
          />
          <div class="h-[var(--main-links-height)]">
            <div class="h-[24px]">
              <h2
                :if={@sidebar_expanded}
                class="text-[14px] font-bold ml-5 dark:text-[#B8B4BF] text-[#353740] tracking-[-1%] leading-6"
              >
                WORKSPACE
              </h2>
            </div>
            <.workspace_sidebar_links
              preview_mode={@preview_mode}
              sidebar_expanded={@sidebar_expanded}
              active_workspace={@active_workspace}
            />
            <div :if={!@sidebar_expanded && @resource_slug} class="flex justify-center">
              <OliWeb.Icons.line_32 />
            </div>
            <WorkspaceUtils.title
              sidebar_expanded={@sidebar_expanded}
              resource_title={@resource_title}
            />
          </div>
          <WorkspaceUtils.sub_menu
            :if={@resource_slug}
            hierarchy={WorkspaceUtils.hierarchy(@active_workspace)}
            resource_slug={@resource_slug}
            resource_title={@resource_title}
            sidebar_expanded={@sidebar_expanded}
            active_view={@active_view}
            active_workspace={@active_workspace}
          />
        </div>
        <div class="p-2 flex-col justify-center items-center gap-4 inline-flex h-[var(--footer-buttons-height)]">
          <.tech_support_button id="tech_support_workspace_sidebar_nav" show_text={@sidebar_expanded} />
          <.exit_workspace_button
            :if={@resource_slug}
            sidebar_expanded={@sidebar_expanded}
            title={if @active_workspace == :course_author, do: "Exit Project", else: "Exit Section"}
            target_workspace={@active_workspace}
          />
        </div>
      </nav>
      <nav
        id="mobile-nav-menu"
        class="
        fixed
        z-50
        w-full
        mt-14
        hidden
        md:hidden
        flex-col
        shadow-sm
        bg-delivery-navbar
        dark:bg-delivery-navbar-dark
      "
        phx-click-away={JS.hide()}
      >
        <div class="px-4 py-2 flex flex-row items-center align-center justify-between border-b border-gray-300 dark:border-gray-800">
          <div class="flex items-center">
            <.tech_support_button id="mobile-tech-support" />
          </div>
          <UserAccount.menu
            id="mobile-user-account-menu-workspace-sidebar"
            ctx={@ctx}
            is_admin={@is_admin}
            dropdown_class="absolute right-0 border"
          />
        </div>
        <.workspace_sidebar_links
          preview_mode={@preview_mode}
          sidebar_expanded={@sidebar_expanded}
          active_workspace={@active_workspace}
          platform="mobile"
        />
      </nav>
    </div>
    """
  end

  attr(:preview_mode, :boolean)
  attr(:sidebar_expanded, :boolean)
  attr(:active_workspace, :atom)
  attr(:platform, :string, default: "desktop")

  def workspace_sidebar_links(assigns) do
    ~H"""
    <div class="w-full p-2 flex-col justify-center gap-2 items-center inline-flex">
      <.nav_link
        id={"#{@platform}_course_author_workspace_nav_link"}
        href={path_for_workspace(:course_author, @sidebar_expanded)}
        is_active={@active_workspace == :course_author}
        sidebar_expanded={@sidebar_expanded}
        on_active_bg="bg-[#F4CFFF] hover:!bg-[#F4CFFF] dark:bg-[#7E2899] dark:hover:!bg-[#7E2899]"
      >
        <:icon>
          <Icons.writing_pencil is_active={@active_workspace == :course_author} />
        </:icon>
        <:text>Course Author</:text>
      </.nav_link>

      <.nav_link
        id={"#{@platform}_instructor_workspace_nav_link"}
        href={path_for_workspace(:instructor, @sidebar_expanded)}
        is_active={@active_workspace == :instructor}
        sidebar_expanded={@sidebar_expanded}
        on_active_bg="bg-[#A8EED8] hover:!bg-[#A8EED8] dark:bg-[#086F4E] dark:hover:!bg-[#086F4E]"
      >
        <:icon>
          <Icons.growing_bars is_active={@active_workspace == :instructor} />
        </:icon>
        <:text>Instructor</:text>
      </.nav_link>

      <.nav_link
        id={"#{@platform}_student_workspace_nav_link"}
        href={path_for_workspace(:student, @sidebar_expanded)}
        is_active={@active_workspace == :student}
        sidebar_expanded={@sidebar_expanded}
        on_active_bg="bg-[#AAC3F0]/75 hover:!bg-[#AAC3F0]/75 dark:bg-[#2957A9] dark:hover:!bg-[#2957A9]"
      >
        <:icon>
          <Icons.graduation_cap
            is_active={@active_workspace == :student}
            stroke="stroke-[#757682] dark:stroke-[#BAB8BF]"
          />
        </:icon>
        <:text>Student</:text>
      </.nav_link>
    </div>
    """
  end

  attr(:section, Section, default: nil)
  attr(:active_tab, :atom)
  attr(:preview_mode, :boolean)
  attr(:sidebar_expanded, :boolean, default: true)
  attr(:notes_enabled, :boolean, default: true)
  attr(:discussions_enabled, :boolean, default: true)
  attr(:has_scheduled_resources?, :boolean, default: false)
  attr(:notification_badges, :map, default: %{})

  def sidebar_links(assigns) do
    ~H"""
    <div class="w-full p-2 flex-col justify-center items-center gap-4 inline-flex">
      <.nav_link
        id="home_nav_link"
        href={path_for(:index, @section, @preview_mode, @sidebar_expanded)}
        is_active={@active_tab == :index}
        sidebar_expanded={@sidebar_expanded}
      >
        <:icon><Icons.home is_active={@active_tab == :index} /></:icon>
        <:text>Home</:text>
      </.nav_link>

      <.nav_link
        id="learn_nav_link"
        href={path_for(:learn, @section, @preview_mode, @sidebar_expanded)}
        is_active={@active_tab == :learn}
        sidebar_expanded={@sidebar_expanded}
      >
        <:icon><Icons.learn is_active={@active_tab == :learn} /></:icon>
        <:text>Learn</:text>
      </.nav_link>

      <.nav_link
        :if={@has_scheduled_resources?}
        id="schedule_nav_link"
        href={path_for(:schedule, @section, @preview_mode, @sidebar_expanded)}
        is_active={@active_tab == :schedule}
        sidebar_expanded={@sidebar_expanded}
      >
        <:icon><Icons.schedule is_active={@active_tab == :schedule} /></:icon>
        <:text>Schedule</:text>
      </.nav_link>

      <.nav_link
        :if={@notes_enabled || @discussions_enabled}
        id="discussions_nav_link"
        href={path_for(:discussions, @section, @preview_mode, @sidebar_expanded)}
        is_active={@active_tab == :discussions}
        sidebar_expanded={@sidebar_expanded}
        badge={Map.get(@notification_badges, :discussions)}
      >
        <:icon><Icons.discussions is_active={@active_tab == :discussions} /></:icon>
        <:text>Notes</:text>
      </.nav_link>

      <.nav_link
        :if={section_has_assignments?(@section.id)}
        id="assignments_nav_link"
        href={path_for(:assignments, @section, @preview_mode, @sidebar_expanded)}
        is_active={@active_tab == :assignments}
        sidebar_expanded={@sidebar_expanded}
      >
        <:icon><Icons.assignments is_active={@active_tab == :assignments} /></:icon>
        <:text>Assignments</:text>
      </.nav_link>

      <.nav_link
        :if={@section.contains_explorations}
        id="explorations_nav_link"
        href={path_for(:explorations, @section, @preview_mode, @sidebar_expanded)}
        is_active={@active_tab == :explorations}
        sidebar_expanded={@sidebar_expanded}
      >
        <:icon><Icons.explorations is_active={@active_tab == :explorations} /></:icon>
        <:text>Explorations</:text>
      </.nav_link>

      <.nav_link
        :if={@section.contains_deliberate_practice}
        id="practice_nav_link"
        href={path_for(:practice, @section, @preview_mode, @sidebar_expanded)}
        is_active={@active_tab == :practice}
        sidebar_expanded={@sidebar_expanded}
      >
        <:icon><Icons.practice is_active={@active_tab == :practice} /></:icon>
        <:text>Practice</:text>
      </.nav_link>
    </div>
    """
  end

  defp toggled_workspace_path(sidebar_expanded, uri) do
    url_params_updated = toggle_sidebar_in_params(uri, sidebar_expanded)
    url_path = uri |> URI.parse() |> Map.get(:path)
    "#{url_path}?#{url_params_updated}"
  end

  defp toggle_sidebar_in_params(uri, sidebar_expanded) do
    uri
    |> URI.parse()
    |> Map.get(:query, "")
    |> case do
      nil -> %{}
      query -> URI.decode_query(query)
    end
    |> Map.merge(%{"sidebar_expanded" => "#{!sidebar_expanded}"})
    |> Phoenix.VerifiedRoutes.__encode_query__()
  end

  defp path_for_workspace(target_workspace, sidebar_expanded) do
    url_params = %{
      sidebar_expanded: sidebar_expanded
    }

    case target_workspace do
      :course_author -> ~p"/workspaces/course_author?#{url_params}"
      :instructor -> ~p"/workspaces/instructor?#{url_params}"
      :student -> ~p"/workspaces/student?#{url_params}"
    end
  end

  defp path_for(:index, %Section{slug: section_slug}, preview_mode, sidebar_expanded) do
    if preview_mode do
      ~p"/sections/#{section_slug}/preview"
    else
      ~p"/sections/#{section_slug}?#{%{sidebar_expanded: sidebar_expanded}}"
    end
  end

  defp path_for(:index, _section, _preview_mode, _sidebar_expanded) do
    "#"
  end

  defp path_for(:learn, %Section{slug: section_slug}, preview_mode, sidebar_expanded) do
    if preview_mode do
      ~p"/sections/#{section_slug}/preview/learn"
    else
      ~p"/sections/#{section_slug}/learn?#{%{sidebar_expanded: sidebar_expanded}}"
    end
  end

  defp path_for(:learn, _section, _preview_mode, _sidebar_expanded) do
    "#"
  end

  defp path_for(:discussions, %Section{slug: section_slug}, preview_mode, sidebar_expanded) do
    if preview_mode do
      ~p"/sections/#{section_slug}/preview/discussions"
    else
      ~p"/sections/#{section_slug}/discussions?#{%{sidebar_expanded: sidebar_expanded}}"
    end
  end

  defp path_for(:discussions, _section, _preview_mode, _sidebar_expanded) do
    "#"
  end

  defp path_for(:assignments, %Section{slug: section_slug}, preview_mode, sidebar_expanded) do
    if preview_mode do
      ~p"/sections/#{section_slug}/preview/assignments"
    else
      ~p"/sections/#{section_slug}/assignments?#{%{sidebar_expanded: sidebar_expanded}}"
    end
  end

  defp path_for(:assignments, _section, _preview_mode, _sidebar_expanded) do
    "#"
  end

  defp path_for(:schedule, %Section{slug: section_slug}, preview_mode, sidebar_expanded) do
    if preview_mode do
      ~p"/sections/#{section_slug}/preview/student_schedule"
    else
      ~p"/sections/#{section_slug}/student_schedule?#{%{sidebar_expanded: sidebar_expanded}}"
    end
  end

  defp path_for(:schedule, _section, _preview_mode, _sidebar_expanded) do
    "#"
  end

  defp path_for(:explorations, %Section{slug: section_slug}, preview_mode, sidebar_expanded) do
    if preview_mode do
      ~p"/sections/#{section_slug}/preview/explorations"
    else
      ~p"/sections/#{section_slug}/explorations?#{%{sidebar_expanded: sidebar_expanded}}"
    end
  end

  defp path_for(:explorations, _section, _preview_mode, _sidebar_expanded) do
    "#"
  end

  defp path_for(:practice, %Section{slug: section_slug}, preview_mode, sidebar_expanded) do
    if preview_mode do
      ~p"/sections/#{section_slug}/preview/practice"
    else
      ~p"/sections/#{section_slug}/practice?#{%{sidebar_expanded: sidebar_expanded}}"
    end
  end

  defp path_for(:practice, _section, _preview_mode, _sidebar_expanded) do
    "#"
  end

  defp path_for(_, _, _, _), do: "#"

  attr :href, :string, required: true
  attr :is_active, :boolean, required: true
  slot :text, required: true
  slot :icon, required: true
  attr :sidebar_expanded, :boolean, default: true
  attr :id, :string
  attr :badge, :integer, default: nil
  attr :on_active_bg, :string, default: "bg-zinc-400 bg-opacity-20"
  attr :navigation_type, :string, default: "navigate"

  def nav_link(%{navigation_type: "navigate"} = assigns) do
    ~H"""
    <.link
      id={@id}
      navigate={@href}
      class={["w-full h-[35px] flex-col justify-center items-center flex hover:no-underline"]}
    >
      <.nav_link_content {assigns} />
    </.link>
    """
  end

  def nav_link(%{navigation_type: "href"} = assigns) do
    ~H"""
    <.link
      id={@id}
      href={@href}
      class={["w-full h-[35px] flex-col justify-center items-center flex hover:no-underline"]}
    >
      <.nav_link_content {assigns} />
    </.link>
    """
  end

  def nav_link_content(assigns) do
    ~H"""
    <div class={[
      "relative w-full h-9 px-3 py-3 dark:hover:bg-[#141416] hover:bg-zinc-400/10 rounded-lg justify-start items-center gap-3 inline-flex",
      if(@is_active,
        do: @on_active_bg
      )
    ]}>
      <div class="w-5 h-5 flex items-center justify-center">
        <%= render_slot(@icon) %>
      </div>
      <div
        :if={@sidebar_expanded}
        class={[
          "text-[#757682] dark:text-[#BAB8BF] text-sm font-medium tracking-tight flex flex-row justify-between",
          if(@is_active, do: "!font-semibold dark:!text-white !text-[#353740]")
        ]}
      >
        <div class="whitespace-nowrap">
          <%= render_slot(@text) %>
        </div>

        <%= if @badge do %>
          <div>
            <.badge variant={:primary} class="ml-2"><%= @badge %></.badge>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr(:section, Section, default: nil)

  def logo_img(assigns) do
    assigns =
      assigns
      |> assign(:logo_src, Branding.brand_logo_url(assigns[:section]))
      |> assign(:logo_src_dark, Branding.brand_logo_url_dark(assigns[:section]))

    ~H"""
    <img src={@logo_src} class="inline-block dark:hidden h-9 object-cover object-left" alt="logo" />
    <img
      src={@logo_src_dark}
      class="hidden dark:inline-block h-9 object-cover object-left"
      alt="logo dark"
    />
    """
  end

  attr :sidebar_expanded, :boolean, default: true
  attr :target_workspace, :atom, default: :student_workspace

  def exit_course_button(assigns) do
    ~H"""
    <.link
      id="exit_course_button"
      navigate={~p"/workspaces/student?#{%{sidebar_expanded: @sidebar_expanded}}"}
      class="w-full h-11 flex-col justify-center items-center flex hover:no-underline text-black/70 hover:text-black/90 dark:text-gray-400 hover:dark:text-white"
    >
      <div class="w-full h-9 px-3 py-3 bg-zinc-400 bg-opacity-20 hover:bg-opacity-40 rounded-lg justify-start items-center gap-3 inline-flex">
        <div class="w-5 h-5 flex items-center justify-center"><Icons.exit /></div>
        <div :if={@sidebar_expanded} class="text-sm font-medium tracking-tight whitespace-nowrap">
          Exit Course
        </div>
      </div>
    </.link>
    """
  end

  attr :sidebar_expanded, :boolean, default: true
  attr :target_workspace, :atom, default: :student
  attr :title, :string, default: "Exit Course"

  def exit_workspace_button(assigns) do
    base_module =
      case assigns.target_workspace do
        :course_author -> OliWeb.Workspaces.CourseAuthor.IndexLive
        :instructor -> OliWeb.Workspaces.Instructor.IndexLive
        :student -> OliWeb.Workspaces.Student
        _ -> raise "Unknown workspace: #{assigns.active_workspace}"
      end

    assigns = assign(assigns, base_module: base_module)

    ~H"""
    <.link
      id="exit_course_button"
      navigate={Routes.live_path(OliWeb.Endpoint, @base_module, sidebar_expanded: @sidebar_expanded)}
      class="w-full h-11 flex-col justify-center items-center flex hover:no-underline text-black/70 hover:text-black/90 dark:text-gray-400 hover:dark:text-white stroke-black/70 hover:stroke-black/90 dark:stroke-[#B8B4BF] hover:dark:stroke-white"
    >
      <div class="w-full h-9 px-3 py-3 bg-zinc-400 bg-opacity-20 hover:bg-opacity-40 rounded-lg justify-start items-center gap-3 inline-flex">
        <div class="w-5 h-5 flex items-center justify-center"><Icons.exit /></div>
        <div :if={@sidebar_expanded} class="text-sm font-medium tracking-tight whitespace-nowrap">
          <%= @title %>
        </div>
      </div>
    </.link>
    """
  end

  attr(:current_page, :map)
  attr(:previous_page, :map)
  attr(:next_page, :map)
  attr(:section_slug, :string)
  attr(:pages_progress, :map)
  attr(:request_path, :string)
  attr(:selected_view, :string, doc: "The selected view for the Learn page (gallery or outline)")

  def previous_next_nav(assigns) do
    # <.links /> were changed from "navigate" to "href" to force a page reload
    # to fix a bug where the page content would render incorrectly some components
    # (for instance, the popup or the formula component from Oli.Rendering.Content.Html)
    # and the page would not react to interactions after navigation to another page
    # ("working" loader kept spinning after interacting with an activity)
    ~H"""
    <div
      id="bottom-bar-wrapper"
      phx-hook="FixedNavigationBar"
      class="group fixed bottom-0 left-1/2 -translate-x-1/2 w-full lg:w-[720px] z-50 h-[10px] lg:h-[74px]"
    >
      <div
        :if={!is_nil(@current_page)}
        id="bottom-bar"
        class="translate-y-full opacity-0 group-hover:translate-y-0 group-hover:opacity-100 absolute bottom-0 left-1/2 -translate-x-1/2 h-[74px] lg:py-4 shadow-lg bg-white dark:bg-black lg:rounded-tl-[40px] lg:rounded-tr-[40px] flex items-center gap-3 lg:w-[720px] w-full z-50 transition-all duration-500 ease-in-out"
      >
        <div class="hidden lg:block absolute -left-[114px] z-0">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="170"
            height="74"
            viewBox="0 0 170 74"
            fill="none"
          >
            <path
              class="fill-white dark:fill-black"
              d="M170 0H134C107 0 92.5 13 68.5 37C44.5 61 24.2752 74 0 74H170V0Z"
            />
          </svg>
        </div>

        <div
          :if={!is_nil(@previous_page)}
          class="grow shrink basis-0 h-10 justify-start items-center flex z-10 overflow-hidden whitespace-nowrap"
          role="prev_page"
        >
          <div
            class="px-2 lg:px-6 rounded justify-end items-center gap-2 flex"
            tooltip="Previous Page"
          >
            <.link
              href={
                resource_navigation_url(
                  @previous_page,
                  @section_slug,
                  assigns[:request_path],
                  assigns[:selected_view]
                )
              }
              class="w-[72px] h-10 opacity-90 hover:opacity-100 bg-[#0062F2]/50 flex items-center justify-center"
            >
              <.left_arrow />
            </.link>
          </div>
          <div class="flex flex-row gap-x-1 justify-start items-center grow shrink basis-0 dark:text-white text-xs font-normal overflow-hidden text-ellipsis">
            <%= maybe_add_icon(@previous_page, @pages_progress) %>
            <span class="overflow-hidden text-ellipsis" title={@previous_page["title"]}>
              <%= @previous_page["title"] %>
            </span>
          </div>
        </div>

        <div
          :if={!is_nil(@next_page)}
          class="grow shrink basis-0 h-10 justify-end items-center flex z-10 overflow-hidden whitespace-nowrap"
          role="next_page"
        >
          <div class="flex flex-row gap-x-1 justify-end items-center grow shrink basis-0 text-right dark:text-white text-xs font-normal overflow-hidden text-ellipsis">
            <%= maybe_add_icon(@next_page, @pages_progress) %>
            <span class="overflow-hidden text-ellipsis" title={@next_page["title"]}>
              <%= @next_page["title"] %>
            </span>
          </div>
          <div class="px-2 lg:px-6 py-2 rounded justify-end items-center gap-2 flex">
            <.link
              href={
                resource_navigation_url(
                  @next_page,
                  @section_slug,
                  assigns[:request_path],
                  assigns[:selected_view]
                )
              }
              class="w-[72px] h-10 opacity-90 hover:opacity-100 bg-[#0062F2] flex items-center justify-center"
            >
              <.right_arrow />
            </.link>
          </div>
        </div>

        <div class="hidden lg:block absolute -right-[114px] z-0">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="170"
            height="74"
            viewBox="0 0 170 74"
            fill="none"
          >
            <path
              class="fill-white dark:fill-black"
              d="M0 0H36C63 0 77.5 13 101.5 37C125.5 61 145.725 74 170 74H0V0Z"
            />
          </svg>
        </div>
      </div>
    </div>
    """
  end

  defp resource_navigation_url(
         %{"id" => resource_id, "slug" => slug, "type" => type, "level" => level},
         section_slug,
         request_path,
         selected_view
       ) do
    case {type, Integer.parse(level)} do
      # If the given resource is a unit or module (level <= 2), we navigate to learn page.
      {"container", {level, _}} when level <= 2 ->
        Utils.learn_live_path(section_slug,
          target_resource_id: resource_id,
          selected_view: selected_view
        )

      # If the given resource is other than a unit or module (page, section/sub-section), we navigate to lesson page.
      _ ->
        # If the request_path is the Learn page and we navigate to a different lesson,
        # we need to update the request_path to include the new target resource.
        request_path =
          if request_path && String.contains?(request_path, "/learn") do
            Utils.learn_live_path(section_slug,
              target_resource_id: resource_id,
              selected_view: selected_view
            )
          else
            request_path
          end

        Utils.lesson_live_path(section_slug, slug,
          request_path: request_path,
          selected_view: selected_view
        )
    end
  end

  attr(:to, :string)
  attr(:show_sidebar, :boolean, default: false)
  attr(:view, :atom, required: true, doc: "adaptive_chromeless pages can't use the link navigate")

  def back_arrow(assigns) do
    ~H"""
    <div
      class={[
        "flex items-center absolute top-2 left-2 p-4 z-50",
        if(!@show_sidebar, do: "2xl:top-12 2xl:left-8")
      ]}
      role="back_link"
    >
      <.link
        :if={@view == :adaptive_chromeless}
        href={@to}
        class="hover:no-underline hover:scale-105 cursor-pointer"
      >
        <Icons.left_arrow class="hover:opacity-100 hover:scale-105 fill-[#9D9D9D]" />
      </.link>
      <.link
        :if={@view != :adaptive_chromeless}
        navigate={@to}
        class="hover:no-underline hover:scale-105 cursor-pointer"
      >
        <Icons.left_arrow class="hover:opacity-100 hover:scale-105 fill-[#9D9D9D]" />
      </.link>
    </div>
    """
  end

  defp left_arrow(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
      <path d="M7.825 13H20V11H7.825L13.425 5.4L12 4L4 12L12 20L13.425 18.6L7.825 13Z" fill="white" />
    </svg>
    """
  end

  defp right_arrow(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      class="rotate-180"
    >
      <path d="M7.825 13H20V11H7.825L13.425 5.4L12 4L4 12L12 20L13.425 18.6L7.825 13Z" fill="white" />
    </svg>
    """
  end

  attr :additional_classes, :string,
    default: "",
    required: false,
    doc: """
    Additional classes to add to the spinner.
    If you want to override the default styling you may probably need to add the Tailwind classes
    with the '!' important flag, ex: "!w-10 !h-10"
    """

  def spinner(assigns) do
    ~H"""
    <svg
      role="spinner"
      aria-hidden="true"
      class={[
        "w-8 h-8 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600",
        @additional_classes
      ]}
      viewBox="0 0 100 101"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
        fill="currentColor"
      />
      <path
        d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
        fill="currentFill"
      />
    </svg>
    <span class="sr-only">Loading...</span>
    """
  end

  def user_given_name(%SessionContext{user: user, author: author}) do
    case {user, author} do
      {%User{guest: true}, _} ->
        "Guest"

      {%User{given_name: given_name}, _} ->
        given_name

      {_, %Author{given_name: given_name}} ->
        given_name

      {_, _} ->
        ""
    end
  end

  def user_name(%SessionContext{user: user, author: author}) do
    case {user, author} do
      {%User{guest: true}, _} ->
        "Guest"

      {%User{name: name}, _} ->
        name

      {_, %Author{name: name}} ->
        name

      {_, _} ->
        ""
    end
  end

  defp logo_link_path(preview_mode, section, user, sidebar_expanded, is_admin) do
    cond do
      preview_mode ->
        "#"

      is_admin ->
        ~p"/workspaces/course_author"

      is_open_and_free_section?(section) or is_independent_learner?(user) ->
        path_for(:index, section, preview_mode, sidebar_expanded)

      true ->
        Routes.static_page_path(OliWeb.Endpoint, :index)
    end
  end

  def show_collab_space?(nil), do: false
  def show_collab_space?(%CollabSpaceConfig{status: :disabled}), do: false
  def show_collab_space?(_), do: true

  defp section_has_assignments?(section_id) do
    section_id |> SectionResourceDepot.graded_pages(hidden: false) |> Enum.any?()
  end

  defp maybe_add_icon(page, pages_progress) do
    page_id = String.to_integer(page["id"])
    progress = Map.get(pages_progress, page_id)

    case {progress, page["graded"]} do
      {1.0, "false"} -> apply(OliWeb.Icons, :check, [%{}])
      {1.0, "true"} -> apply(OliWeb.Icons, :square_checked, [%{}])
      {_, "true"} -> apply(OliWeb.Icons, :flag, [%{}])
      _ -> nil
    end
  end
end
