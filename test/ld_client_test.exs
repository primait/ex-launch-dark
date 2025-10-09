defmodule ExLaunchDark.ClientTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias ExLaunchDark.Client
  alias ExLaunchDark.LDConfig

  describe "validate_config" do
    test "raises error when sdk_key is nil" do
      config = %LDConfig{
        sdk_key: nil,
        base_uri: "https://app.launchdarkly.com",
        options: %{}
      }

      assert_raise RuntimeError, fn ->
        Client.init(config, :test_project)
      end
    end

    test "raises error when base_uri is nil" do
      config = %LDConfig{
        sdk_key: "sdk-test-key",
        base_uri: nil,
        options: %{}
      }

      assert_raise RuntimeError, fn ->
        Client.init(config, :test_project)
      end
    end
  end

  describe "init integration" do
    test "returns client_status ready" do
      config = %LDConfig{
        sdk_key: "sdk-test-key",
        base_uri: "https://app.launchdarkly.com",
        options: %{}
      }

      :meck.new(:ldclient, [:no_link])

      :meck.expect(:ldclient, :start_instance, fn sdk_key, project_id, options ->
        assert sdk_key == String.to_charlist(config.sdk_key)
        assert project_id == :test_project
        assert options[:base_uri] == String.to_charlist(config.base_uri)
        :ok
      end)

      capture_log(fn ->
        assert Client.init(config, :test_project) == :client_ready
      end)

      :meck.unload(:ldclient)
    end
  end
end
