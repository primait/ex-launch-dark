defmodule ExLaunchDark.Adapter do
  @moduledoc false

  @type context :: ExLaunchDark.LDContextStruct.t()
  @type project_key :: atom()
  @type flag_key :: String.t() | binary()
  @type reason :: atom()

  @callback get_feature_flag_value(project_key(), flag_key(), context(), any()) ::
              {:ok, any(), reason()}
              | {:error, any(), reason()}
              | {:null, any(), reason()}
end
