defmodule Oli.Delivery.Metrics do
  import Ecto.Query, warn: false

  alias Oli.Repo
  alias Oli.Analytics.DataTables.DataTable
  alias Oli.Delivery.Attempts.Core.{ResourceAccess, ActivityAttempt}
  alias Oli.Delivery.Attempts.Core

  alias Oli.Delivery.Sections.{
    ContainedPage,
    Enrollment,
    EnrollmentContextRole,
    Section,
    SectionResource
  }

  alias Oli.Delivery.Snapshots.Snapshot
  alias Oli.Accounts.User
  alias Lti_1p3.Tool.ContextRoles

  def progress_datatable_for(section_id, container_id) do
    learner_id = ContextRoles.get_role(:context_learner).id

    users = from(e in Enrollment,
      join: ecr in assoc(e, :context_roles),
      join: u in assoc(e, :user),
      where: e.section_id == ^section_id,
      where: ecr.id == ^learner_id,
      select: u,
      distinct: u
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn user, acc -> Map.put(acc, user.id, user) end)

    user_ids = Map.keys(users)

    progress_for(section_id, user_ids, container_id)
    |> Enum.reduce([], fn {user_id, progress}, acc ->
      [%{
        id: user_id,
        name: users[user_id].name,
        email: users[user_id].email,
        progress: progress
      } | acc]
    end)
    |> DataTable.new()
    |> DataTable.headers([:id, :name, :email, :progress])

  end

  @doc """
  Calculate the progress for a specific student (or a list of students),
  in all pages of a specific container.

  Omitting the container_id (or specifying nil) calculates progress
  across the entire course section.

  This query leverages the `contained_pages` relation, which is always an
  up to date view of the structure of a course section. This allows this
  query to take into account structural changes as the result of course
  remix. The `contained_pages` relation is rebuilt after every remix.

  It returns a map:

    %{user_id_1 => user_1_progress,
      ...
      user_id_n => user_n_progress
    }
  """
  @spec progress_for(
          section_id :: integer,
          user_id :: integer | list(integer),
          container_id :: integer | nil
        ) :: map
  def progress_for(section_id, user_id, container_id \\ nil) do
    user_id_list = if is_list(user_id), do: user_id, else: [user_id]

    filter_by_container =
      case container_id do
        nil ->
          dynamic([cp, _], is_nil(cp.container_id))

        _ ->
          dynamic([cp, _], cp.container_id == ^container_id)
      end

    pages_count =
      from(cp in ContainedPage)
      |> where([cp], cp.section_id == ^section_id)
      |> where(^filter_by_container)
      |> select([cp], count(cp.id))
      |> Repo.one()
      |> max(1)

    query =
      ContainedPage
      |> join(:inner, [cp], ra in ResourceAccess,
        on:
          cp.page_id == ra.resource_id and cp.section_id == ra.section_id and
            ra.user_id in ^user_id_list
      )
      |> where([cp, ra], cp.section_id == ^section_id)
      |> where(^filter_by_container)
      |> group_by([_cp, ra], ra.user_id)
      |> select([cp, ra], {ra.user_id, fragment("SUM(?)", ra.progress) / ^pages_count})

    Repo.all(query)
    |> Enum.into(%{})
  end

  defp do_get_progress_for_page(section_id, user_ids, page_id) do
    filter_by_user =
      case is_list(user_ids) do
        true -> dynamic([ra], ra.user_id in ^user_ids)
        _ -> dynamic([ra], ra.user_id == ^user_ids)
      end

    from(ra in ResourceAccess,
      where: ra.resource_id == ^page_id and ra.section_id == ^section_id,
      where: ^filter_by_user,
      group_by: ra.user_id,
      select: {
        ra.user_id,
        fragment(
          "SUM(?)",
          ra.progress
        )
      }
    )
  end

  @doc """
  Calculate the progress for a given student or list of students in a page.
  """
  def progress_for_page(_section_id, [], _), do: []

  def progress_for_page(section_id, [_ | _] = user_ids, page_id),
    do:
      do_get_progress_for_page(section_id, user_ids, page_id)
      |> Repo.all()
      |> Enum.into(%{})

  def progress_for_page(section_id, user_id, page_id) do
    case do_get_progress_for_page(section_id, user_id, page_id) |> Repo.one() do
      nil -> 0
      {_, progress} -> progress
    end
  end

  @doc """
  Calculate the percentage of students that have completed a container or page
  """
  def completion_for(section_id, container_id) do
    completions =
      User
      |> join(:inner, [u], e in Enrollment, on: u.id == e.user_id and e.section_id == ^section_id and e.status == :enrolled)
      |> join(:inner, [u, e], ecr in EnrollmentContextRole,
        on:
          ecr.enrollment_id == e.id and
            ecr.context_role_id == ^ContextRoles.get_role(:context_learner).id
      )
      |> join(:left, [u, e], ra in ResourceAccess,
        on:
          ra.user_id == u.id and ra.section_id == ^section_id and
            ra.resource_id == ^container_id
      )
      |> select([_, _, _, ra], %{
        progress: ra.progress
      })
      |> Repo.all()

    case length(completions) do
      0 -> 0.0
      length -> Enum.count(completions, &(&1.progress == 1)) / length * 100
    end
  end

  @doc """
  Calculate the progress for a specific student, in all pages of a
  collection of containers.
  """
  def progress_across(section_id, container_ids, user_id) do
    query =
      ContainedPage
      |> join(:left, [cp], ra in ResourceAccess,
        on:
          cp.page_id == ra.resource_id and cp.section_id == ra.section_id and
            ra.user_id == ^user_id
      )
      |> where([cp, ra], cp.section_id == ^section_id and cp.container_id in ^container_ids)
      |> group_by([cp, ra], cp.container_id)
      |> select([cp, ra], {
        cp.container_id,
        fragment(
          "SUM(?) / COUNT(*)",
          ra.progress
        )
      })

    Repo.all(query)
    |> Enum.into(%{})
  end

  @doc """
  Calculate the progress for all students, in all pages of a
  collection of containers.

  The last two parameters gives flexibility into excluding specific users
  from the calculation. This exists primarily to exclude instructors.
  `user_ids_to_ignore` can be an empty list, but `user_count` should always be the total
  number of enrolled students (excluding the count of those in the exlusion parameter).
  """
  def progress_across(section_id, container_ids, user_ids_to_ignore, user_count) do
    # If zero was passed in, we can allow the query to execute correctly and avoid a divide by zero by
    # simply changing it to 1
    user_count = max(user_count, 1)

    query =
      ContainedPage
      |> join(:left, [cp], ra in ResourceAccess,
        on: cp.page_id == ra.resource_id and cp.section_id == ra.section_id
      )
      |> join(:left, [cp, _], sr in SectionResource,
        on: cp.container_id == sr.resource_id and cp.section_id == sr.section_id
      )
      |> where(
        [cp, ra, _],
        cp.section_id == ^section_id and cp.container_id in ^container_ids and
          ra.user_id not in ^user_ids_to_ignore
      )
      |> group_by([cp, ra, sr], [cp.container_id, sr.contained_page_count])
      |> select([cp, ra, sr], {
        cp.container_id,
        fragment(
          "SUM(?) / (? * ?)",
          ra.progress,
          sr.contained_page_count,
          ^user_count
        )
      })

    Repo.all(query)
    |> Enum.into(%{})
  end

  @doc """
  Calculate the progress for all students in a collection of pages.

  The last two parameters gives flexibility into excluding specific users
  from the calculation. This exists primarily to exclude instructors.
  `user_ids_to_ignore` can be an empty list, but `user_count` should always be the total
  number of enrolled students (excluding the count of those in the exlusion parameter).
  """
  def progress_across_for_pages(section_id, pages_ids, user_ids_to_ignore, user_count) do
    user_count = max(user_count, 1)

    query =
      from(ra in ResourceAccess,
        where:
          ra.resource_id in ^pages_ids and ra.section_id == ^section_id and
            ra.user_id not in ^user_ids_to_ignore,
        group_by: ra.resource_id,
        select: {
          ra.resource_id,
          fragment(
            "SUM(?) / (?)",
            ra.progress,
            ^user_count
          )
        }
      )

    Repo.all(query)
    |> Enum.into(%{})
  end

  @doc """
  Calculate the progress for a specific student in a collection of pages.
  """
  def progress_across_for_pages(section_id, pages_ids, student_id) do
    query =
      from(ra in ResourceAccess,
        where:
          ra.resource_id in ^pages_ids and ra.section_id == ^section_id and
            ra.user_id == ^student_id,
        group_by: ra.resource_id,
        select: {
          ra.resource_id,
          fragment(
            "SUM(?) / COUNT(*)",
            ra.progress
          )
        }
      )

    Repo.all(query)
    |> Enum.into(%{})
  end

  @doc """
  Calculate the average score for a specific student (or a list of students),
  in all pages of a specific container.

  Omitting the container_id (or specifying nil) calculates average score
  across the entire course section.

  This query leverages the `contained_pages` relation, which is always an
  up to date view of the structure of a course section. This allows this
  query to take into account structural changes as the result of course
  remix. The `contained_pages` relation is rebuilt after every remix.

  It returns a map:

    %{user_id_1 => user_1_avg_score,
      ...
      user_id_n => user_n_avg_score
    }
  """
  @spec avg_score_for(
          section_id :: integer,
          user_id :: integer | list(integer),
          container_id :: integer | nil
        ) :: map

  def avg_score_for(section_id, user_id, container_id \\ nil) do
    user_id_list = if is_list(user_id), do: user_id, else: [user_id]

    filter_by_container =
      case container_id do
        nil ->
          dynamic([cp, _], is_nil(cp.container_id))

        _ ->
          dynamic([cp, _], cp.container_id == ^container_id)
      end

    query =
      ContainedPage
      |> join(:inner, [cp], ra in ResourceAccess,
        on:
          cp.page_id == ra.resource_id and cp.section_id == ra.section_id and
            ra.user_id in ^user_id_list
      )
      |> where([cp, ra], cp.section_id == ^section_id and not is_nil(ra.score))
      |> where(^filter_by_container)
      |> group_by([_cp, ra], ra.user_id)
      |> select(
        [cp, ra],
        {ra.user_id, fragment("SUM(?)", ra.score) / fragment("COUNT(?)", ra.out_of)}
      )

    Repo.all(query)
    |> Enum.into(%{})
  end

  @doc """
  Calculates the students latest interaction across all pages of a given container (the max value).
  Omitting the container_id (or specifying nil) calculates students latest interaction
  across the entire course section.
  If an enrolled student has not yet interacted, it returns the :updated_at time stamp of his enrollment.

  It returns a map:

    %{student_id_1 => student_1_last_interaction,
      ...
      student_id_n => student_n_last_interaction
    }
  """
  @spec students_last_interaction_across(section :: map, container_id :: any) :: map
  def students_last_interaction_across(section, container_id \\ nil) do
    on =
      case container_id do
        nil ->
          dynamic([_s, e, ra], e.user_id == ra.user_id)

        _ ->
          pages_for_container =
            from(cp in ContainedPage,
              where: cp.section_id == ^section.id and cp.container_id == ^container_id,
              select: cp.page_id
            )
            |> Repo.all()

          dynamic([_s, e, ra], e.user_id == ra.user_id and ra.resource_id in ^pages_for_container)
      end

    query =
      from(
        s in Section,
        join: e in Enrollment,
        on: e.section_id == s.id,
        left_join: ra in ResourceAccess,
        on: ^on,
        where: s.slug == ^section.slug and e.status == :enrolled,
        group_by: [e.user_id, e.updated_at],
        select: {
          e.user_id,
          fragment(
            "coalesce(MAX(?), ?)",
            ra.updated_at,
            e.updated_at
          )
        }
      )

    Repo.all(query)
    |> Enum.into(%{})
  end

  @doc """
  Calculates the students latest interaction for a given section page:
  the latest :updated_at time stamp across all ResourceAccess records for each student for a given page.
  If an enrolled student has not yet interacted in that page, it returns the :updated_at time stamp of his enrollment.

    It returns a map:

    %{student_id_1 => student_1_last_interaction,
      ...
      student_id_n => student_n_last_interaction
    }
  """
  @spec students_last_interaction_for_page(section_slug :: String.t(), page_id :: integer) :: map
  def students_last_interaction_for_page(section_slug, page_id) do
    query =
      from(
        s in Section,
        join: e in Enrollment,
        on: e.section_id == s.id,
        left_join: ra in ResourceAccess,
        on: e.user_id == ra.user_id,
        where: s.slug == ^section_slug and (ra.resource_id == ^page_id or is_nil(ra.resource_id)) and e.status == :enrolled,
        group_by: [e.user_id, e.updated_at],
        select: {
          e.user_id,
          fragment(
            "coalesce(MAX(?), ?)",
            ra.updated_at,
            e.updated_at
          )
        }
      )

    Repo.all(query)
    |> Enum.into(%{})
  end

  @doc """
  Calculates the learning mastery ("High", "Medium", "Low", "Not enough data")
  for every learning objective of a given section

    It returns a map:

    %{objective_id_1 => "High",
      ...
      objective_id_n => "Low"
    }
  """
  def mastery_per_learning_objective(section_slug) do
    query =
      from(sn in Snapshot,
        join: s in Section,
        on: sn.section_id == s.id,
        where: sn.attempt_number == 1 and sn.part_attempt_number == 1 and s.slug == ^section_slug,
        group_by: sn.objective_id,
        select:
          {sn.objective_id,
           fragment(
             "CAST(COUNT(CASE WHEN ? THEN 1 END) as float) / CAST(COUNT(*) as float)",
             sn.correct
           )}
      )

    Repo.all(query)
    |> Enum.into(%{}, fn {objective_id, mastery} -> {objective_id, mastery_range(mastery)} end)
  end

  def mastery_for_student_per_learning_objective(section_slug, student_id) do
    query =
      from(sn in Snapshot,
        join: s in Section,
        on: sn.section_id == s.id,
        where:
          sn.attempt_number == 1 and sn.part_attempt_number == 1 and s.slug == ^section_slug and
            sn.user_id == ^student_id,
        group_by: sn.objective_id,
        select:
          {sn.objective_id,
           fragment(
             "CAST(COUNT(CASE WHEN ? THEN 1 END) as float) / CAST(COUNT(*) as float)",
             sn.correct
           )}
      )

    Repo.all(query)
    |> Enum.into(%{}, fn {objective_id, mastery} -> {objective_id, mastery_range(mastery)} end)
  end

  @doc """
  Calculates the learning mastery ("High", "Medium", "Low", "Not enough data")
  for every container of a given section

    It returns a map:

    %{container_id_1 => "High",
      ...
      container_id_n => "Low"
    }
  """
  def mastery_per_container(section_slug) do
    query =
      from(sn in Snapshot,
        join: s in Section,
        on: sn.section_id == s.id,
        join: cp in ContainedPage,
        on: cp.page_id == sn.resource_id,
        where: sn.attempt_number == 1 and sn.part_attempt_number == 1 and s.slug == ^section_slug,
        group_by: cp.container_id,
        select:
          {cp.container_id,
           fragment(
             "CAST(COUNT(CASE WHEN ? THEN 1 END) as float) / CAST(COUNT(*) as float)",
             sn.correct
           )}
      )

    Repo.all(query)
    |> Enum.into(%{}, fn {container_id, mastery} ->
      {container_id, mastery_range(mastery)}
    end)
  end

  @doc """
  Calculates the learning mastery ("High", "Medium", "Low", "Not enough data")
  for every student across a given container.
  Omitting the container_id (or specifying nil) calculates students learning mastery
  across the entire course section.

    It returns a map:

    %{student_id_1 => "High",
      ...
      student_id_n => "Low"
    }
  """
  def mastery_per_student_across(section, container_id \\ nil) do
    filter_by_container =
      case container_id do
        nil ->
          true

        _ ->
          pages_for_container =
            from(cp in ContainedPage,
              where: cp.section_id == ^section.id and cp.container_id == ^container_id,
              select: cp.page_id
            )
            |> Repo.all()

          dynamic([sn, _s], sn.resource_id in ^pages_for_container)
      end

    query =
      from(sn in Snapshot,
        join: s in Section,
        on: sn.section_id == s.id,
        where: sn.attempt_number == 1 and sn.part_attempt_number == 1 and s.slug == ^section.slug,
        where: ^filter_by_container,
        group_by: sn.user_id,
        select:
          {sn.user_id,
           fragment(
             "CAST(COUNT(CASE WHEN ? THEN 1 END) as float) / CAST(COUNT(*) as float)",
             sn.correct
           )}
      )

    Repo.all(query)
    |> Enum.into(%{}, fn {student_id, mastery} ->
      {student_id, mastery_range(mastery)}
    end)
  end

  @doc """
  Calculates the learning mastery ("High", "Medium", "Low", "Not enough data")
  for every container of a given section for a given student

    It returns a map:

    %{container_id_1 => "High",
      ...
      container_id_n => "Low"
    }
  """
  def mastery_for_student_per_container(section_slug, student_id) do
    query =
      from(sn in Snapshot,
        join: s in Section,
        on: sn.section_id == s.id,
        join: cp in ContainedPage,
        on: sn.resource_id == cp.page_id,
        where:
          sn.attempt_number == 1 and sn.part_attempt_number == 1 and s.slug == ^section_slug and
            sn.user_id == ^student_id,
        group_by: cp.container_id,
        select:
          {cp.container_id,
           fragment(
             "CAST(COUNT(CASE WHEN ? THEN 1 END) as float) / CAST(COUNT(*) as float)",
             sn.correct
           )}
      )

    Repo.all(query)
    |> Enum.into(%{}, fn {student_id, mastery} ->
      {student_id, mastery_range(mastery)}
    end)
  end

  @doc """
  Calculates the learning mastery ("High", "Medium", "Low", "Not enough data")
  for each student of a given section for a specific page

    It returns a map:

    %{student_id_1 => "High",
      ...
      student_id_n => "Low"
    }
  """
  def mastery_per_student_for_page(section_slug, page_id) do
    query =
      from(sn in Snapshot,
        join: s in Section,
        on: sn.section_id == s.id,
        where:
          sn.attempt_number == 1 and sn.part_attempt_number == 1 and s.slug == ^section_slug and
            sn.resource_id == ^page_id,
        group_by: sn.user_id,
        select:
          {sn.user_id,
           fragment(
             "CAST(COUNT(CASE WHEN ? THEN 1 END) as float) / CAST(COUNT(*) as float)",
             sn.correct
           )}
      )

    Repo.all(query)
    |> Enum.into(%{}, fn {student_id, mastery} -> {student_id, mastery_range(mastery)} end)
  end

  defp mastery_range(nil), do: "Not enough data"
  defp mastery_range(mastery) when mastery <= 0.5, do: "Low"
  defp mastery_range(mastery) when mastery <= 0.8, do: "Medium"
  defp mastery_range(_mastery), do: "High"

  @doc """
  Updates page progress to be 100% complete.
  """
  def mark_progress_completed(%ResourceAccess{} = ra) do
    Core.update_resource_access(ra, %{progress: 1.0})
  end

  @doc """
  Resets page progress to be 0% complete.
  """
  def reset_progress(%ResourceAccess{} = ra) do
    Core.update_resource_access(ra, %{progress: 0.0})
  end

  @doc """
  For an activity attempt specified by an attempt guid, calculate and set in the corresponding resource access
  record, the percentage complete for the related page. This calculation only needs to be performed after the
  evaluation of the first attempt for given activity.  This method should update exactly one record, the resource
  access for the page that this activity attempt ultimately pertains to (through its parent resource attempt).

  Can return one of:
  {:ok, :updated} -> Progress calculated and set
  {:ok, :noop} -> Noting needed to be done, since the attempt number was greater than 1
  {:error, :unexpected_update_count} -> 0 or more than 1 record would have been updated, rolled back
  {:error, e} -> An other error occurred, rolled back
  """
  def update_page_progress(activity_attempt_guid) when is_binary(activity_attempt_guid) do
    if Core.is_first_activity_attempt?(activity_attempt_guid) do
      do_update(activity_attempt_guid)
    else
      {:ok, :noop}
    end
  end

  def update_page_progress(%ActivityAttempt{attempt_number: 1, attempt_guid: attempt_guid}) do
    do_update(attempt_guid)
  end

  def update_page_progress(_) do
    {:ok, :noop}
  end

  defp do_update(activity_attempt_guid) do
    Oli.Repo.transaction(fn ->
      sql = """
        UPDATE
          resource_accesses
        SET
          progress = (SELECT
              COUNT(aa2.id) filter (WHERE aa2.lifecycle_state = 'evaluated' OR aa2.lifecycle_state = 'submitted')::float / COUNT(aa2.id)::float
            FROM activity_attempts as aa
            JOIN resource_attempts as ra ON ra.id = aa.resource_attempt_id
            JOIN activity_attempts as aa2 ON ra.id = aa2.resource_attempt_id
            WHERE aa.attempt_guid = $1 AND aa2.scoreable = true AND aa2.attempt_number = 1),
          updated_at = NOW()
        WHERE
          id =
            (SELECT
              resource_attempts.resource_access_id
            FROM resource_attempts
            JOIN activity_attempts ON resource_attempts.id = activity_attempts.resource_attempt_id
            WHERE activity_attempts.attempt_guid = $2
            LIMIT 1);
      """

      case Ecto.Adapters.SQL.query(Oli.Repo, sql, [activity_attempt_guid, activity_attempt_guid]) do
        {:ok, %{num_rows: 1}} -> :updated
        {:ok, %{num_rows: _}} -> Oli.Repo.rollback(:unexpected_update_count)
        {:error, e} -> Oli.Repo.rollback(e)
      end
    end)
  end

  @doc """
    Returns the last time a user accessed a section
  """

  def get_last_access_for_user_in_a_section(user_id, section_id) do
    query =
      from(u in User,
        join: enr in Enrollment,
        on: enr.user_id == u.id,
        join: ra in ResourceAccess,
        on: ra.user_id == enr.user_id,
        where: u.id == ^user_id and ra.section_id == ^section_id and enr.status == :enrolled,
        group_by: u.name,
        select: fragment("MAX(?)", ra.updated_at)
      )

    Repo.one(query)
  end
end