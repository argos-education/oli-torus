defmodule OliWeb.Delivery.FindMyInstitution do
  use OliWeb, :surface_view

  alias Oli.Predefined
  alias Surface.Components.Link

  @push_patch_path &__MODULE__.live_path/2
  @limit_increment 10

  def mount(
        _params,
        _session,
        socket
      ) do
    world_universities_and_domains = Predefined.world_universities_and_domains()
      |> Enum.map(fn item ->
        item
        |> Map.put(:s_name, String.downcase(item.name))
        |> Map.put(:s_institution_url, String.downcase(item.institution_url))
      end)


    {:ok,
     assign(socket,
       world_universities_and_domains: world_universities_and_domains,
       text_search: "",
       results: [],
       limit_results: @limit_increment,
       limit_increment: @limit_increment
     )}
  end

  def handle_params(params, _, socket) do
    %{world_universities_and_domains: world_universities_and_domains} = socket.assigns
    text_search = Map.get(params, "text_search", "")

    {:noreply,
     assign(socket,
       text_search: text_search,
       results: search(text_search, world_universities_and_domains),
       limit_results: @limit_increment
     )}
  end

  defp search("", _), do: []

  defp search(text_search, world_universities_and_domains) do
    s_text_search = String.downcase(text_search)

    world_universities_and_domains
    |> Enum.filter(fn item -> String.contains?(item.s_name, s_text_search) || String.contains?(item.s_institution_url, s_text_search) end)
  end

  def render(assigns) do
    ~F"""
    <div class="container">
      <div class="row">
        <div class="col-sm-12 col-md-10 col-lg-8 col-xl-8 mx-auto">
          <div class="mb-3">
            <span>
              <Link to={Routes.pow_session_path(OliWeb.Endpoint, :new)}>
                  <i class="las la-arrow-left"></i> Back
              </Link>
            </span>
          </div>

          <h3>Find my Institution</h3>

          <div class="input-group mb-3">
            <input type="text" class="form-control" placeholder="Search for your institution..." aria-label="Search for your institution..." value={@text_search} phx-hook="TextInputListener" phx-value-change="apply_search" phx-throttle={500}>

            <div class="input-group-append">
              {#if @text_search != ""}
                <button class="input-group-text" value="" :on-click="apply_search"><i class="las la-times"></i></button>
              {#else}
                <span class="input-group-text"><i class="las la-search"></i></span>
              {/if}
            </div>
          </div>

          {#if @text_search != ""}
            <div class="list-group">
              {#for %{name: name, institution_url: institution_url} <- @results |> Enum.take(@limit_results)}
                <a href={institution_url} class="list-group-item list-group-item-action">
                  <div class="d-flex w-100 justify-content-between">
                    <h5 class="mb-1">{name}</h5>
                  </div>
                  <p class="mb-1">{institution_url}</p>
                </a>
              {#else}
                No Results
              {/for}

              {#if @limit_results < Enum.count(@results)}
                <div class="text-center">
                  <button class="btn btn-sm btn-link" :on-click="load_more">Load {@limit_increment} more...</button>
                </div>
              {/if}
            </div>
          {/if}

        </div>
      </div>
    </div>
    """
  end

  def handle_event("apply_search", %{"value" => value}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         @push_patch_path.(
           socket,
           %{"text_search" => value}
         ),
       replace: true
     )}
  end

  def handle_event("load_more", _, socket) do
    {:noreply,
     assign(socket, limit_results: socket.assigns.limit_results + @limit_increment
     )}
  end

  def live_path(socket, params) do
    Routes.live_path(socket, __MODULE__, params)
  end

end
