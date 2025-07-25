defmodule OliWeb.Workspaces.Instructor.IndexLive do
  use OliWeb, :live_view

  alias Oli.Delivery.Sections
  alias OliWeb.Backgrounds
  alias OliWeb.Common.{FormatDateTime, Params, SearchInput}
  alias OliWeb.Icons

  import OliWeb.Common.SourceImage
  import OliWeb.Components.Utils

  @default_params %{text_search: "", sidebar_expanded: true}

  @context_instructor_roles [
    Lti_1p3.Roles.ContextRoles.get_role(:context_instructor)
  ]

  @impl Phoenix.LiveView
  def mount(_params, _session, %{assigns: %{current_user: current_user, ctx: ctx}} = socket)
      when not is_nil(current_user) do
    sections =
      current_user.id
      |> sections_where_user_is_instructor()
      |> add_instructors()

    {:ok,
     assign(socket,
       sections: sections,
       filtered_sections: sections,
       active_workspace: :instructor,
       ctx: ctx
     )}
  end

  def mount(_params, _session, %{assigns: %{is_admin: true}} = socket) do
    # admin case...

    {:ok, assign(socket, active_workspace: :instructor)}
  end

  def mount(_params, _session, socket) do
    # no current user case...

    authentication_providers =
      Oli.AssentAuth.UserAssentAuth.authentication_providers() |> Keyword.keys()

    {:ok,
     assign(socket,
       current_user: nil,
       active_workspace: :instructor,
       footer_enabled?: false,
       authentication_providers: authentication_providers
     )}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, %{assigns: %{sections: sections, ctx: ctx}} = socket) do
    params = decode_params(params)

    {:noreply,
     assign(socket,
       filtered_sections: maybe_filter_by_text(sections, params.text_search),
       params: params,
       ctx: ctx
     )}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, params: decode_params(params))}
  end

  @impl Phoenix.LiveView

  def render(%{is_admin: true} = assigns) do
    ~H"""
    <div class="dark:bg-[#0F0D0F] bg-[#F3F4F8]">
      <div class="relative flex items-center h-[247px]">
        <div class="absolute top-0 h-full w-full">
          <Backgrounds.instructor_dashboard_header />
        </div>
        <div class="flex-col justify-start items-start gap-[15px] z-10 px-6 md:px-[63px] font-['Open Sans']">
          <div class="flex flex-row items-center gap-3">
            <Icons.growing_bars
              stroke_class="stroke-[#353740] dark:stroke-white"
              class="w-[36px] h-[36px]"
            />
            <h1 class="text-[#353740] dark:text-white text-[32px] font-bold leading-normal">
              Instructor Dashboard
            </h1>
          </div>
          <h2 class="text-[#353740] dark:text-white text-base font-normal leading-normal">
            Gain insights into student engagement, progress, and learning patterns.
          </h2>
        </div>
      </div>

      <div class="flex flex-col items-start mt-[40px] gap-9 py-[60px] px-[63px]">
        <div class="flex flex-col gap-4">
          <h3 class="w-full text-xl dark:text-white">
            Instructor workspace with an admin account has not yet been developed.
            To use this workspace please logout and sign in with an instructor account
          </h3>
        </div>

        <div class="flex flex-col gap-4">
          <h3 class="w-full text-xl dark:text-white">
            <%= if !is_nil(@current_user) do %>
              You are currently logged in with a delivery account:
              <div class="bg-gray-300 dark:bg-gray-700 rounded-lg p-4 text-sm">
                <table>
                  <tr>
                    <th class="text-left">Name</th>
                    <td><%= @current_user.name %></td>
                  </tr>
                  <tr>
                    <th class="text-left">Given Name</th>
                    <td><%= @current_user.given_name %></td>
                  </tr>
                  <tr>
                    <th class="text-left">Family Name</th>
                    <td><%= @current_user.family_name %></td>
                  </tr>
                  <tr>
                    <th class="text-left">Email</th>
                    <td><%= @current_user.email %></td>
                  </tr>
                  <tr>
                    <th class="text-left">Guest?</th>
                    <td><%= @current_user.guest %></td>
                  </tr>
                  <tr>
                    <th class="text-left">Hidden?</th>
                    <td><%= @current_user.hidden %></td>
                  </tr>
                  <tr>
                    <th class="text-left">Direct Delivery?</th>
                    <td><%= @current_user.independent_learner %></td>
                  </tr>
                </table>
              </div>

              <p>
                <%= link to: ~p"/users/log_out", method: :delete do %>
                  Sign out of this delivery account.
                <% end %>
              </p>
            <% else %>
              You are not logged in with any delivery account.
            <% end %>
          </h3>
        </div>
      </div>
    </div>
    """
  end

  def render(%{current_user: nil} = assigns) do
    ~H"""
    <div class="flex-1 flex justify-center items-center min-h-screen">
      <div class="absolute h-full w-full top-0 left-0">
        <Backgrounds.instructor_workspace_sign_in />
      </div>
      <div class="z-20 flex justify-center gap-2 lg:gap-12 xl:gap-32 px-6 md:px-[63px]">
        <div class="w-1/4 lg:w-1/2 flex items-start justify-center">
          <div class="w-96 flex-col justify-start items-start gap-0 lg:gap-3.5 inline-flex">
            <div class="text-left lg:text-3xl xl:text-4xl">
              <span class="text-white font-normal font-['Open Sans'] leading-10">
                Welcome to
              </span>
              <span class="text-white font-bold font-['Open Sans'] leading-10">
                <%= Oli.VendorProperties.product_short_name() %>
              </span>
            </div>
            <div class="w-48 h-11 justify-start items-center gap-1 inline-flex">
              <div class="justify-start items-center gap-2 lg:gap-px flex">
                <div class="grow shrink basis-0 self-start px-1 py-2 justify-center items-center flex">
                  <OliWeb.Icons.growing_bars
                    class="w-7 h-6 lg:w-[36px] lg:h-[36px]"
                    stroke_class="stroke-white"
                  />
                </div>
                <div class="w-40 lg:text-center text-white lg:text-3xl xl:text-4xl font-bold font-['Open Sans']">
                  Instructor
                </div>
              </div>
            </div>
            <div class="lg:mt-6 text-white lg:text-lg xl:text-xl font-normal leading-normal">
              Gain insights into student engagement, progress, and learning patterns.
            </div>
          </div>
        </div>
        <div class="lg:w-1/2 flex items-center justify-center">
          <Components.Auth.login_form
            title="Instructor Sign In"
            form={@form}
            action={~p"/users/log_in?#{[request_path: ~p"/workspaces/instructor"]}"}
            registration_link={~p"/users/register"}
            reset_password_link={~p"/users/reset_password"}
            authentication_providers={@authentication_providers}
            auth_provider_path_fn={&~p"/users/auth/#{&1}/new"}
          />
        </div>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="dark:bg-[#0F0D0F] bg-[#F3F4F8]">
      <div class="relative flex items-center h-[247px]">
        <div class="absolute top-0 h-[291px] w-full overflow-x-hidden">
          <Backgrounds.instructor_dashboard_header />
        </div>
        <div class="flex-col justify-start items-start gap-[15px] z-10 px-6 md:px-[63px] font-['Open Sans']">
          <div class="flex flex-row items-center gap-3">
            <Icons.growing_bars
              stroke_class="stroke-[#353740] dark:stroke-white"
              class="w-[36px] h-[36px]"
            />
            <h1 class="text-[#353740] dark:text-white text-[32px] font-bold leading-normal">
              Instructor Dashboard
            </h1>
          </div>
          <h2 class="text-[#353740] dark:text-white text-base font-normal leading-normal">
            Gain insights into student engagement, progress, and learning patterns.
          </h2>
        </div>
      </div>

      <div class="flex flex-col items-start mt-[40px] gap-9 py-[60px] px-6 md:px-[63px]">
        <div class="flex flex-col gap-4">
          <h3 class="dark:text-violet-100 text-xl font-bold font-['Open Sans'] leading-normal whitespace-nowrap">
            My courses
          </h3>
          <div
            :if={!is_independent_instructor?(@current_user)}
            role="create section instructions"
            class="dark:text-violet-100 text-base font-normal font-['Inter'] leading-normal"
          >
            To create course sections,
            <.tech_support_link
              id="tech_support_is_not_independet_instructor"
              class="text-[#006CD9] hover:text-[#1B67B2] dark:text-[#4CA6FF] dark:hover:text-[#99CCFF] hover:underline text-base font-bold font-['Open Sans'] tracking-tight cursor-pointer"
            >
              contact support.
            </.tech_support_link>
          </div>
        </div>
        <div class="flex flex-col md:flex-row md:items-center w-full md:justify-between gap-3">
          <.link
            href={if(is_independent_instructor?(@current_user), do: ~p"/sections/independent/create")}
            class={[
              "px-4 py-2 max-w-[220px] hover:no-underline rounded-md justify-center items-center gap-2 inline-flex",
              "text-white text-base font-normal font-['Inter'] leading-normal whitespace-nowrap",
              if(is_independent_instructor?(@current_user),
                do: "bg-[#0080FF] hover:bg-[#0075EB] dark:bg-[#0062F2] dark:hover:bg-[#0D70FF]",
                else: "bg-zinc-600 cursor-not-allowed"
              )
            ]}
          >
            <Icons.plus class="w-5 h-5" path_class="stroke-white" /> Create New Section
          </.link>
          <.form for={%{}} phx-change="search_section" class="w-full max-w-[400px]">
            <SearchInput.render
              id="section_search_input"
              name="text_search"
              placeholder="Search my courses..."
              text={@params.text_search}
            />
          </.form>
        </div>

        <div class="flex w-full mb-10">
          <%= if length(@sections) == 0 do %>
            <p>You are not enrolled in any courses as an instructor.</p>
          <% else %>
            <div class="flex flex-wrap w-full gap-3">
              <.instructor_course_card
                :for={{section, index} <- Enum.with_index(@filtered_sections)}
                index={index}
                section={section}
                params={@params}
                ctx={@ctx}
              />
              <p :if={length(@filtered_sections) == 0} class="mt-4">
                No course found matching <strong>"<%= @params.text_search %>"</strong>
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr :section, :map
  attr :index, :integer
  attr :params, :map
  attr :ctx, :map

  def instructor_course_card(assigns) do
    ~H"""
    <div
      id={"course_card_#{@section.id}"}
      phx-mounted={
        JS.transition(
          {"ease-out duration-300", "opacity-0 -translate-x-1/2", "opacity-100 translate-x-0"},
          time: if(@index < 6, do: 100 + @index * 20, else: 240)
        )
      }
      class="opacity-0 flex flex-col w-96 h-[500px] rounded-lg border-2 border-gray-700 transition-all overflow-hidden bg-white"
    >
      <div
        class="w-96 h-[220px] bg-cover border-b-2 border-gray-700"
        style={"background-image: url('#{cover_image(@section)}');"}
      >
      </div>
      <div class="flex-col justify-start items-start gap-2 inline-flex p-8">
        <div
          class="justify-center text-[#757682] text-xs font-bold uppercase leading-3"
          role="start_end_date"
        >
          <%= FormatDateTime.to_formatted_datetime(@section.start_date, @ctx, "{Mshort} {YYYY}") %> - <%= FormatDateTime.to_formatted_datetime(
            @section.end_date,
            @ctx,
            "{Mshort} {YYYY}"
          ) %>
        </div>
        <h5
          class="text-black text-base font-bold font-['Inter'] leading-normal overflow-hidden"
          style="display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical;"
          role="course title"
        >
          <%= @section.title %>
        </h5>
        <div
          class="justify-center text-[#757682] text-base font-bold leading-normal"
          role="instructors"
        >
          <%= if length(Sections.get_instructors_for_section(@section.id)) == 1 do %>
            Instructor:
          <% else %>
            Instructors:
          <% end %>
          <%= list_instructors(Sections.get_instructors_for_section(@section.id)) %>
        </div>
        <div class="text-black text-base font-normal leading-normal h-[100px] overflow-hidden">
          <p
            role="course description"
            style="display: -webkit-box; -webkit-line-clamp: 4; -webkit-box-orient: vertical;"
          >
            <%= @section.description %>
          </p>
        </div>
        <div class="self-stretch justify-end items-start gap-4 inline-flex">
          <.link
            href={get_course_url(@section, @params.sidebar_expanded)}
            class="px-5 py-3 bg-[#0080FF] hover:bg-[#0075EB] dark:bg-[#0062F2] dark:hover:bg-[#0D70FF] hover:no-underline rounded-md justify-center items-center gap-2 flex text-white text-base font-normal leading-normal"
          >
            <div class="text-white text-base font-normal font-['Inter'] leading-normal whitespace-nowrap">
              View Course
            </div>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("search_section", %{"text_search" => text_search}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/workspaces/instructor?#{%{socket.assigns.params | text_search: text_search}}"
     )}
  end

  defp add_instructors([]), do: []

  defp add_instructors(sections) do
    instructors_per_section = Sections.instructors_per_section(Enum.map(sections, & &1.id))

    sections
    |> Enum.map(fn section ->
      Map.merge(section, %{instructors: Map.get(instructors_per_section, section.id, [])})
    end)
  end

  defp maybe_filter_by_text(sections, nil), do: sections
  defp maybe_filter_by_text(sections, ""), do: sections

  # Filters sections by section title or instructor name
  defp maybe_filter_by_text(sections, text_search) do
    normalized_text_search = String.downcase(text_search)

    sections
    |> Enum.filter(fn section ->
      instructor_names = Enum.map(section.instructors, &to_string/1)

      searchable_text =
        [section.title, instructor_names] |> IO.iodata_to_binary() |> String.downcase()

      String.contains?(searchable_text, normalized_text_search)
    end)
  end

  defp get_course_url(%{slug: slug}, sidebar_expanded),
    do: ~p"/sections/#{slug}/manage?#{%{sidebar_expanded: sidebar_expanded}}"

  defp decode_params(params) do
    %{
      text_search: Params.get_param(params, "text_search", @default_params.text_search),
      sidebar_expanded:
        Params.get_boolean_param(params, "sidebar_expanded", @default_params.sidebar_expanded)
    }
  end

  defp sections_where_user_is_instructor(user_id) do
    Sections.get_open_and_free_active_sections_by_roles(user_id, @context_instructor_roles)
  end
end
