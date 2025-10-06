defmodule ExLaunchDark.LDContextStruct do
  @moduledoc """
  A struct to hold LaunchDarkly context information.
  """
  @enforce_keys [:key, :kind]
  defstruct key: nil, kind: nil, attributes: %{}
end