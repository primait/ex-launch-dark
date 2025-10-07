defmodule ExLaunchDark.LDAdapterTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias ExLaunchDark.LDAdapter
  alias ExLaunchDark.LDContextStruct

  describe "fetch_feature_flag_value" do
    test "OK response" do
      :meck.new(:ldclient, [:no_link])
      :meck.expect(:ldclient, :variation_detail, fn flag_key, _, _, project_id ->
        assert flag_key == "flag_foo"
        assert project_id == :test_project
        {1, "on", {:match_rule, :a, :b}}
      end)

      ctx = %LDContextStruct{key: "my_ctx", kind: "user", attributes: %{}}

      capture_log(fn ->
        {result, value, reason} = LDAdapter.get_feature_flag_value(:test_project, "flag_foo", ctx, false)
        assert result == :ok
        assert value == "on"
        assert reason == :match_rule
      end)

      :meck.unload(:ldclient)
    end

#    test "Error response" do
#      :meck.new(:ldclient, [:no_link])
#      :meck.expect(:ldclient, :variation_detail, fn flag_key, _, _, project_id ->
#        assert flag_key == "flag_foo"
#        assert project_id == :test_project
#        {:null, nil, {:error, :reason_name}}
#      end)
#
#      ctx = %LDContextStruct{key: "my_ctx", kind: "user", attributes: %{}}
#
#      capture_log(fn ->
#        assert LDAdapter.get_feature_flag_value(:test_project, "flag_foo", ctx, false) ==
#                 {:error, :reason_name}
#      end)
#
#      :meck.unload(:ldclient)
#    end

#    test "returns {:error, default, reason} for error tuple" do
#      :meck.expect(:ldclient, :variation_detail, fn _, _, _, _ ->
#        {nil, false, {:error, :network}}
#      end)
#
#      ctx = %LDContextStruct{key: "user", kind: "user", attributes: %{}}
#
#      assert LDAdapter.get_feature_flag_value(:proj, "flag", ctx, false) ==
#               {:error, false, :network}
#    end
#
#    test "returns {:null, default, reason} for unexpected tuple" do
#      :meck.expect(:ldclient, :variation_detail, fn _, _, _, _ -> {nil, false, :unknown} end)
#      ctx = %LDContextStruct{key: "user", kind: "user", attributes: %{}}
#
#      assert LDAdapter.get_feature_flag_value(:proj, "flag", ctx, false) ==
#               {:null, false, :unknown}
#    end
  end
end
