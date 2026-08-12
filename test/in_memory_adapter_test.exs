defmodule ExLaunchDark.InMemoryAdapterTest do
  use ExUnit.Case, async: false

  alias ExLaunchDark.InMemoryAdapter

  test "returns default when no override exists" do
    assert {:ok, false, :default} =
             InMemoryAdapter.get_feature_flag_value(:proj, "flag-a", %{}, false)
  end

  test "enable/1 overrides value to true" do
    :ok = InMemoryAdapter.enable("flag-a")

    assert {:ok, true, :test_override} =
             InMemoryAdapter.get_feature_flag_value(:proj, "flag-a", %{}, false)
  end

  test "disable/1 overrides value to false" do
    :ok = InMemoryAdapter.disable("flag-a")

    assert {:ok, false, :test_override} =
             InMemoryAdapter.get_feature_flag_value(:proj, "flag-a", %{}, true)
  end

  test "clear_flags/0 removes overrides" do
    :ok = InMemoryAdapter.enable("flag-a")
    :ok = InMemoryAdapter.clear_flags()

    assert {:ok, false, :default} =
             InMemoryAdapter.get_feature_flag_value(:proj, "flag-a", %{}, false)
  end

  test "accepts iodata/binary flag keys consistently" do
    :ok = InMemoryAdapter.enable(["flag", "-", "a"])

    assert {:ok, true, :test_override} =
             InMemoryAdapter.get_feature_flag_value(:proj, "flag-a", %{}, false)
  end

  describe ":global scope" do
    setup do
      Application.put_env(:ex_launch_dark, :in_memory_adapter_scope, :global)

      on_exit(fn ->
        Application.delete_env(:ex_launch_dark, :in_memory_adapter_scope)
        InMemoryAdapter.clear_flags()
      end)

      :ok
    end

    test "an override is visible across processes" do
      flag = "test_flag"

      InMemoryAdapter.enable(flag)
      assert_feature_flag_value(flag, true, :test_override)

      test_pid = self()

      spawn(fn ->
        result = InMemoryAdapter.get_feature_flag_value("project", flag, %{}, false)
        send(test_pid, {:flag_value, result})
      end)

      assert_receive {
        :flag_value,
        {:ok, true, :test_override}
      }
    end
  end

  describe ":process scope" do
    setup do
      Application.put_env(:ex_launch_dark, :in_memory_adapter_scope, :process)

      on_exit(fn -> Application.delete_env(:ex_launch_dark, :in_memory_adapter_scope) end)

      :ok
    end

    test "an override is NOT visible across processes" do
      flag = "test_flag"

      InMemoryAdapter.enable(flag)
      assert_feature_flag_value(flag, true, :test_override)

      test_pid = self()

      spawn(fn ->
        result = InMemoryAdapter.get_feature_flag_value("project", flag, %{}, false)
        send(test_pid, {:flag_value, result})
      end)

      assert_receive {
        :flag_value,
        {:ok, false, :default}
      }
    end

    test "clearing one process does not clear another process flags" do
      current_test_pid = self()
      flag = "test_flag"

      InMemoryAdapter.enable(flag)
      assert_feature_flag_value(flag, true, :test_override)

      # spawn a new process to simulate another test that enables
      # a feature flag and then clears overrides when it finishes
      pid_from_some_other_test =
        spawn(fn ->
          InMemoryAdapter.enable(flag)
          assert_feature_flag_value(flag, true, :test_override)

          send(current_test_pid, {:ready, self()})

          receive do
            :clear_overrides ->
              InMemoryAdapter.clear_flags_for(self())
              assert_feature_flag_value(flag, false, :default)
              send(current_test_pid, :cleared)
          end
        end)

      assert current_test_pid != pid_from_some_other_test

      # once the fake test process is ready, we can clear its
      # overrides and ensure that our override still exists
      assert_receive {:ready, ^pid_from_some_other_test}
      send(pid_from_some_other_test, :clear_overrides)
      assert_receive :cleared

      # our override must still exist
      assert_feature_flag_value(flag, true, :test_override)
    end
  end

  def assert_feature_flag_value(flag_key, expected_value, expected_source) do
    assert {:ok, ^expected_value, ^expected_source} =
             InMemoryAdapter.get_feature_flag_value("project", flag_key, %{}, false)
  end
end
