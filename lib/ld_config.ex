defmodule ExLaunchDark.LDConfig do
  @moduledoc """
  A struct to hold LaunchDarkly configuration information.
  """

  defstruct sdk_key: nil, base_uri: "https://app.launchdarkly.com", options: %{}
end