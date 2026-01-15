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

  def normalize_key(v) when is_binary(v), do: v
  def normalize_key(v) when is_list(v), do: IO.iodata_to_binary(v)
  def normalize_key(v), do: v |> to_string() |> IO.iodata_to_binary()
end
