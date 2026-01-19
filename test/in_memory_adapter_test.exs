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
end
