defmodule ExLaunchDark.LDMultiContextStruct do
  @moduledoc """
  A struct to hold LaunchDarkly multi-context information.
  """

  @enforce_keys [:contexts]
  defstruct contexts: []

  @type t() :: %__MODULE__{
          contexts: [ExLaunchDark.LDContextStruct.t()]
        }
end
