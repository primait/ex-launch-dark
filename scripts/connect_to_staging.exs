defmodule ExLaunchDark.ConnectToStaging do
  @moduledoc """
  Script to connect to LaunchDarkly staging environment and fetch a feature flag value.

  NOTE: the default `LDContextStruct` uses `kind: "user"`. You might want to modify this.

  Usage:
    mix run scripts/connect_to_staging.exs <project> <sdkkey> <flag_key>

  Where:
    <project>  - The project identifier (atom) (e.g. `:test_project`)
    <sdkkey>   - The SDK key for authentication (click the three dots next to the name of your environment and choose "SDK keys" in LaunchDarkly to find it)
    <flag_key> - The feature flag key to evaluate (e.g. "flag_foo")
  """
  alias ExLaunchDark.LDConfig
  alias ExLaunchDark.LDAdapter
  alias ExLaunchDark.Client
  alias ExLaunchDark.LDContextStruct

  require Logger

  @base_uri "https://app.launchdarkly.com"

  def do_it(project, sdkkey, flag_key) do
    client = %LDConfig{
      sdk_key: sdkkey,
      base_uri: @base_uri,
      options: %{}
    }
    ctx = %LDContextStruct{
      kind: "user",
      key: "ignore_me_local_testing",
      attributes: %{}
    }

    Client.init(client, project)

    # Wait for the client to be fully initialized
    wait_for_client_ready(project, 1000)


    result = LDAdapter.get_feature_flag_value(project, flag_key, ctx, false)

    Logger.info("WOOT Feature flag '#{flag_key}' evaluation result: #{inspect(result)}")
    Client.terminate()
  end

  # Helper function to wait for client initialization
  defp wait_for_client_ready(project_id, timeout) do
    start_time = System.monotonic_time(:millisecond)
    wait_for_client_ready_loop(project_id, start_time, timeout)
  end

  defp wait_for_client_ready_loop(project_id, start_time, timeout) do
    current_time = System.monotonic_time(:millisecond)

    if current_time - start_time > timeout do
      raise "Client failed to initialize within #{timeout}ms"
    end

    if :ldclient.initialized(project_id) do
      :ok
    else
      Process.sleep(100)
      wait_for_client_ready_loop(project_id, start_time, timeout)
    end
  end
end

defmodule Args do
  require Logger

    # Helper function to parse command line arguments
  def parse_args([project, sdkkey, flag_key]) do
    {String.to_atom(project), sdkkey, flag_key}
  end
  def parse_args(args) do
    Logger.error("Invalid number of arguments: #{Enum.count(args)}. Expected: <project> <sdkkey> <flag_key>")
    raise "Invalid arguments"
  end

end

{project, sdkkey, flag_key} = Args.parse_args(System.argv())
ExLaunchDark.ConnectToStaging.do_it(project, sdkkey, flag_key)
