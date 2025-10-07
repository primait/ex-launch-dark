# ExLaunchDark

Elixir Launch Darkly integration library

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_launch_dark` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_launch_dark, "~> 0.1.0"}
  ]
end
```

## Configuration

The client requires a Launch Darkly SDK key to connect to the service. 
You can get this key from your Launch Darkly account.

Then in the host application configuration file, typically `config/config.exs` or `config/runtime.exs`, add:

```elixir
# List all project keys to be used
config :ex_launch_dark, :projects, [:project_key_1, :project_key_n]
# Defined shared url among all different project clients
config :ex_launch_dark, :base_uri, "https://app.launchdarkly.com"   
# For each project, add its own SDK key
config :ex_launch_dark, :project_key_1, "sdk-xxxxx-yyyyy-zzzzzzz-11111"
config :ex_launch_dark, :project_key_n, "sdk-xxxxx-yyyyy-zzzzzzz-22222"
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_launch_dark>.

