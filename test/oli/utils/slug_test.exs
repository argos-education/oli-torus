defmodule Oli.Utils.SlugTest do
  use Oli.DataCase

  import Ecto.Query, warn: false

  alias Oli.Utils.Slug

  alias Oli.Authoring.Course.Project
  alias Oli.Delivery.Sections.{SectionInvite, SectionResource}
  alias Oli.Delivery.Sections
  alias Oli.Resources.Revision
  alias Oli.Repo
  alias Ecto.Changeset

  describe "resources" do
    setup do
      map = Seeder.base_project_with_resource2()

      # Create another project with resources and revisions
      Seeder.another_project(map.author, map.institution)

      map
    end

    test "get unique prefix", _ do
      assert Slug.get_unique_prefix("revisions") |> String.length() == 5
    end

    test "slug with prefix", _ do
      slug = Slug.slug_with_prefix("12345", "title")
      assert String.length(slug) == 17
      parts = String.split(slug, "_")
      assert Enum.count(parts) == 3
      assert Enum.at(parts, 0) == "12345"
      assert Enum.at(parts, 1) == "title"
    end

    test "alpha numeric only", _ do
      alpha_numeric = Slug.alpha_numeric_only("My_Test Project ~!@#$%^&*()--+=[]{}\|;:'<>,./?")
      assert alpha_numeric == "My_TestProject"
    end

    test "update_on_change/2 does not update the slug when the previous revision title matches",
         %{revision1: r} do
      {:ok, new_revision} =
        Revision.changeset(%Revision{}, %{
          previous_revision_id: r.id,
          title: r.title,
          resource_id: r.resource_id,
          resource_type_id: r.resource_type_id,
          author_id: r.author_id
        })
        |> Repo.insert()

      assert new_revision.slug == r.slug
    end

    test "update_on_change/2 creates non-empty slug when title contains special characters", %{
      revision1: r
    } do
      {:ok, new_revision} =
        Revision.changeset(%Revision{}, %{
          previous_revision_id: r.id,
          title: "灵丹妙药",
          resource_id: r.resource_id,
          resource_type_id: r.resource_type_id,
          author_id: r.author_id
        })
        |> Repo.insert()

      assert new_revision.slug != r.slug
      assert String.length(new_revision.slug) == 10
    end

    test "update_on_change/2 does update the slug when the previous revision title differs", %{
      revision1: r
    } do
      {:ok, new_revision} =
        Revision.changeset(%Revision{}, %{
          previous_revision_id: r.id,
          title: "a different title",
          resource_id: r.resource_id,
          resource_type_id: r.resource_type_id,
          author_id: r.author_id
        })
        |> Repo.insert()

      refute new_revision.slug == r.slug
      assert new_revision.slug == "a_different_title"
    end


    test "update_on_change/2 handles the case when there isn't a previous revision", %{
      revision1: r
    } do
      {:ok, new_revision} =
        Revision.changeset(%Revision{}, %{
          title: "a different title",
          resource_id: r.resource_id,
          resource_type_id: r.resource_type_id,
          author_id: r.author_id
        })
        |> Repo.insert()

      assert new_revision.slug == "a_different_title"
    end

    test "update_on_change/2 updates the slug when the title changes", %{revision1: r} do
      # clearly a change that doesn't involve the title
      assert Revision.changeset(r, %{graded: true})
             |> Slug.update_on_change("revisions")
             |> Changeset.get_change(:slug) == nil

      # a change involving the title, but not actually changing it
      assert Revision.changeset(r, %{title: r.title})
             |> Slug.update_on_change("revisions")
             |> Changeset.get_change(:slug) == nil

      # changing the title
      assert Revision.changeset(r, %{title: "a changed title"})
             |> Slug.update_on_change("revisions")
             |> Changeset.get_change(:slug) == "a_changed_title"

      Revision.changeset(r, %{title: "a changed title"})
      |> Repo.update()

      r = Repo.get!(Revision, r.id)
      assert r.slug == "a_changed_title"

      Revision.changeset(r, %{title: "a changed title"})
      |> Repo.update()

      r = Repo.get!(Revision, r.id)
      assert r.slug == "a_changed_title"
    end

    test "update_never/2 does not update the slug when the title changes", %{project: p} do
      assert Project.changeset(p, %{version: "2"})
             |> Slug.update_never("projects")
             |> Changeset.get_change(:slug) == nil

      assert Project.changeset(p, %{title: "a changed title"})
             |> Slug.update_never("projects")
             |> Changeset.get_change(:slug) == nil
    end

    test "update_on_change/2 produces valid slug when the title contains non-alphanumeric and special characters",
         %{revision1: r} do
      {:ok, new_revision} =
        Revision.changeset(%Revision{}, %{
          previous_revision_id: r.id,
          # apostrophe is a special character
          title: "What’s in a Name?",
          resource_id: r.resource_id,
          resource_type_id: r.resource_type_id,
          author_id: r.author_id
        })
        |> Repo.insert()

      refute new_revision.slug == r.slug
      assert new_revision.slug == "whats_in_a_name"
    end

    test "update_never_seedless/2 produces a valid alphanumeric slug", %{project: project} do
      {:ok, section} =
        Sections.create_section(%{
          base_project_id: project.id,
          title: "some title",
          context_id: "context_id"
        })

      section_invite =
        Ecto.Changeset.change(%SectionInvite{}, %{
          section_id: section.id,
          date_expires: DateTime.truncate(now(), :second)
        })
        |> Slug.update_never_seedless("section_invites")
        |> Repo.insert!()

      slug = section_invite.slug

      assert slug =~ ~r/^[a-zA-Z0-9]+$/
    end

    test "update_never_seedless/2 cannot be changed", %{project: project} do
      {:ok, section} =
        Sections.create_section(%{
          base_project_id: project.id,
          title: "some title",
          context_id: "context_id"
        })

      section_invite =
        Ecto.Changeset.change(%SectionInvite{}, %{
          section_id: section.id,
          date_expires: DateTime.truncate(now(), :second)
        })
        |> Slug.update_never_seedless("section_invites")
        |> Repo.insert!()

      slug = section_invite.slug

      updated_section_invite =
        SectionInvite.changeset(section_invite)
        |> Slug.update_never_seedless("section_invites")
        |> Repo.update!()

      assert slug == updated_section_invite.slug
    end

    test "generate_nth/2 generates a slug with no suffix in the first attempt" do
      assert Slug.generate_nth("Hello World", 0) == "hello_world"
    end

    test "generate_nth/2 generates a slug with a 5-chars-long suffix before the fifth attempt" do
      assert Slug.generate_nth("Hello World", Enum.random(1..4)) =~ ~r/hello_world_\w{5,5}/
    end

    test "generate_nth/2 generates a slug with a 10-chars-long suffix after the fifth attempt" do
      assert Slug.generate_nth("Hello World", Enum.random(5..10)) =~ ~r/hello_world_\w{10,10}/
    end

    test "generate/2 generates a unique slug using the title provided", %{revision1: r} do
      slug = Slug.generate("section_resources", r.title)

      refute Repo.exists?(from sr in SectionResource, where: sr.slug == ^slug)
    end

    test "generate/2 generates a list of unique slugs using the titles provided", %{
      revision1: r1,
      revision2: r2
    } do
      slugs = Slug.generate("section_resources", [r1.title, r2.title])

      refute Repo.exists?(from sr in SectionResource, where: sr.slug in ^slugs)
    end
  end
end
