# ExLaunchDark

Elixir Launch Darkly integration library

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_launch_dark` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_launch_dark, "~> 0.1.0"},
    # or using git source
    {:ex_launch_dark, git: "url_to_repo", tag: "1.1.0"}
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

## Usage
To start using the library main functions you can start playing with the `ExLaunchDark.LDAdapter` module.
Which exposes some of the most common flag operations, like:

```elixir
# Retrieve the current value of any given feature flag 
ld_ctx = %ExLaunchDark.LDContextStruct{key: "ctx_key_123", kind: "user"}
case ExLaunchDark.LDAdapter.get_feature_flag_value(:project_key_1, "flag_foo", ld_ctx, false) do
  {:ok, value, _reason} -> 
    # All good, use the value
  {:error, _default, reason} -> 
    # Something went wrong, handle the error using given reason
end

NOTE: elixir generally prefers underscores rather than hypens (e.g. "flag_foo" rather than "flag-foo") but Launchdarkly idioms prefer hyphens. `ExLaunchDark.LDAdapter.get_feature_flag_value` makes no assumptions nor enforcement
of this. If you want to use the Launchdarkly style for your `flag_key` then use `ExLaunchDark.LDAdapter.normalise` first.
```

## Development
In order run this project isolated, you need to ensure you have first installed manually the ``asdf`` 
tool manager in your host machine, then run:

```bash
asdf install
```

which will install the required Erlang and Elixir versions as specified in the `.tool-versions` file.

Then you can fetch the dependencies with:

```bash
mix deps.get
mix deps.compile
``` 

### Application commands 
In order to ease some of the common development tasks, you can use any of the "commands/tasks" 
defined in the `mise.toml` file, like:

```bash
mise start 
mise test
mise code:check 
mise code:format
```

## Release 

You can bump the version directly in the `mix.exs` file, or by using any of next commands:

```bash
mix bump patch
mix bump minor
mix bump major
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_launch_dark>.

