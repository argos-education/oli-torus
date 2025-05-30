defmodule OliWeb.WorkspaceControllerTest do
  use OliWeb.ConnCase
  alias Oli.Repo
  alias Oli.Seeder

  describe "projects" do
    test "displays the projects page", %{conn: conn} do
      {:ok, conn: conn, author: _author} = author_conn(%{conn: conn})
      conn = get(conn, Routes.live_path(OliWeb.Endpoint, OliWeb.Projects.ProjectsLive))
      assert html_response(conn, 200) =~ "Projects"
    end

    test "author has projects -> displays projects", %{conn: conn} do
      {:ok, conn: conn, author: author} = author_conn(%{conn: conn})
      make_n_projects(3, author)

      conn = get(conn, Routes.live_path(OliWeb.Endpoint, OliWeb.Projects.ProjectsLive))
      assert length(Repo.preload(author, [:projects]).projects) == 3
      assert !(html_response(conn, 200) =~ "None exist")
    end

    test "author has no projects -> displays no projects", %{conn: conn} do
      {:ok, conn: conn, author: author} = author_conn(%{conn: conn})
      make_n_projects(0, author)

      conn = get(conn, Routes.live_path(OliWeb.Endpoint, OliWeb.Projects.ProjectsLive))
      assert Enum.empty?(Repo.preload(author, [:projects]).projects)
      assert html_response(conn, 200) =~ "None exist"
    end

    test "Has a `create project` button", %{conn: conn} do
      {:ok, conn: conn, author: _author} = author_conn(%{conn: conn})
      conn = get(conn, Routes.live_path(OliWeb.Endpoint, OliWeb.Projects.ProjectsLive))
      assert html_response(conn, 200) =~ "New Project"
    end

    test "login fails if author is deleted", %{conn: conn} do
      {:ok, conn: conn, author: author} = author_conn(%{conn: conn})

      {:ok, _} = Oli.Accounts.delete_author(author)

      conn = get(conn, Routes.live_path(OliWeb.Endpoint, OliWeb.Projects.ProjectsLive))
      assert html_response(conn, 302) =~ "You are being <a href=\"/authors/log_in"
    end

    test "can still access the projects page if an author is deleted", %{conn: conn} do
      %{author: author, author2: author2} = Seeder.base_project_with_resource2()

      {:ok, _} = Oli.Accounts.delete_author(author)

      conn =
        log_in_author(conn, author2)

      conn = get(conn, Routes.live_path(OliWeb.Endpoint, OliWeb.Projects.ProjectsLive))
      assert html_response(conn, 200) =~ "Projects"
      assert html_response(conn, 200) =~ "Example Open and Free Course"
    end
  end
end
