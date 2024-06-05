defmodule Oli.Activities.Reports.Providers.OliLikert do
  @behaviour Oli.Activities.Reports.Renderer

  alias Oli.Delivery.Attempts.Core

  @impl Oli.Activities.Reports.Renderer
  def render(
        %Oli.Rendering.Context{enrollment: enrollment, user: user} = context,
        %{"activityId" => activity_id} = _element
      ) do
    attempt_data = process_attempt_data(enrollment.section_id, user.id, activity_id)
    data_url = "/api/v1/activity/report/#{enrollment.section_id}/#{activity_id}"

    prompts = [~s|<div>
    <ul>|, prompts_from_items(Map.get(attempt_data, :data)), "</ul></div>"]

    {:ok, first} =
      Map.get(attempt_data, :choices)
      |> List.first()
      |> JSONPointer.get("/content/0/children/0/text")

    {:ok, last} =
      Map.get(attempt_data, :choices)
      |> List.last()
      |> JSONPointer.get("/content/0/children/0/text")

    visuals = [~s|
    <div class="flex flex-row">
      <div class="flex flex-col ml-2">
        <div>#{last}</div>
        <div class="grow"></div>
        <div class="mb-8">#{first}</div>
      </div>
      <div class="grow">|, visualization(context, data_url), ~s|</div>
    </div>|]

    {:ok, [visuals, prompts]}
  end

  @impl Oli.Activities.Reports.Renderer
  def report_data(section_id, user_id, activity_id) do
    Map.get(process_attempt_data(section_id, user_id, activity_id), :data)
  end

  defp process_attempt_data(section_id, user_id, activity_id) do
    activity_attempt =
      Core.get_latest_activity_attempt(section_id, user_id, activity_id)
      |> Oli.Repo.preload(:part_attempts)

    part_attempts_by_id =
      Enum.reduce(activity_attempt.part_attempts, %{}, fn a, c -> Map.put(c, a.part_id, a) end)

    data =
      Map.get(activity_attempt.revision.content, "items")
      |> Enum.with_index()
      |> Enum.reduce([], fn {a, idx}, c ->
        {:ok, p} = JSONPointer.get(a, "/content/0/children/0/text")
        r = Map.get(part_attempts_by_id, Map.get(a, "id"))
        {:ok, r} = JSONPointer.get(r.response, "/input")

        value = %{
          prompt_long: "P#{idx + 1}: #{p}",
          prompt: "P#{idx + 1}",
          response: r,
          color: color_matcher(Map.get(a, "group")),
          group: Map.get(a, "group"),
          index: idx
        }

        c ++ [value]
      end)

    %{choices: Map.get(activity_attempt.revision.content, "choices"), data: data}
  end

  defp prompts_from_items(data) do
    Enum.reduce(data, [], fn a, c ->
      prompt = ~s|<li style="color:#{Map.get(a, :color)}">#{Map.get(a, :prompt_long)}</li>|
      [c | prompt]
    end)
  end

  defp color_matcher(str) when is_binary(str) do
    case String.downcase(str) do
      "shallow" -> "red"
      "deep" -> "green"
      _ -> "blue"
    end
  end

  defp color_matcher(_), do: "blue"

  defp visualization(%Oli.Rendering.Context{} = context, data_url) do
    # encoded = Jason.encode!(data)

    spec =
      VegaLite.from_json("""
      {
        "width": 500,
        "height": 300,
        "description": "A simple bar chart with embedded data.",
        "data": {
            "url": "#{data_url}"
        },
        "layer": [
            {
                "mark": "bar",
                "encoding": {
                    "x": {
                        "field": "prompt",
                        "type": "ordinal",
                        "sort": {
                            "field": "index",
                            "order": "ascending"
                        },
                        "axis": {
                            "labelAngle": 0
                        },
                        "title": "Deep ---- Shallow"
                    },
                    "y": {
                        "field": "response",
                        "type": "quantitative",
                        "title": "Scale"
                    },
                    "color": {
                        "field": "color",
                        "type": "nominal",
                        "scale": null
                    }
                }
            }
        ]
      }
      """)
      |> VegaLite.to_spec()

    {:safe, attempt_selector} =
      OliWeb.Common.React.component(context, "Components.VegaLiteRenderer", %{spec: spec})

    [attempt_selector]
  end
end
