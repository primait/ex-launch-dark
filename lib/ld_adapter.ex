defmodule ExLaunchDark.LDAdapter do
  @moduledoc """
  Adapter module for LaunchDarkly feature flag evaluations.
  """
  require Logger

  alias ExLaunchDark.LDContextBuilder

  @doc """
  Retrieves the value of a single feature flag for a given context.
  """
  @spec get_feature_flag_value(atom(), String.t(), ExLaunchDark.LDContextStruct, any()) ::
          {:ok, any(), any()} | {:error, any()}
  def get_feature_flag_value(project_id, flag_key, ld_context, default_value \\ false) do
    LDContextBuilder.build_context(ld_context)
    |> fetch_flag_value(project_id, flag_key, default_value)
  end

  defp fetch_flag_value(ld_context, project_id, flag_key, default_value) do
    Logger.debug("LDContext: #{inspect(ld_context)}")

    case :ldclient.variation_detail(flag_key, ld_context, default_value, project_id) do
      {_, _default, {:error, reason}} ->
        {:error, reason}

      {_variation_idx, value, details} ->
        {:ok, value, get_value_reason(details)}
    end
  end

  @doc """
  Tracks a custom event for a given context.
  """
  @spec track_event(
          atom(),
          String.t(),
          ExLaunchDark.LDContextStruct,
          :ldclient_event.event_data()
        ) :: :ok
  def track_event(project_id, event_name, ld_context, event_data \\ %{}) do
    ld_context = LDContextBuilder.build_context(ld_context)
    :ldclient.track(event_name, ld_context, event_data, project_id)
  end

  @doc """
  Retrieves the state of all feature flags for a given context.
  """
  @spec get_all_flags(atom(), ExLaunchDark.LDContextStruct) ::
          :ldclient_eval.feature_flags_state()
  def get_all_flags(project_id, ld_context) do
    ld_context
    |> LDContextBuilder.build_context()
    |> :ldclient.all_flags_state(project_id)
  end

  defp get_value_reason({reason, _, _}), do: reason
  defp get_value_reason(reason) when is_atom(reason), do: reason
  defp get_value_reason({reason}), do: reason
end
