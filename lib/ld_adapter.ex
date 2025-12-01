defmodule ExLaunchDark.LDAdapter do
  @moduledoc """
  Adapter module for LaunchDarkly feature flag evaluations.
  """
  require Logger

  alias ExLaunchDark.LDContextBuilder
  alias ExLaunchDark.LDContextStruct

  @doc """
  Retrieves the value of a single feature flag for a given context.
  """
  @spec get_feature_flag_value(atom(), String.t(), any(), any()) ::
          {:ok, any(), atom()} | {:error, any(), atom()} | {:null, any(), atom()}
  def get_feature_flag_value(project_id, flag_key, ld_context, default_value \\ false) do
    LDContextBuilder.build_context(ld_context)
    |> fetch_flag_value(project_id, flag_key, default_value)
  end

  defp fetch_flag_value(ld_context, project_id, flag_key, default_value) do
    Logger.debug("Fetching flag: #{flag_key} with LDContext: #{inspect(ld_context)}")

    :ldclient.variation_detail(flag_key, ld_context, default_value, project_id)
    |> parse_flag_response(default_value)
  end

  defp parse_flag_response({_, _, {:error, reason}}, default_value) do
    Logger.error("Flag response error", reason: inspect(reason))
    {:error, default_value, reason}
  end

  defp parse_flag_response({variation_idx, value, {reason, _, _}}, _default_value) do
    Logger.debug(
      "Flag response ok - variation: #{variation_idx}, value: #{inspect(value)}, reason: #{inspect(reason)}"
    )

    {:ok, value, reason}
  end

  defp parse_flag_response({_idx, _value, reason}, default_value) do
    Logger.warning("Flag response mismatch", reason: inspect(reason))
    {:null, default_value, reason}
  end

  @doc """
  Tracks a custom event for a given context.
  """
  @spec track_event(
          atom(),
          String.t(),
          %LDContextStruct{},
          :ldclient_event.event_data()
        ) :: :ok
  def track_event(project_id, event_name, ld_context, event_data \\ %{}) do
    ld_context = LDContextBuilder.build_context(ld_context)
    :ldclient.track(event_name, ld_context, event_data, project_id)
  end

  @doc """
  Retrieves the state of all feature flags for a given context.
  """
  @spec get_all_flags(atom(), %LDContextStruct{}) ::
          :ldclient_eval.feature_flags_state()
  def get_all_flags(project_id, ld_context) do
    ld_context
    |> LDContextBuilder.build_context()
    |> :ldclient.all_flags_state(project_id)
  end
end
