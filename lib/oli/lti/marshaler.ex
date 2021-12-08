defmodule Oli.Lti.DataProvider.Marshaler do
  @moduledoc """
  Marshaler to convert between Lti_1p3 structs and Ecto schemas
  """
  alias Lti_1p3.Jwk
  alias Lti_1p3.Nonce
  alias Lti_1p3.Tool.ContextRole
  alias Lti_1p3.Tool.PlatformRole
  alias Lti_1p3.Tool.Deployment
  alias Lti_1p3.Tool.Registration
  alias Lti_1p3.Platform.PlatformInstance
  alias Lti_1p3.Platform.LoginHint
  alias Oli.Lti

  @doc """
  Converts an Lti_1p3 struct to an EctoProvider struct.
  ## Examples
      iex> Marshaler.to(%Lti_1p3.Jwk{})
      %Oli.Lti.Jwk{}

  If a list of Lti_1p3 structs is provided, each item in the list is
  converted and returned as a list of EctoProvider structs
      iex> Marshaler.to([%Lti_1p3.Jwk{}])
      [%Oli.Lti.Jwk{}]

  If ContextRole or PlatformRole struct is provided, the ecto struct metadata will be
  set to state: :loaded as though the role was retrieved from the database.
  This guarantees any assoc updates will not result in new role records created
  but instead use the existing role records created by the seed.
  """
  def to(items) when is_list(items) do
    Enum.map(items, fn t -> EctoProvider.Marshaler.to(t) end)
  end

  def to(%Jwk{} = t) do
    struct(EctoProvider.Jwk, Map.from_struct(t))
  end

  def to(%Nonce{} = t) do
    struct(EctoProvider.Nonce, Map.from_struct(t))
  end

  def to(%ContextRole{} = t) do
    struct(EctoProvider.ContextRole, Map.from_struct(t))
    |> Ecto.put_meta(state: :loaded)
  end

  def to(%PlatformRole{} = t) do
    struct(EctoProvider.PlatformRole, Map.from_struct(t))
    |> Ecto.put_meta(state: :loaded)
  end

  def to(%Deployment{} = t) do
    struct(EctoProvider.Deployment, Map.from_struct(t))
  end

  def to(%Registration{} = t) do
    struct(EctoProvider.Registration, Map.from_struct(t))
  end

  def to(%PlatformInstance{} = t) do
    struct(EctoProvider.PlatformInstance, Map.from_struct(t))
  end

  def to(%LoginHint{} = t) do
    struct(EctoProvider.LoginHint, Map.from_struct(t))
  end

  @doc """
  Converts an EctoProvider struct to an Lti_1p3 struct.
  ## Examples
      iex> Marshaler.from(%Oli.Lti.Jwk{})
      %Lti_1p3.Jwk{}

  If a list of EctoProvider structs is provided, each item in the list is
  converted and returned as a list of Lti_1p3 structs
      iex> Marshaler.to([%Oli.Lti.Jwk{}])
      [%Lti_1p3.Jwk{}]
  """
  def from(items) when is_list(items) do
    Enum.map(items, fn t -> EctoProvider.Marshaler.from(t) end)
  end

  def from(%EctoProvider.Jwk{} = f) do
    struct(Jwk, Map.from_struct(f))
  end

  def from(%EctoProvider.Nonce{} = f) do
    struct(Nonce, Map.from_struct(f))
  end

  def from(%EctoProvider.ContextRole{} = f) do
    struct(ContextRole, Map.from_struct(f))
  end

  def from(%EctoProvider.PlatformRole{} = f) do
    struct(PlatformRole, Map.from_struct(f))
  end

  def from(%EctoProvider.Deployment{} = f) do
    struct(Deployment, Map.from_struct(f))
  end

  def from(%EctoProvider.Registration{} = f) do
    struct(Registration, Map.from_struct(f))
  end

  def from(%EctoProvider.PlatformInstance{} = f) do
    struct(PlatformInstance, Map.from_struct(f))
  end

  def from(%EctoProvider.LoginHint{} = f) do
    struct(LoginHint, Map.from_struct(f))
  end
end
