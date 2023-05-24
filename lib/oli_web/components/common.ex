defmodule OliWeb.Components.Common do
  use Phoenix.Component

  def not_found(assigns) do
    ~H"""
    <main role="main" class="container mx-auto">
      <div class="alert alert-danger mt-3" role="alert">
        <h4 class="alert-heading">Not Found</h4>
        <p>The page you are trying to access does not exist. If you think this is an error, please contact support.</p>
        <hr>
        <p class="mb-0"><b>Tip:</b> Check the URL or link and try again.</p>
      </div>
    </main>
    """
  end
end
