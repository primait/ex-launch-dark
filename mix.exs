defmodule ExLaunchDark.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_launch_dark,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExLaunchDark.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ldclient, "~> 3.0", hex: :launchdarkly_server_sdk}
    ]
  end
end
