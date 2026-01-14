defmodule ExLaunchDark.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_launch_dark,
      version: "1.2.1",
      elixir: "~> 1.18",
      package: package(),
      start_permanent: Mix.env() == :prod,
      docs: docs(),
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
      {:mix_bump, "~> 0.1.0", only: [:dev, :staging]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md": [title: "Overview"],
        "LICENSE.md": [title: "License"]
      ],
      main: "readme",
      source_url: "https://github.com/primait/ex-launch-dark"
    ]
  end
end
