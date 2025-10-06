defmodule ExLaunchDark.Client do
  @moduledoc """
    Module to start the LaunchDarkly client
  """
  require Logger

  @type client_status :: :client_ready | :client_error

  @spec init(ExLaunchDark.LDConfig.t()) :: :client_status
  def init(ld_config) do
    ld_config
    |> validate_config()
    |> start_ld_client()
  end

  defp validate_config(%{sdk_key: nil} = _ld_config), do: raise "Config Error: sdk_key cannot be nil"
  defp validate_config(%{base_uri: nil} = _ld_config), do: raise "Config Error: base_uri cannot be nil"
  defp validate_config(ld_config), do: ld_config

  defp start_ld_client(%{sdk_key: sdk_key, base_uri: base_uri, options: _options}) do
#    ld_options = Map.merge(options, %{base_uri: "https://app.launchdarkly.com"})
    case :ldclient.start_instance(String.to_charlist(sdk_key), :default, %{base_uri: String.to_charlist(base_uri)}) do
      :ok ->
        Logger.notice("LaunchDarkly client started with SDK key: #{sdk_key}")
        :client_ready
      other ->
        Logger.error("Failed to start LaunchDarkly client with SDK key: #{sdk_key} with error: #{inspect(other)}")
        :client_error
    end
  end

  def terminate do
    :ldclient.stop_all_instances()
  end
end