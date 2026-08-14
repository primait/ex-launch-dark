defmodule ExLaunchDark.InMemoryAdapter.TableKeeperTest do
  use ExUnit.Case, async: false

  alias ExLaunchDark.InMemoryAdapter

  describe "keeper not started for configured table" do
    setup do
      # Point the adapter at a table that has no keeper — adapter must raise.
      Application.put_env(:ex_launch_dark, :in_memory_adapter_table, :no_such_keeper_table)
      on_exit(fn -> Application.delete_env(:ex_launch_dark, :in_memory_adapter_table) end)
      :ok
    end

    test "adapter raises a clear error when the table does not exist" do
      assert_raise RuntimeError, ~r/not initialized/, fn ->
        InMemoryAdapter.enable("some-flag")
      end
    end
  end

  describe "custom table name" do
    setup do
      Application.put_env(:ex_launch_dark, :in_memory_adapter_table, :custom_keeper_test_table)
      # Start a keeper without name registration so it doesn't conflict with the app-supervised keeper.
      # Use start/2 (not start_link) so the keeper outlives the test process until we stop it explicitly.
      {:ok, keeper} = GenServer.start(ExLaunchDark.InMemoryAdapter.TableKeeper, [])

      on_exit(fn ->
        Application.delete_env(:ex_launch_dark, :in_memory_adapter_table)
        GenServer.stop(keeper)
      end)

      %{keeper: keeper}
    end

    test "keeper creates and owns the table from the configured name", %{keeper: keeper} do
      assert :ets.info(:custom_keeper_test_table, :owner) == keeper
    end

    test "adapter reads and writes through the custom-named table" do
      :ok = InMemoryAdapter.enable("custom-flag")

      assert {:ok, true, :test_override} =
               InMemoryAdapter.get_feature_flag_value(:proj, "custom-flag", %{}, false)
    end
  end
end
