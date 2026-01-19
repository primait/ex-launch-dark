defmodule ExLaunchDark.Application do
  @moduledoc """
  ExLaunchDark - Elixir integration for LaunchDarkly feature flags.

  ## Quick Start

  Use the unified `ExLaunchDark.FeatureFlags` interface to interact with feature flags:

      alias ExLaunchDark.FeatureFlags
      alias ExLaunchDark.LDContextStruct

      context = %LDContextStruct{key: "user-123", kind: "user"}
      {:ok, value, _reason} = FeatureFlags.get_flag(:my_project, "feature-key", context, false)

  ## Configuration

  Configure the adapter in your config files:

      # Production: LaunchDarkly
      config :ex_launch_dark, :adapter, ExLaunchDark.LDAdapter

      # Test/Dev: In-Memory
      config :ex_launch_dark, :adapter, ExLaunchDark.InMemoryAdapter

  See `ExLaunchDark.FeatureFlags` for the main API documentation.
  """

  use Application
  require Logger

  def start(_type, _args) do
    Logger.debug("Starting ExLaunchDark application...")

    all_config = build_projects_config()

    # Start clients sequentially to avoid race inside ldclient
    Enum.each(all_config, fn {project, cfg} ->
      case ExLaunchDark.Client.init(cfg, project) do
        :client_ready -> :ok
        :client_error -> :error
      end
    end)

    Supervisor.start_link([], strategy: :one_for_one, name: ExLaunchDark.Supervisor)
  end

  defp build_projects_config do
    projects =
      Application.get_env(:ex_launch_dark, :projects, [])

    base_uri =
      Application.get_env(:ex_launch_dark, :base_uri, "https://app.launchdarkly.com")

    Enum.map(projects, fn project ->
      sdk_key =
        Application.fetch_env!(:ex_launch_dark, project) ||
          raise "Missing SDK key config for project #{inspect(project)}"

      {project,
       %ExLaunchDark.LDConfig{
         sdk_key: sdk_key,
         base_uri: base_uri,
         options: %{}
       }}
    end)
  end
end
