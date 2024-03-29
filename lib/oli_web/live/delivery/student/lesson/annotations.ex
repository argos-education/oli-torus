defmodule OliWeb.Delivery.Student.Lesson.Annotations do
  use OliWeb, :html

  alias OliWeb.Components.Common
  alias Oli.Accounts.User

  attr :create_new_annotation, :boolean, default: false
  attr :annotations, :any, required: true
  attr :current_user, Oli.Accounts.User, required: true
  attr :active_tab, :atom, default: :my_notes
  attr :post_replies, :list, default: nil

  def panel(assigns) do
    ~H"""
    <div class="flex-1 flex flex-row overflow-hidden">
      <div class="justify-start">
        <.toggle_notes_button>
          <i class="fa-solid fa-xmark group-hover:scale-110"></i>
        </.toggle_notes_button>
      </div>
      <div class="flex-1 flex flex-col bg-white dark:bg-black p-5">
        <.tab_group class="py-3">
          <.tab name={:my_notes} selected={@active_tab == :my_notes}>
            <.user_icon class="mr-2" /> My Notes
          </.tab>
          <.tab name={:all_notes} selected={@active_tab == :all_notes}>
            <.users_icon class="mr-2" /> Class Notes
          </.tab>
        </.tab_group>
        <.search_box class="mt-2" />
        <hr class="m-6 border-b border-b-gray-200" />
        <div class="flex-1 flex flex-col gap-3 overflow-y-auto pb-[80px]">
          <.add_new_annotation_input
            class="my-2"
            active={@create_new_annotation}
            disable_anonymous_option={@active_tab == :my_notes || is_guest(@current_user)}
            save_label={if(@active_tab == :my_notes, do: "Save", else: "Post")}
            placeholder={
              if(@active_tab == :my_notes, do: "Add a new note...", else: "Post a new note...")
            }
          />

          <%= case @annotations do %>
            <% nil -> %>
              <Common.loading_spinner />
            <% [] -> %>
              <div class="text-center p-4 text-gray-500"><%= empty_label(@active_tab) %></div>
            <% annotations -> %>
              <%= for annotation <- annotations do %>
                <.post post={annotation} current_user={@current_user} post_replies={@post_replies} />
              <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp is_guest(%User{guest: guest}), do: guest
  defp is_guest(_), do: false

  defp empty_label(:my_notes), do: "There are no notes yet"
  defp empty_label(_), do: "There are no posts yet"

  slot :inner_block, required: true

  def toggle_notes_button(assigns) do
    ~H"""
    <button
      class="flex flex-col items-center rounded-l-lg bg-white dark:bg-black px-6 py-12 text-xl group"
      phx-click="toggle_sidebar"
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def annotations_icon(assigns) do
    ~H"""
    <svg
      width="24"
      height="25"
      viewBox="0 0 24 25"
      xmlns="http://www.w3.org/2000/svg"
      class="group-hover:scale-110"
    >
      <path
        id="Path"
        fill="#0064ed"
        fill-rule="evenodd"
        stroke="none"
        d="M 9.51568 1.826046 C 5.766479 1.826046 2.727119 4.889919 2.727119 8.669355 C 2.727119 9.763306 2.98112 10.79484 3.432001 11.709678 C 3.53856 11.925805 3.55584 12.175646 3.48008 12.404678 L 2.330881 15.88008 L 5.81328 14.748066 C 6.03848 14.674919 6.283121 14.693466 6.494881 14.799678 C 7.40368 15.255725 8.42864 15.51266 9.51568 15.51266 C 13.264959 15.51266 16.304239 12.448791 16.304239 8.669355 C 16.304239 4.889919 13.264959 1.826046 9.51568 1.826046 Z M 0.91568 8.669355 C 0.91568 3.881369 4.76608 0 9.51568 0 C 14.26536 0 18.115759 3.881369 18.115759 8.669355 C 18.115759 13.457338 14.26536 17.338711 9.51568 17.338711 C 8.276159 17.338711 7.09592 17.073872 6.02928 16.596533 L 1.183681 18.171612 C 0.85872 18.277258 0.5024 18.189596 0.26216 17.945 C 0.021919 17.700485 -0.06144 17.340405 0.04648 17.01387 L 1.6472 12.173065 C 1.17672 11.100726 0.91568 9.914679 0.91568 8.669355 Z"
      />
      <path
        id="path1"
        fill="#0064ed"
        fill-rule="evenodd"
        stroke="none"
        d="M 23.192719 16.158226 C 23.192719 11.929112 19.79184 8.500807 15.59664 8.500807 C 11.401441 8.500807 8.000481 11.929112 8.000481 16.158226 C 8.000481 20.387257 11.401441 23.815567 15.59664 23.815567 C 16.691441 23.815567 17.733999 23.581615 18.676081 23.16 L 22.955999 24.551207 C 23.243038 24.644514 23.55776 24.567179 23.77 24.351126 C 23.982239 24.135078 24.055841 23.817099 23.96048 23.528627 L 22.54664 19.252899 C 22.962162 18.305725 23.192719 17.258146 23.192719 16.158226 Z"
      />
    </svg>
    """
  end

  slot :inner_block, required: true
  attr :rest, :global, include: ~w(class)

  defp tab_group(assigns) do
    ~H"""
    <div class={["flex flex-row", @rest[:class]]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :name, :atom, required: true
  attr :selected, :boolean, default: false
  slot :inner_block, required: true

  defp tab(assigns) do
    ~H"""
    <button
      phx-click="select_tab"
      phx-value-tab={@name}
      class={[
        "flex-1 inline-flex justify-center border-l border-t border-b first:rounded-l-lg last:rounded-r-lg last:border-r px-4 py-3 inline-flex items-center",
        if(@selected,
          do: "bg-primary border-primary text-white stroke-white font-semibold",
          else:
            "stroke-[#383A44] border-gray-400 hover:bg-gray-100 dark:border-gray-700 dark:hover:bg-gray-800"
        )
      ]}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :rest, :global, include: ~w(class)

  defp user_icon(assigns) do
    ~H"""
    <svg
      class={@rest[:class]}
      width="20"
      height="20"
      viewBox="0 0 20 20"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M16.6666 17.5V15.8333C16.6666 14.9493 16.3154 14.1014 15.6903 13.4763C15.0652 12.8512 14.2173 12.5 13.3333 12.5H6.66659C5.78253 12.5 4.93468 12.8512 4.30956 13.4763C3.68444 14.1014 3.33325 14.9493 3.33325 15.8333V17.5"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
      <path
        d="M10.0001 9.16667C11.841 9.16667 13.3334 7.67428 13.3334 5.83333C13.3334 3.99238 11.841 2.5 10.0001 2.5C8.15913 2.5 6.66675 3.99238 6.66675 5.83333C6.66675 7.67428 8.15913 9.16667 10.0001 9.16667Z"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </svg>
    """
  end

  attr :rest, :global, include: ~w(class)

  defp users_icon(assigns) do
    ~H"""
    <svg
      class={@rest[:class]}
      width="20"
      height="20"
      viewBox="0 0 20 20"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <g clip-path="url(#clip0_270_13479)">
        <path
          d="M14.1666 17.5V15.8333C14.1666 14.9493 13.8154 14.1014 13.1903 13.4763C12.5652 12.8512 11.7173 12.5 10.8333 12.5H4.16659C3.28253 12.5 2.43468 12.8512 1.80956 13.4763C1.18444 14.1014 0.833252 14.9493 0.833252 15.8333V17.5"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M7.50008 9.16667C9.34103 9.16667 10.8334 7.67428 10.8334 5.83333C10.8334 3.99238 9.34103 2.5 7.50008 2.5C5.65913 2.5 4.16675 3.99238 4.16675 5.83333C4.16675 7.67428 5.65913 9.16667 7.50008 9.16667Z"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M19.1667 17.4991V15.8324C19.1662 15.0939 18.9204 14.3764 18.4679 13.7927C18.0154 13.209 17.3819 12.7921 16.6667 12.6074"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M13.3333 2.60742C14.0503 2.79101 14.6858 3.20801 15.1396 3.79268C15.5935 4.37736 15.8398 5.09645 15.8398 5.83659C15.8398 6.57673 15.5935 7.29582 15.1396 7.8805C14.6858 8.46517 14.0503 8.88217 13.3333 9.06576"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </g>
      <defs>
        <clipPath id="clip0_270_13479">
          <rect width="20" height="20" fill="white" />
        </clipPath>
      </defs>
    </svg>
    """
  end

  attr :rest, :global, include: ~w(class)

  defp search_box(assigns) do
    ~H"""
    <div class={["flex flex-row", @rest[:class]]}>
      <div class="flex-1 relative">
        <i class="fa-solid fa-search absolute left-4 top-4 text-gray-400 pointer-events-none text-lg">
        </i>
        <input
          type="text"
          class="w-full border border-gray-400 dark:border-gray-700 rounded-lg pl-12 pr-3 py-3"
        />
      </div>
    </div>
    """
  end

  attr :active, :boolean, default: false
  attr :disable_anonymous_option, :boolean, default: false
  attr :save_label, :string, default: "Save"
  attr :placeholder, :string, default: "Add a new note..."
  attr :rest, :global, include: ~w(class)

  defp add_new_annotation_input(%{active: true} = assigns) do
    ~H"""
    <div class={[
      "flex flex-row p-2 border-2 border-gray-300 dark:border-gray-700 rounded-lg",
      @rest[:class]
    ]}>
      <form class="w-full" phx-submit="create_annotation">
        <div class="flex-1 flex flex-col relative border-gray-400 dark:border-gray-700 rounded-lg p-3">
          <div class="flex-1">
            <textarea
              id="annotation_input"
              name="content"
              phx-hook="AutoSelect"
              rows="4"
              class="w-full border border-gray-400 dark:border-gray-700 dark:bg-black rounded-lg p-3"
              placeholder={@placeholder}
            />
          </div>
          <%= unless @disable_anonymous_option do %>
            <div class="flex flex-row justify-start my-2">
              <.input type="checkbox" name="anonymous" value="false" label="Stay anonymous" />
            </div>
          <% end %>
          <div class="flex flex-row-reverse justify-start gap-2 mt-3">
            <Common.button variant={:primary}>
              <%= @save_label %>
            </Common.button>
            <Common.button type="button" variant={:secondary} phx-click="cancel_create_annotation">
              Cancel
            </Common.button>
          </div>
        </div>
      </form>
    </div>
    """
  end

  defp add_new_annotation_input(assigns) do
    ~H"""
    <div class={["flex flex-row", @rest[:class]]}>
      <div class="flex-1 relative">
        <input
          type="text"
          class="w-full border border-gray-400 dark:border-gray-700 rounded-lg p-3"
          placeholder={@placeholder}
          phx-focus="begin_create_annotation"
        />
      </div>
    </div>
    """
  end

  attr :post, Oli.Resources.Collaboration.Post, required: true
  attr :current_user, Oli.Accounts.User, required: true
  attr :post_replies, :any, required: true

  defp post(assigns) do
    ~H"""
    <div class="flex flex-col p-4 border-2 border-gray-200 dark:border-gray-800 rounded">
      <div class="flex flex-row justify-between mb-1">
        <div class="font-semibold">
          <%= post_creator(@post, @current_user) %>
        </div>
        <div class="text-sm text-gray-500">
          <%= Timex.from_now(@post.inserted_at) %>
        </div>
      </div>
      <p class="my-2">
        <%= @post.content.message %>
      </p>
      <.post_actions post={@post} />
      <.post_replies post={@post} replies={@post_replies} current_user={@current_user} />
    </div>
    """
  end

  defp post_creator(%{anonymous: true} = post, current_user) do
    anonymous_name = "Anonymous " <> Oli.Predefined.map_id_to_anonymous_name(post.user_id)

    if post.user_id == current_user.id do
      anonymous_name <> " (Me)"
    else
      anonymous_name
    end
  end

  defp post_creator(post, current_user) do
    if post.user_id == current_user.id do
      "Me"
    else
      case post.user do
        %User{guest: true} ->
          "Anonymous " <> Oli.Predefined.map_id_to_anonymous_name(post.user_id)

        %User{name: name} ->
          name
      end
    end
  end

  attr :post, Oli.Resources.Collaboration.Post, required: true

  defp post_actions(assigns) do
    case assigns.post do
      %Oli.Resources.Collaboration.Post{visibility: :public, status: :submitted} ->
        ~H"""
        <div class="text-sm italic text-gray-500 my-2">
          Submitted and pending approval
        </div>
        """

      %Oli.Resources.Collaboration.Post{visibility: :public} ->
        ~H"""
        <div class="flex flex-row gap-2 my-2">
          <button
            class="inline-flex gap-1 text-sm text-gray-500 bold py-1 px-2 rounded-lg hover:bg-gray-100"
            phx-click="toggle_post_replies"
            phx-value-post-id={assigns.post.id}
          >
            <.replies_bubble_icon /> <%= if(@post.replies_count > 0,
              do: @post.replies_count,
              else: "Reply"
            ) %>
          </button>
        </div>
        """

      _ ->
        ~H"""

        """
    end
  end

  attr :post, Oli.Resources.Collaboration.Post, required: true
  attr :current_user, Oli.Accounts.User, required: true
  attr :replies, :any, required: true
  attr :disable_anonymous_option, :boolean, default: false

  defp post_replies(assigns) do
    ~H"""
    <%= if !is_nil(@replies) && elem(@replies, 0) == @post.id do %>
      <%= case @replies do %>
        <% {_, :loading} -> %>
          <Common.loading_spinner />
        <% {_, []} -> %>
          <.add_new_reply_input parent_post_id={@post.id} />
        <% {_, replies} -> %>
          <div class="flex flex-col gap-2 pl-4">
            <%= for reply <- replies do %>
              <.reply post={reply} current_user={@current_user} />
            <% end %>
          </div>
          <.add_new_reply_input
            parent_post_id={@post.id}
            disable_anonymous_option={@disable_anonymous_option}
          />
        <% _ -> %>
      <% end %>
    <% end %>
    """
  end

  attr :parent_post_id, :integer, required: true
  attr :disable_anonymous_option, :boolean, default: false

  defp add_new_reply_input(assigns) do
    ~H"""
    <div class="flex flex-row mt-2">
      <form class="w-full" phx-submit="create_reply" phx-value-parent-post-id={@parent_post_id}>
        <div class="flex-1 relative">
          <textarea
            id="reply_input"
            name="content"
            phx-hook="AutoSelect"
            rows="1"
            class="w-full min-h-[50px] border border-gray-400 dark:border-gray-700 dark:bg-black rounded-lg p-3 pr-12"
            placeholder="Add a reply..."
          />
          <button class="absolute right-2 bottom-2.5 py-1 px-1.5 rounded-lg">
            <.send_icon />
          </button>
        </div>
        <%= unless @disable_anonymous_option do %>
          <div class="flex flex-row justify-start my-2">
            <.input type="checkbox" name="anonymous" value="false" label="Stay anonymous" />
          </div>
        <% end %>
      </form>
    </div>
    """
  end

  defp send_icon(assigns) do
    ~H"""
    <svg width="34" height="34" viewBox="0 0 34 34" fill="none" xmlns="http://www.w3.org/2000/svg">
      <g>
        <path
          fill-rule="evenodd"
          clip-rule="evenodd"
          d="M32.1126 16.9704C32.1126 17.2865 31.966 17.5683 31.737 17.7516C31.6728 17.8029 31.6022 17.8465 31.5265 17.881L12.4545 27.0638C12.0851 27.2417 11.6445 27.176 11.343 26.8982C11.0415 26.6203 10.9402 26.1865 11.0873 25.8038L14.4848 16.9704L11.0873 8.13703C10.9402 7.75434 11.0415 7.32057 11.343 7.0427C11.6445 6.76484 12.0851 6.69917 12.4545 6.87705L31.5265 16.0598C31.6026 16.0945 31.6737 16.1385 31.7382 16.1903C31.7856 16.2283 31.8292 16.2704 31.8686 16.3158C32.0206 16.4912 32.1126 16.7201 32.1126 16.9704ZM26.7305 15.9704L13.8595 9.77328L16.243 15.9704H26.7305ZM16.243 17.9704L26.7305 17.9704L13.8595 24.1676L16.243 17.9704Z"
          fill="#0064ED"
        />
      </g>
    </svg>
    """
  end

  attr :post, Oli.Resources.Collaboration.Post, required: true
  attr :current_user, Oli.Accounts.User, required: true

  defp reply(assigns) do
    ~H"""
    <div class="flex flex-col my-2 pl-4 border-l-2 border-gray-200 dark:border-gray-800">
      <div class="flex flex-row justify-between mb-1">
        <div class="font-semibold">
          <%= post_creator(@post, @current_user) %>
        </div>
        <div class="text-sm text-gray-500">
          <%= Timex.from_now(@post.inserted_at) %>
        </div>
      </div>
      <p class="my-2">
        <%= @post.content.message %>
      </p>
    </div>
    """
  end

  attr :point_marker, :map, required: true
  attr :selected, :boolean, default: false
  attr :count, :integer, default: nil

  def annotation_bubble(assigns) do
    ~H"""
    <button
      class="absolute right-[-15px] cursor-pointer group"
      style={"top: #{@point_marker.top}px"}
      phx-click="select_annotation_point"
      phx-value-point-marker-id={@point_marker.id}
    >
      <.chat_bubble selected={@selected} count={@count} />
    </button>
    """
  end

  attr :selected, :boolean, default: false
  attr :count, :integer, default: nil

  def chat_bubble(assigns) do
    ~H"""
    <svg
      width="31"
      height="31"
      viewBox="0 0 31 31"
      fill="none"
      class="group-hover:scale-110 group-active:scale-100"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M30 14.6945C30.0055 16.8209 29.5087 18.9186 28.55 20.8167C27.4132 23.0912 25.6657 25.0042 23.5031 26.3416C21.3405 27.679 18.8483 28.3879 16.3055 28.3889C14.1791 28.3944 12.0814 27.8976 10.1833 26.9389L1 30L4.06111 20.8167C3.10239 18.9186 2.60556 16.8209 2.61111 14.6945C2.61209 12.1517 3.32098 9.65951 4.65837 7.49692C5.99577 5.33433 7.90884 3.58679 10.1833 2.45004C12.0814 1.49132 14.1791 0.994502 16.3055 1.00005H17.1111C20.4692 1.18531 23.641 2.60271 26.0191 4.98087C28.3973 7.35902 29.8147 10.5308 30 13.8889V14.6945Z"
        class={[
          "",
          if(@selected, do: "fill-primary stroke-primary", else: "fill-white stroke-gray-300")
        ]}
        stroke-width="1.61111"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
      <%= case @count do %>
        <% nil -> %>
          <text
            x="52%"
            y="50%"
            dominant-baseline="middle"
            text-anchor="middle"
            class={["text-xl", if(@selected, do: "fill-white", else: "fill-gray-500")]}
          >
            +
          </text>
        <% _ -> %>
          <text
            x="52%"
            y="50%"
            dominant-baseline="middle"
            text-anchor="middle"
            class={["text-sm", if(@selected, do: "fill-white", else: "fill-gray-500")]}
          >
            <%= @count %>
          </text>
      <% end %>
    </svg>
    """
  end

  def replies_bubble_icon(assigns) do
    ~H"""
    <svg width="23" height="23" viewBox="0 0 23 23" fill="none" xmlns="http://www.w3.org/2000/svg">
      <line x1="6.16821" y1="8.60156" x2="16.0243" y2="8.60156" stroke="#2D3648" stroke-width="1.5" />
      <line x1="6.16821" y1="13.6055" x2="16.0243" y2="13.6055" stroke="#2D3648" stroke-width="1.5" />
      <path
        fill-rule="evenodd"
        clip-rule="evenodd"
        d="M11.7869 2.27309C7.1428 2.27309 3.37805 6.03784 3.37805 10.6819C3.37805 12.0261 3.69262 13.2936 4.25113 14.4177C4.38308 14.6833 4.4045 14.9903 4.31072 15.2717L2.8872 19.5421L7.20077 18.1512C7.47968 18.0613 7.78271 18.084 8.04505 18.2146C9.17069 18.775 10.4403 19.0907 11.7869 19.0907C16.4309 19.0907 20.1957 15.3259 20.1957 10.6819C20.1957 6.03784 16.4309 2.27309 11.7869 2.27309ZM1.13425 10.6819C1.13425 4.79863 5.90359 0.0292969 11.7869 0.0292969C17.6701 0.0292969 22.4395 4.79863 22.4395 10.6819C22.4395 16.5652 17.6701 21.3345 11.7869 21.3345C10.2515 21.3345 8.78951 21.009 7.46835 20.4225L1.46623 22.3579C1.06368 22.4877 0.622338 22.38 0.324734 22.0795C0.0271304 21.779 -0.0761506 21.3366 0.0576046 20.9353L2.04039 14.9871C1.45758 13.6695 1.13425 12.2121 1.13425 10.6819Z"
        fill="#2D3648"
      />
    </svg>
    """
  end
end