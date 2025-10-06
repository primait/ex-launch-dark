defmodule ExLaunchDark.LDContextStruct do
  @moduledoc """
  A struct to hold LaunchDarkly context information.
  """
  defstruct key: nil, kind: nil, attributes: []
end