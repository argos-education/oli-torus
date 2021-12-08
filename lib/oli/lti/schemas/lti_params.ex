defmodule Oli.Lti.LtiParams do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lti_1p3_params" do
    field :key, :string
    field :params, :map
    field :exp, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(nonce, attrs) do
    nonce
    |> cast(attrs, [:key, :params, :exp])
    |> validate_required([:key, :params, :exp])
    |> unique_constraint(:key)
  end
end
