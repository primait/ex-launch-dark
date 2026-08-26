defmodule ExLaunchDark.InMemoryAdapter.TableKeeper do
  @moduledoc false
  # Creates and owns the ETS table for the lifetime of this process.
  use GenServer

  @default_table :ex_launch_dark_feature_flags

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    table = Application.get_env(:ex_launch_dark, :in_memory_adapter_table, @default_table)
    :ets.new(table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{table: table}}
  end
end
