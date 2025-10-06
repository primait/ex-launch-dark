defmodule ExLaunchDark.Client do
  @moduledoc """
    Module to start the LaunchDarkly client
  """
  require Logger

  @tag :default
  @poll_interval 100
  @max_attempts 50

  @type client_status :: :client_ready | :client_error

  @spec init(ExLaunchDark.LDConfig.t()) :: :client_status
  def init(ld_config) do
    case is_client_started() do
      true -> :client_ready
      false ->
        ld_config
        |> validate_config()
        |> start_ld_client()
    end
  end

  defp validate_config(%{sdk_key: nil} = _ld_config), do: raise "Config Error: sdk_key cannot be nil"
  defp validate_config(%{base_uri: nil} = _ld_config), do: raise "Config Error: base_uri cannot be nil"
  defp validate_config(ld_config), do: ld_config

  defp start_ld_client(%{sdk_key: sdk_key, base_uri: base_uri, options: _options}) do
#    ld_options = Map.merge(options, %{base_uri: "https://app.launchdarkly.com"})
    case :ldclient.start_instance(String.to_charlist(sdk_key), :default, %{base_uri: String.to_charlist(base_uri)}) do
      :ok ->
        wait_until_initialized()
        :client_ready
      other ->
        Logger.error("Failed to start LaunchDarkly client with SDK key: #{sdk_key} with error: #{inspect(other)}")
        :client_error
    end
  end

  defp is_client_started do
    case :ldclient.initialized(@tag) do
      :ok -> true
      _ -> false
    end
  end

  defp wait_until_initialized(attempt \\ 1)
  defp wait_until_initialized(attempt) when attempt > @max_attempts do
    raise "LaunchDarkly client not initialized after #{attempt - 1} attempts"
  end
  defp wait_until_initialized(attempt) do
    case is_client_started() do
      true -> :ok
      false ->
        Process.sleep(@poll_interval)
        wait_until_initialized(attempt + 1)
    end
  end

  def terminate do
    :ldclient.stop_all_instances()
  end
end