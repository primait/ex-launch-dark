defmodule ExLaunchDark.Application do
  @moduledoc """
  Public API + application start for ExLaunchDark.
  """

  use Application
  require Logger

  def start(_type, _args) do
    Logger.debug("Starting ExLaunchDark application...")

    ld_config = Application.fetch_env!(:ex_launch_dark, :ld_config)

    children = [
      {Task, fn ->
        case ExLaunchDark.Client.init(ld_config) do
          :client_ready -> :ok
          :client_error -> Logger.error("LaunchDarkly client failed to initialize")
        end
      end}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ExLaunchDark.Supervisor)
  end

  # Example public API
  def hello, do: :world
end
