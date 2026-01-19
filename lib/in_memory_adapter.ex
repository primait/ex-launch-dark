defmodule ExLaunchDark.InMemoryAdapter do
  @moduledoc """
  In-memory adapter for feature flags, primarily for testing/local development.

  Stores overrides in ETS keyed by LaunchDarkly flag key (string/binary).
  Do not use in production.
  """

  @behaviour ExLaunchDark.Adapter

  @type context :: ExLaunchDark.Adapter.context()
  @type flag_key :: ExLaunchDark.Adapter.flag_key()

  @default_table :ex_launch_dark_feature_flags

  defp table do
    Application.get_env(:ex_launch_dark, :in_memory_adapter_table, @default_table)
  end

  defp ensure_table do
    t = table()

    case :ets.info(t) do
      :undefined ->
        :ets.new(t, [:named_table, :set, :public, read_concurrency: true])
        :ok

      _ ->
        :ok
    end
  end

  @spec clear_flags() :: :ok
  def clear_flags do
    ensure_table()
    :ets.delete_all_objects(table())
    :ok
  end

  @spec enable(flag_key()) :: :ok
  def enable(flag_key), do: set_flag_value(flag_key, true)

  @spec disable(flag_key()) :: :ok
  def disable(flag_key), do: set_flag_value(flag_key, false)

  @spec set_flag_value(flag_key(), boolean()) :: :ok
  def set_flag_value(flag_key, value) when is_boolean(value) do
    ensure_table()
    key = ExLaunchDark.Adapter.normalize_key(flag_key)
    :ets.insert(table(), {key, value})
    :ok
  end

  @impl true
  @spec get_feature_flag_value(atom(), flag_key(), context(), any()) ::
          {:ok, any(), atom()} | {:error, any(), atom()} | {:null, any(), atom()}
  def get_feature_flag_value(_proj_key, flag_key, _context, default) do
    ensure_table()
    key = ExLaunchDark.Adapter.normalize_key(flag_key)

    case :ets.lookup(table(), key) do
      [{^key, value}] -> {:ok, value, :test_override}
      [] -> {:ok, default, :default}
      _ -> {:error, default, :no_match}
    end
  end
end
