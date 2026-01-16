defmodule ExLaunchDark.AdapterTest do
  use ExUnit.Case, async: true

  alias ExLaunchDark.Adapter

  describe "normalize_key/1" do
    test "returns the same binary when input is a binary" do
      assert Adapter.normalize_key("flag-key") == "flag-key"
      assert Adapter.normalize_key(<<"flag-key">>) == "flag-key"
    end

    test "normalizes iodata (list) into a binary" do
      assert Adapter.normalize_key(["flag", "-", "key"]) == "flag-key"
      assert Adapter.normalize_key([["flag"], ?-, ["key"]]) == "flag-key"
    end

    test "normalizes charlist into a binary" do
      assert Adapter.normalize_key(~c"flag-key") == "flag-key"
    end

    test "normalizes atoms into a binary via to_string/1" do
      assert Adapter.normalize_key(:flag_key) == "flag_key"
      assert Adapter.normalize_key(:"claims-global-platform") == "claims-global-platform"
    end

    test "normalizes integers into a binary via to_string/1" do
      assert Adapter.normalize_key(123) == "123"
    end

    test "always returns a binary" do
      assert is_binary(Adapter.normalize_key("x"))
      assert is_binary(Adapter.normalize_key(["x"]))
      assert is_binary(Adapter.normalize_key(:x))
      assert is_binary(Adapter.normalize_key(1))
    end

    test "raises when input is nil" do
      assert_raise ArgumentError, "flag key cannot be nil", fn ->
        Adapter.normalize_key(nil)
      end
    end
  end
end
