# Migration Guide: Using the Unified Interface

This guide helps you migrate from direct adapter usage to the new unified `ExLaunchDark.FeatureFlags` interface.

## Why Migrate?

The unified interface provides:
- **Single API**: One module to import instead of choosing between adapters
- **Configuration-based switching**: Change adapters without code changes
- **Easier testing**: Switch to in-memory adapter for tests via configuration
- **Future-proof**: New adapters will automatically work with your code

## Migration Steps

### Step 1: Update Configuration

Add the adapter configuration to your config files:

```elixir
# config/prod.exs
config :ex_launch_dark, :adapter, ExLaunchDark.LDAdapter

# config/test.exs
config :ex_launch_dark, :adapter, ExLaunchDark.InMemoryAdapter

# config/dev.exs (optional - use in-memory for local dev)
config :ex_launch_dark, :adapter, ExLaunchDark.InMemoryAdapter
```

### Step 2: Update Your Code

#### Before (Direct Adapter Usage)

```elixir
# Old way - directly calling the adapter
defmodule MyApp.Features do
  alias ExLaunchDark.LDAdapter
  alias ExLaunchDark.LDContextStruct

  def check_feature(user_id, feature_key) do
    context = %LDContextStruct{key: user_id, kind: "user"}
    
    case LDAdapter.get_feature_flag_value(:my_project, feature_key, context, false) do
      {:ok, value, _reason} -> value
      _ -> false
    end
  end
end
```

#### After (Unified Interface)

```elixir
# New way - using the unified interface
defmodule MyApp.Features do
  alias ExLaunchDark.FeatureFlags
  alias ExLaunchDark.LDContextStruct

  def check_feature(user_id, feature_key) do
    context = %LDContextStruct{key: user_id, kind: "user"}
    
    case FeatureFlags.get_flag(:my_project, feature_key, context, false) do
      {:ok, value, _reason} -> value
      _ -> false
    end
  end
end
```

### Step 3: Update Tests

#### Before

```elixir
defmodule MyApp.FeaturesTest do
  use ExUnit.Case
  alias ExLaunchDark.InMemoryAdapter
  alias MyApp.Features

  # Had to manually decide to use InMemoryAdapter in tests
  setup do
    InMemoryAdapter.clear_flags()
    :ok
  end

  test "feature check" do
    InMemoryAdapter.enable("my-feature")
    assert Features.check_feature("user-123", "my-feature")
  end
end
```

#### After

```elixir
defmodule MyApp.FeaturesTest do
  use ExUnit.Case
  alias ExLaunchDark.InMemoryAdapter
  alias MyApp.Features

  # Same test code, but adapter is configured in config/test.exs
  setup do
    InMemoryAdapter.clear_flags()
    :ok
  end

  test "feature check" do
    InMemoryAdapter.enable("my-feature")
    assert Features.check_feature("user-123", "my-feature")
  end
end
```

## API Mapping

| Old (Direct Adapter) | New (Unified Interface) |
|---------------------|------------------------|
| `LDAdapter.get_feature_flag_value/4` | `FeatureFlags.get_flag/4` |
| `LDAdapter.track_event/4` | `FeatureFlags.track_event/4` |
| `LDAdapter.get_all_flags/2` | `FeatureFlags.get_all_flags/2` |
| `InMemoryAdapter.get_feature_flag_value/4` | `FeatureFlags.get_flag/4` (with InMemoryAdapter configured) |

## Advanced: Conditional Logic Based on Adapter

If you need different behavior based on the adapter:

```elixir
# Check which adapter is being used
if ExLaunchDark.FeatureFlags.using_in_memory_adapter?() do
  # Test/dev-specific logic
else
  # Production logic
end

# Or check for LaunchDarkly
if ExLaunchDark.FeatureFlags.using_ld_adapter?() do
  # LaunchDarkly-specific features
  ExLaunchDark.FeatureFlags.track_event(:project, "event", context)
end
```

## Backward Compatibility

The old adapter modules are still available and fully functional. You can migrate gradually:

1. Update configuration to specify the adapter
2. Migrate modules one at a time
3. Keep using direct adapter calls where needed

## Benefits Summary

- **Before**: Your code was coupled to a specific adapter implementation
- **After**: Your code depends on the interface; adapter is a configuration detail
- **Testing**: No code changes needed to switch between real and mock implementations
- **Maintenance**: Add new adapters without touching application code

## Questions?

If you have questions about the migration, please check:
- `CONFIG_EXAMPLES.md` for configuration examples
- `ExLaunchDark.FeatureFlags` module documentation
- `README.md` for usage examples
