defmodule ExLaunchDark.Client do
  @moduledoc """
    Module to start the LaunchDarkly client
  """
  require Logger

  @type client_status :: :client_ready | :client_error

  @spec init(ExLaunchDark.LDConfig.t(), atom()) :: :client_status
  def init(ld_config, project_id) do
    ld_config
    |> validate_config()
    |> start_ld_client(project_id)
  end

  defp validate_config(%{sdk_key: nil} = _ld_config), do: raise "Config Error: sdk_key cannot be nil"
  defp validate_config(%{base_uri: nil} = _ld_config), do: raise "Config Error: base_uri cannot be nil"
  defp validate_config(ld_config), do: ld_config

  defp start_ld_client(ld_config, project_id) do
    %{sdk_key: sdk_key, base_uri: base_uri, options: _options} = ld_config
#    ld_options = Map.merge(options, %{base_uri: "https://app.launchdarkly.com"})
    case :ldclient.start_instance(String.to_charlist(sdk_key), project_id, %{base_uri: String.to_charlist(base_uri)}) do
      :ok ->
        Logger.info("LaunchDarkly client started for project #{project_id} with SDK key: #{sdk_key}")
        :client_ready
      other ->
        Logger.error("Failed to start LaunchDarkly client for project #{project_id} with SDK key: #{sdk_key} with error: #{inspect(other)}")
        :client_error
    end
  end

  def terminate, do: :ldclient.stop_all_instances()
  def terminate(project_id) do
    :ldclient.stop_instance(project_id)
  end

end