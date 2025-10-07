defmodule ExLaunchDark.Application do
  @moduledoc """
  Public API + application start for ExLaunchDark.
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
      Application.fetch_env(:ex_launch_dark, :projects) || []

    base_uri =
      Application.fetch_env(:ex_launch_dark, :base_uri) || "https://app.launchdarkly.com"

    {_, projects_ids} = projects
    {_, base_uri_value} = base_uri
    Enum.map(projects_ids, fn project ->
      sdk_key =
        Application.fetch_env!(:ex_launch_dark, project) ||
          raise "Missing SDK key config for project #{inspect(project)}"

      {project,
        %ExLaunchDark.LDConfig{
          sdk_key: sdk_key,
          base_uri: base_uri_value,
          options: %{}
        }}
    end)
  end

  # Example public API
  def hello, do: :world
end
