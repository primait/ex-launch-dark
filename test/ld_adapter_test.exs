defmodule ExLaunchDark.LDAdapterTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias ExLaunchDark.LDAdapter, as: Sut
  alias ExLaunchDark.LDContextStruct

  describe "fetch_feature_flag_value" do
    test "OK response" do
      :meck.new(:ldclient, [:no_link])

      :meck.expect(:ldclient, :variation_detail, fn flag_key, ld_context, _default, project_id ->
        assert flag_key == "flag_foo"
        assert project_id == :test_project
        assert :ldclient_context.get_kinds(ld_context) == ["user"]

        {1, "on", {:match_rule, :a, :b}}
      end)

      ctx = %LDContextStruct{key: "my_ctx", kind: "user", attributes: %{}}

      capture_log(fn ->
        {result, value, reason} =
          Sut.get_feature_flag_value(:test_project, "flag_foo", ctx, false)

        assert result == :ok
        assert value == "on"
        assert reason == :match_rule
      end)

      :meck.unload(:ldclient)
    end

    test "OK response" do
      :meck.new(:ldclient, [:no_link])

      :meck.expect(:ldclient, :variation_detail, fn flag_key, ld_context, _default, project_id ->
        assert flag_key == "flag_foo"
        assert project_id == :test_project
        assert :ldclient_context.get_kinds(ld_context) == ["user"]

        {1, "on", {:match_rule, :a, :b}}
      end)

      ctx = %LDContextStruct{key: "my_ctx", kind: "user", attributes: %{}}

      capture_log(fn ->
        {result, value, reason} =
          Sut.get_feature_flag_value(:test_project, "flag_foo", ctx, false)

        assert result == :ok
        assert value == "on"
        assert reason == :match_rule
      end)

      :meck.unload(:ldclient)
    end

    test "Error response" do
      :meck.new(:ldclient, [:no_link])

      :meck.expect(:ldclient, :variation_detail, fn flag_key, ld_context, _default, project_id ->
        assert flag_key == "flag_foo"
        assert project_id == :test_project
        assert :ldclient_context.get_kinds(ld_context) == ["user"]

        {:null, nil, {:error, :reason_name}}
      end)

      ctx = %LDContextStruct{key: "my_ctx", kind: "user", attributes: %{}}

      capture_log(fn ->
        {result, _value, reason} =
          Sut.get_feature_flag_value(:test_project, "flag_foo", ctx, false)

        assert result == :error
        assert reason == :reason_name
      end)

      :meck.unload(:ldclient)
    end
  end

  describe "normalise/1" do
    for {actual, expected} <- [
          {"FLAG_Foo", "flag-foo"},
          {"flag-bar", "flag-bar"},
          {"Flag_Baz", "flag-baz"},
          {"UPPER_CASE", "upper-case"},
          {"mixed-Case_Flag", "mixed-case-flag"},
          {"alreadynormalized", "alreadynormalized"}
        ] do
      test "flag is normalised: #{actual} -> #{expected}" do
        assert unquote(expected) == Sut.normalise(unquote(actual))
      end
    end
  end
end
