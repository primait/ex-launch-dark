defmodule ExLaunchDark.LDContextBuilderTest do
  use ExUnit.Case
  alias ExLaunchDark.LDContextBuilder
  alias ExLaunchDark.LDContextStruct
  alias ExLaunchDark.LDMultiContextStruct

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

  describe "build_multi_context/1" do
    test "builds multi-context with service + user kinds" do
      service =
        %LDContextStruct{
          key: service_name = "example-service",
          kind: "service",
          attributes: %{}
        }

      user =
        %LDContextStruct{
          key: email = "antonio.banderas@example.com",
          kind: "user",
          attributes: %{"country" => country = "es", "roles" => roles = ["admin", "user"]}
        }

      multi = %LDMultiContextStruct{contexts: [service, user]}

      ld_ctx = LDContextBuilder.build_context(multi)

      # It should contain both kinds
      assert Enum.sort(:ldclient_context.get_kinds(ld_ctx)) == ["service", "user"]

      # Keys must be retrievable per kind
      assert :ldclient_context.get_key("service", ld_ctx) == service_name
      assert :ldclient_context.get_key("user", ld_ctx) == email

      # Attributes must be retrievable under the right kind
      assert :ldclient_context.get("user", "country", ld_ctx) == country
      assert :ldclient_context.get("user", "roles", ld_ctx) == roles
    end

    test "raises error when multi-context has duplicate kinds" do
      c1 = %LDContextStruct{key: "a", kind: "user", attributes: %{}}
      c2 = %LDContextStruct{key: "b", kind: "user", attributes: %{}}

      multi = %LDMultiContextStruct{contexts: [c1, c2]}

      assert_raise RuntimeError, fn ->
        LDContextBuilder.build_context(multi)
      end
    end

    test "raises error when multi-context is empty" do
      multi = %LDMultiContextStruct{contexts: []}

      assert_raise RuntimeError, fn ->
        LDContextBuilder.build_context(multi)
      end
    end
  end
end
