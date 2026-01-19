# Example Configuration for ExLaunchDark

This document provides example configurations for different environments.

## Production Configuration

```elixir
# config/prod.exs
import Config

# Use the LaunchDarkly adapter for production
config :ex_launch_dark, :adapter, ExLaunchDark.LDAdapter

# Configure LaunchDarkly projects
config :ex_launch_dark, :projects, [:my_app, :my_service]
config :ex_launch_dark, :base_uri, "https://app.launchdarkly.com"

# SDK keys (typically loaded from environment variables)
config :ex_launch_dark, :my_app, System.get_env("LAUNCHDARKLY_SDK_KEY_APP")
config :ex_launch_dark, :my_service, System.get_env("LAUNCHDARKLY_SDK_KEY_SERVICE")
```

## Test Configuration

```elixir
# config/test.exs
import Config

# Use the in-memory adapter for testing
config :ex_launch_dark, :adapter, ExLaunchDark.InMemoryAdapter

# You can optionally specify a custom ETS table name
config :ex_launch_dark, :in_memory_adapter_table, :test_feature_flags
```

## Development Configuration

```elixir
# config/dev.exs
import Config

# Option 1: Use in-memory adapter for local development
config :ex_launch_dark, :adapter, ExLaunchDark.InMemoryAdapter

# Option 2: Use LaunchDarkly with a development SDK key
# config :ex_launch_dark, :adapter, ExLaunchDark.LDAdapter
# config :ex_launch_dark, :projects, [:dev_project]
# config :ex_launch_dark, :base_uri, "https://app.launchdarkly.com"
# config :ex_launch_dark, :dev_project, "sdk-xxxxx-yyyyy-zzzzzzz"
```

## Runtime Configuration

For dynamic configuration based on environment variables:

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  # Determine adapter based on environment variable
  adapter =
    case System.get_env("FEATURE_FLAGS_ADAPTER") do
      "in_memory" -> ExLaunchDark.InMemoryAdapter
      _ -> ExLaunchDark.LDAdapter
    end

  config :ex_launch_dark, :adapter, adapter

  # Configure projects if using LaunchDarkly adapter
  if adapter == ExLaunchDark.LDAdapter do
    config :ex_launch_dark, :projects, [:my_app]
    config :ex_launch_dark, :base_uri, System.get_env("LAUNCHDARKLY_BASE_URI", "https://app.launchdarkly.com")
    config :ex_launch_dark, :my_app, System.fetch_env!("LAUNCHDARKLY_SDK_KEY")
  end
end
```

## Usage Examples

### Basic Usage

```elixir
# In your application code
defmodule MyApp.FeatureService do
  alias ExLaunchDark.FeatureFlags
  alias ExLaunchDark.LDContextStruct

  def feature_enabled?(user_id, feature_key) do
    context = %LDContextStruct{
      key: user_id,
      kind: "user"
    }

    case FeatureFlags.get_flag(:my_app, feature_key, context, false) do
      {:ok, true, _reason} -> true
      _ -> false
    end
  end
end
```

### Testing with In-Memory Adapter

```elixir
# In your test file
defmodule MyApp.FeatureServiceTest do
  use ExUnit.Case
  alias ExLaunchDark.InMemoryAdapter
  alias MyApp.FeatureService

  setup do
    # Clear flags before each test
    InMemoryAdapter.clear_flags()
    :ok
  end

  test "feature is enabled when flag is set" do
    # Set up test data
    InMemoryAdapter.enable("new-feature")

    # Test your code
    assert FeatureService.feature_enabled?("user-123", "new-feature")
  end

  test "feature is disabled by default" do
    refute FeatureService.feature_enabled?("user-123", "unknown-feature")
  end
end
```

### Multi-Context Evaluation

```elixir
defmodule MyApp.AdvancedFeatureService do
  alias ExLaunchDark.FeatureFlags
  alias ExLaunchDark.LDContextStruct
  alias ExLaunchDark.LDMultiContextStruct

  def check_feature_for_user_and_org(user_id, org_id, feature_key) do
    user_ctx = %LDContextStruct{
      key: user_id,
      kind: "user",
      attributes: %{}
    }

    org_ctx = %LDContextStruct{
      key: org_id,
      kind: "organization",
      attributes: %{}
    }

    multi_ctx = %LDMultiContextStruct{
      contexts: [user_ctx, org_ctx]
    }

    case FeatureFlags.get_flag(:my_app, feature_key, multi_ctx, false) do
      {:ok, value, reason} -> 
        {:ok, value, reason}
      error -> 
        error
    end
  end
end
```

## Switching Adapters

The beauty of the unified interface is that you can switch between adapters without changing your application code:

```elixir
# Your application code remains the same
context = %LDContextStruct{key: "user-123", kind: "user"}
{:ok, value, _} = ExLaunchDark.FeatureFlags.get_flag(:my_app, "feature", context, false)

# Just change the configuration:
# Development/Test:
config :ex_launch_dark, :adapter, ExLaunchDark.InMemoryAdapter

# Production:
config :ex_launch_dark, :adapter, ExLaunchDark.LDAdapter
```
