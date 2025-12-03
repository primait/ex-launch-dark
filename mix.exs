defmodule ExLaunchDark.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_launch_dark,
      version: "1.0.1",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def package do
    [
      description:
        "ExLaunchDark is an integration library to perform common LaunchDarkly operations.",
      name: "ex_launch_dark",
      maintainer: ["prima.it"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/primait/ex-launch-dark"}
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
      {:ldclient, "~> 3.0", hex: :launchdarkly_server_sdk},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:meck, "~> 0.9.2", only: :test},
      {:mix_bump, "~> 0.1.0", only: [:dev, :staging]}
    ]
  end
end
