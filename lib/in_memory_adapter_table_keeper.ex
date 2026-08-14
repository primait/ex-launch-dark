defmodule ExLaunchDark.InMemoryAdapter.TableKeeper do
  @moduledoc false
  # Holds ETS table ownership so the table survives any caller process exiting.
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, nil}

  @impl true
  def handle_info({:"ETS-TRANSFER", _table, _from, _gift}, state), do: {:noreply, state}
end
