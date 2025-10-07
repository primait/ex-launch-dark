defmodule ExLaunchDark.LDContextBuilderTest do
  use ExUnit.Case
  alias ExLaunchDark.LDContextBuilder
  alias ExLaunchDark.LDContextStruct

  describe "build_context/1" do
    test "builds context with key, kind, and empty attributes" do
      ctx = %LDContextStruct{key: "my_ctx", kind: "user"}
      ld_ctx = LDContextBuilder.build_context(ctx)
      assert :ldclient_context.get_key("user", ld_ctx) == "my_ctx"
      assert :ldclient_context.get_kinds(ld_ctx) == ["user"]
    end

    test "builds context with attributes" do
      attrs = %{foo: "bar", baz: true}
      ctx = %LDContextStruct{key: "my_ctx", kind: "user", attributes: attrs}
      ld_ctx = LDContextBuilder.build_context(ctx)
      assert :ldclient_context.get("user", "foo", ld_ctx) == "bar"
      assert :ldclient_context.get("user", "baz", ld_ctx) == true
    end

    test "raises error when key is nil" do
      ctx = %LDContextStruct{key: nil, kind: "user", attributes: %{}}

      assert_raise RuntimeError, fn ->
        LDContextBuilder.build_context(ctx)
      end
    end

    test "raises error when kind is nil" do
      ctx = %LDContextStruct{key: "my_ctx", kind: nil, attributes: %{}}

      assert_raise RuntimeError, fn ->
        LDContextBuilder.build_context(ctx)
      end
    end
  end
end
