defmodule ExLaunchDark.InMemoryAdapterTest do
  use ExUnit.Case, async: false

  alias ExLaunchDark.InMemoryAdapter

  setup do
    # The keeper is started by the application; just ensure a clean table between tests.
    on_exit(fn -> InMemoryAdapter.clear_flags() end)
    :ok
  end

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

    test "clear_flags/0 clears all overrides" do
      InMemoryAdapter.enable("flag-g")
      assert_feature_flag_value("flag-g", true, :test_override)
      :ok = InMemoryAdapter.clear_flags()
      assert_feature_flag_value("flag-g", false, :default)
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

    test "clear_flags/0 raises in process scope" do
      assert_raise ArgumentError, ~r/clear_flags_for/, fn ->
        InMemoryAdapter.clear_flags()
      end
    end
  end

  def assert_feature_flag_value(flag_key, expected_value, expected_source) do
    assert {:ok, ^expected_value, ^expected_source} =
             InMemoryAdapter.get_feature_flag_value("project", flag_key, %{}, false)
  end

  describe "TableKeeper ownership" do
    setup do
      Application.put_env(:ex_launch_dark, :in_memory_adapter_scope, :process)
      on_exit(fn -> Application.delete_env(:ex_launch_dark, :in_memory_adapter_scope) end)
      :ok
    end

    test "TableKeeper creates and owns the ETS table" do
      table =
        Application.get_env(
          :ex_launch_dark,
          :in_memory_adapter_table,
          :ex_launch_dark_feature_flags
        )

      keeper = Process.whereis(ExLaunchDark.InMemoryAdapter.TableKeeper)
      assert is_pid(keeper), "TableKeeper must be running"
      assert :ets.info(table, :owner) == keeper
    end

    test "ETS table ownership remains with TableKeeper after a caller exits" do
      table =
        Application.get_env(
          :ex_launch_dark,
          :in_memory_adapter_table,
          :ex_launch_dark_feature_flags
        )

      keeper = Process.whereis(ExLaunchDark.InMemoryAdapter.TableKeeper)
      parent = self()

      process_a =
        spawn(fn ->
          InMemoryAdapter.enable("flag-a")
          send(parent, :a_ready)
          receive do: (:stop -> :ok)
        end)

      assert_receive :a_ready

      process_b =
        spawn(fn ->
          InMemoryAdapter.enable("flag-b")
          initial = InMemoryAdapter.get_feature_flag_value(:proj, "flag-b", %{}, false)
          send(parent, {:b_ready, initial})

          receive do
            :check ->
              result = InMemoryAdapter.get_feature_flag_value(:proj, "flag-b", %{}, false)
              send(parent, {:b_result, result})
          end
        end)

      assert_receive {:b_ready, {:ok, true, :test_override}}

      ref = Process.monitor(process_a)
      send(process_a, :stop)
      assert_receive {:DOWN, ^ref, :process, ^process_a, :normal}

      assert :ets.info(table, :owner) == keeper,
             "TableKeeper must still own the table after process_a exits"

      send(process_b, :check)
      assert_receive {:b_result, {:ok, true, :test_override}}
    end
  end
end
