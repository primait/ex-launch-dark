defmodule ExLaunchDark.FeatureFlagsTest do
  use ExUnit.Case, async: false

  alias ExLaunchDark.FeatureFlags
  alias ExLaunchDark.InMemoryAdapter
  alias ExLaunchDark.LDContextStruct

  setup do
    # Save original adapter config
    original_adapter = Application.get_env(:ex_launch_dark, :adapter)

    # Clean up in-memory flags before each test
    InMemoryAdapter.clear_flags()

    on_exit(fn ->
      # Restore original adapter config
      if original_adapter do
        Application.put_env(:ex_launch_dark, :adapter, original_adapter)
      else
        Application.delete_env(:ex_launch_dark, :adapter)
      end

      InMemoryAdapter.clear_flags()
    end)

    {:ok, original_adapter: original_adapter}
  end

  describe "get_flag/4 with InMemoryAdapter" do
    setup do
      Application.put_env(:ex_launch_dark, :adapter, InMemoryAdapter)
      :ok
    end

    test "returns default value when flag is not set" do
      context = %LDContextStruct{key: "user-123", kind: "user"}

      assert {:ok, false, :default} =
               FeatureFlags.get_flag(:test_project, "unknown-flag", context, false)
    end

    test "returns flag value when flag is enabled" do
      InMemoryAdapter.enable("test-flag")
      context = %LDContextStruct{key: "user-123", kind: "user"}

      assert {:ok, true, :test_override} =
               FeatureFlags.get_flag(:test_project, "test-flag", context, false)
    end

    test "returns flag value when flag is disabled" do
      InMemoryAdapter.disable("test-flag")
      context = %LDContextStruct{key: "user-123", kind: "user"}

      assert {:ok, false, :test_override} =
               FeatureFlags.get_flag(:test_project, "test-flag", context, true)
    end

    test "handles various key formats" do
      InMemoryAdapter.enable("my_feature_flag")
      context = %LDContextStruct{key: "user-123", kind: "user"}

      # String key
      assert {:ok, true, :test_override} =
               FeatureFlags.get_flag(:test_project, "my_feature_flag", context, false)

      # Binary key
      assert {:ok, true, :test_override} =
               FeatureFlags.get_flag(:test_project, <<"my_feature_flag">>, context, false)
    end
  end

  describe "adapter detection" do
    test "get_adapter/0 returns configured adapter" do
      Application.put_env(:ex_launch_dark, :adapter, InMemoryAdapter)
      assert FeatureFlags.get_adapter() == InMemoryAdapter

      Application.put_env(:ex_launch_dark, :adapter, ExLaunchDark.LDAdapter)
      assert FeatureFlags.get_adapter() == ExLaunchDark.LDAdapter
    end

    test "get_adapter/0 defaults to LDAdapter when not configured" do
      Application.delete_env(:ex_launch_dark, :adapter)
      assert FeatureFlags.get_adapter() == ExLaunchDark.LDAdapter
    end

    test "using_in_memory_adapter?/0 returns correct value" do
      Application.put_env(:ex_launch_dark, :adapter, InMemoryAdapter)
      assert FeatureFlags.using_in_memory_adapter?() == true

      Application.put_env(:ex_launch_dark, :adapter, ExLaunchDark.LDAdapter)
      assert FeatureFlags.using_in_memory_adapter?() == false
    end

    test "using_ld_adapter?/0 returns correct value" do
      Application.put_env(:ex_launch_dark, :adapter, ExLaunchDark.LDAdapter)
      assert FeatureFlags.using_ld_adapter?() == true

      Application.put_env(:ex_launch_dark, :adapter, InMemoryAdapter)
      assert FeatureFlags.using_ld_adapter?() == false
    end
  end

  describe "LaunchDarkly-specific functions with InMemoryAdapter" do
    setup do
      Application.put_env(:ex_launch_dark, :adapter, InMemoryAdapter)
      :ok
    end

    test "track_event/4 raises error" do
      context = %LDContextStruct{key: "user-123", kind: "user"}

      assert_raise RuntimeError, "track_event is not supported by InMemoryAdapter", fn ->
        FeatureFlags.track_event(:test_project, "test-event", context)
      end
    end

    test "get_all_flags/2 raises error" do
      context = %LDContextStruct{key: "user-123", kind: "user"}

      assert_raise RuntimeError, "get_all_flags is not supported by InMemoryAdapter", fn ->
        FeatureFlags.get_all_flags(:test_project, context)
      end
    end
  end
end
