defmodule Oli.Lti.Deployment do
  use Ecto.Schema
  import Ecto.Changeset
  import Oli.Lti.Config

  schema "lti_1p3_deployments" do
    field :deployment_id, :string

    belongs_to :registration, schema(:registration)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(deployment, attrs \\ %{}) do
    deployment
    |> cast(attrs, [:deployment_id, :registration_id])
    |> validate_required([:deployment_id, :registration_id])
  end
end
