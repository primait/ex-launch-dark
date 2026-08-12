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

  @spec scope() :: :global | :process
  defp scope do
    case Application.get_env(:ex_launch_dark, :in_memory_adapter_scope, :global) do
      :global -> :global
      :process -> :process
      invalid -> raise ArgumentError, "invalid :in_memory_adapter_scope: #{inspect(invalid)}"
    end
  end

  defp table do
    Application.get_env(:ex_launch_dark, :in_memory_adapter_table, @default_table)
  end

  defp ensure_table do
    t = table()

    case :ets.info(t) do
      :undefined ->
        try do
          :ets.new(t, [:named_table, :set, :public, read_concurrency: true])
          :ok
        rescue
          # another process already created the table concurrently
          ArgumentError -> :ok
        end

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

  @doc """
  Clears all feature flags for the given process ID.
  """
  @spec clear_flags_for(pid()) :: :ok
  def clear_flags_for(pid) when is_pid(pid) do
    ensure_table()
    :ets.match_delete(table(), {{pid, :_}, :_})
    :ok
  end

  @spec enable(flag_key()) :: :ok
  def enable(flag_key), do: set_flag_value(flag_key, true)

  @spec disable(flag_key()) :: :ok
  def disable(flag_key), do: set_flag_value(flag_key, false)

  @spec set_flag_value(flag_key(), boolean()) :: :ok
  def set_flag_value(flag_key, value) when is_boolean(value) do
    ensure_table()
    :ets.insert(table(), {scope_key(flag_key), value})
    :ok
  end

  @impl true
  def get_feature_flag_value(_proj_key, flag_key, _context, default) do
    ensure_table()

    case :ets.lookup(table(), scope_key(flag_key)) do
      [{_, value}] -> {:ok, value, :test_override}
      [] -> {:ok, default, :default}
      _ -> {:error, default, :no_match}
    end
  end

  # Builds the ETS key according to the configured scope:
  # - :global -> shared across all processes
  # - :process -> scoped to the current process
  defp scope_key(flag_key) do
    normalized_key = ExLaunchDark.Adapter.normalize_key(flag_key)

    case scope() do
      :global -> normalized_key
      :process -> {self(), normalized_key}
    end
  end
end
