defmodule Oli.Lti.EctoProvider do
  import Ecto.Query, warn: false

  alias Lti_1p3.DataProvider
  alias Lti_1p3.PlatformDataProvider
  alias Lti_1p3.ToolDataProvider
  alias Lti_1p3.DataProviderError
  alias Lti_1p3.Jwk
  alias Lti_1p3.Nonce
  alias Lti_1p3.Tool.Registration
  alias Lti_1p3.Tool.Deployment
  alias Lti_1p3.Tool.LtiParams
  alias Lti_1p3.Platform.PlatformInstance
  alias Lti_1p3.Platform.LoginHint

  ## DataProviders ##
  @behaviour DataProvider

  @impl DataProvider
  def create_jwk(%Jwk{} = jwk) do
    attrs = marshal_from(jwk)

    struct(schema(:jwk))
    |> schema(:jwk).changeset(attrs)
    |> repo!().insert()
    |> unmarshal_to(Jwk)
  end

  @impl DataProvider
  def get_active_jwk() do
    case repo!().all(
           from k in schema(:jwk), where: k.active == true, order_by: [desc: k.id], limit: 1
         ) do
      [head | _] -> {:ok, unmarshal_to(head, Jwk)}
      _ -> {:error, %Lti_1p3.DataProviderError{msg: "No active Jwk found", reason: :not_found}}
    end
  end

  @impl DataProvider
  def get_all_jwks() do
    repo!().all(from(k in schema(:jwk)))
    |> Enum.map(fn jwk -> unmarshal_to(jwk, Jwk) end)
  end

  @impl DataProvider
  def get_nonce(value, domain \\ nil) do
    case domain do
      nil ->
        repo!().get_by(schema(:nonce), value: value)

      domain ->
        repo!().get_by(schema(:nonce), value: value, domain: domain)
    end
    |> unmarshal_to(Nonce)
  end

  @impl DataProvider
  def create_nonce(%Nonce{} = nonce) do
    attrs = marshal_from(nonce)

    struct(schema(:nonce))
    |> schema(:nonce).changeset(attrs)
    |> repo!().insert()
    |> case do
      {:error, %Ecto.Changeset{errors: [value: {_msg, [{:constraint, :unique} | _]}]} = changeset} ->
        {:error,
         %Lti_1p3.DataProviderError{
           msg: maybe_changeset_error_to_str(changeset),
           reason: :unique_constraint_violation
         }}

      nonce ->
        unmarshal_to(nonce, Nonce)
    end
  end

  # 86400 seconds = 24 hours
  @impl DataProvider
  def delete_expired_nonces(nonce_ttl_sec \\ 86_400) do
    nonce_expiry = Timex.now() |> Timex.subtract(Timex.Duration.from_seconds(nonce_ttl_sec))
    repo!().delete_all(from(n in schema(:nonce), where: n.inserted_at < ^nonce_expiry))
  end

  ## ToolDataProviders ##
  @behaviour ToolDataProvider

  @impl ToolDataProvider
  def create_registration(%Registration{} = registration) do
    attrs = marshal_from(registration)

    struct(schema(:registration))
    |> schema(:registration).changeset(attrs)
    |> repo!().insert()
    |> unmarshal_to(Registration)
  end

  @impl ToolDataProvider
  def create_deployment(%Deployment{} = deployment) do
    attrs = marshal_from(deployment)

    struct(schema(:deployment))
    |> schema(:deployment).changeset(attrs)
    |> repo!().insert()
    |> unmarshal_to(Deployment)
  end

  @impl ToolDataProvider
  def get_registration_deployment(issuer, client_id, deployment_id) do
    case repo!().one(
           from d in schema(:deployment),
             join: r in ^schema(:registration),
             on: d.registration_id == r.id,
             where:
               r.issuer == ^issuer and r.client_id == ^client_id and
                 d.deployment_id == ^deployment_id,
             select: {r, d}
         ) do
      nil ->
        nil

      {r, d} ->
        {unmarshal_to(r, Registration), unmarshal_to(d, Deployment)}
    end
  end

  @impl ToolDataProvider
  def get_jwk_by_registration(%Registration{tool_jwk_id: tool_jwk_id}) do
    repo!().one(
      from jwk in schema(:jwk),
        where: jwk.id == ^tool_jwk_id
    )
    |> unmarshal_to(Jwk)
  end

  @impl ToolDataProvider
  def get_registration_by_issuer_client_id(issuer, client_id) do
    repo!().one(
      from registration in schema(:registration),
        where: registration.issuer == ^issuer and registration.client_id == ^client_id,
        select: registration
    )
    |> unmarshal_to(Registration)
  end

  @impl ToolDataProvider
  def get_deployment(%Registration{id: registration_id}, deployment_id) do
    repo!().one(
      from r in schema(:deployment),
        # where: r.registration_id == ^registration_id and r.deployment_id == ^deployment_id,
        # preload: [:registration])
        where: r.registration_id == ^registration_id and r.deployment_id == ^deployment_id
    )
    |> unmarshal_to(Deployment)
  end

  @impl ToolDataProvider
  def get_lti_params_by_key(key),
    do:
      repo!().get_by(schema(:lti_params), key: key)
      |> unmarshal_to(LtiParams)

  @impl ToolDataProvider
  def create_or_update_lti_params(%LtiParams{key: key} = lti_params) do
    attrs = marshal_from(lti_params)

    case repo!().get_by(schema(:lti_params), key: key) do
      nil ->
        struct(schema(:lti_params))
        |> schema(:lti_params).changeset(attrs)

      fetched_params ->
        fetched_params
        |> schema(:lti_params).changeset(attrs)
    end
    |> repo!().insert_or_update()
    |> unmarshal_to(LtiParams)
  end

  ## PlatformDataProviders ##
  @behaviour PlatformDataProvider

  @impl PlatformDataProvider
  def create_platform_instance(%PlatformInstance{} = platform_instance) do
    attrs = marshal_from(platform_instance)

    struct(schema(:platform_instance))
    |> schema(:platform_instance).changeset(attrs)
    |> repo!().insert()
    |> unmarshal_to(PlatformInstance)
  end

  @impl PlatformDataProvider
  def get_platform_instance_by_client_id(client_id),
    do:
      repo!().get_by(schema(:platform_instance), client_id: client_id)
      |> unmarshal_to(PlatformInstance)

  @impl PlatformDataProvider
  def get_login_hint_by_value(value),
    do:
      repo!().get_by(schema(:login_hint), value: value)
      |> unmarshal_to(LoginHint)

  @impl PlatformDataProvider
  def create_login_hint(%LoginHint{} = login_hint) do
    attrs = marshal_from(login_hint)

    struct(schema(:login_hint))
    |> schema(:login_hint).changeset(attrs)
    |> repo!().insert()
    |> unmarshal_to(LoginHint)
  end

  @impl PlatformDataProvider
  def delete_expired_login_hints(login_hint_ttl_sec \\ 86_400) do
    login_hint_expiry =
      Timex.now() |> Timex.subtract(Timex.Duration.from_seconds(login_hint_ttl_sec))

    repo!().delete_all(from(h in schema(:login_hint), where: h.inserted_at < ^login_hint_expiry))
  end

  defp marshal_from(data) do
    Map.from_struct(data)
  end

  defp unmarshal_to({:ok, data}, struct_type) do
    map = Map.from_struct(data)
    {:ok, struct(struct_type, map)}
  end

  defp unmarshal_to({:error, maybe_changeset}, _struct_type) do
    {:error, %DataProviderError{msg: maybe_changeset_error_to_str(maybe_changeset)}}
  end

  defp unmarshal_to(nil, _struct_type) do
    nil
  end

  defp unmarshal_to(data, struct_type) do
    map = Map.from_struct(data)
    struct(struct_type, map)
  end

  defp maybe_changeset_error_to_str(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", _to_string(value))
      end)
    end)
    |> Enum.reduce("", fn {k, v}, acc ->
      joined_errors = Enum.join(v, "; ")
      "#{acc} #{k}: #{joined_errors}"
    end)
    |> String.trim()
  end

  defp maybe_changeset_error_to_str(no_changeset), do: no_changeset

  defp _to_string(val) when is_list(val) do
    Enum.join(val, ",")
  end

  defp _to_string(val), do: to_string(val)
end
