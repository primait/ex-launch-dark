defmodule ExLaunchDark.LDAdapter do
  @moduledoc """
  Adapter module for LaunchDarkly feature flag evaluations.
  """
  require Logger

  alias ExLaunchDark.Client
  alias ExLaunchDark.LDContextBuilder

  @spec init(ExLaunchDark.LDConfig.t()) :: Client.client_status
  def init(ld_config) do
    Client.init(ld_config)
  end

  @doc """
  Retrieves the value of a feature flag for a given context.
  """
  @spec get_feature_flag_value(Client.client_status, String.t(), ExLaunchDark.LDContextStruct, any()) :: {:ok, any(), any()} | {:error, any()}
  def get_feature_flag_value(client_status, flag_key, ld_context, default_value \\ false) do
    case client_status do
      :client_ready ->
        LDContextBuilder.build_context(ld_context)
        |> fetch_flag_value(flag_key, default_value)
      :client_error ->
        {:error, :client_not_initialized}
    end
  end

  defp fetch_flag_value(ld_context, flag_key, default_value) do
    Logger.debug("LDContext: #{inspect(ld_context)}")
    case :ldclient.variation_detail(flag_key, ld_context, default_value) do
      {_, _default, {:error, reason}} ->
        Client.terminate()
        {:error, reason}

      {_variation_idx, value, details} ->
        Client.terminate()
        {:ok, value, get_value_reason(details)}
    end
  end

  defp get_value_reason({reason, _, _}), do: reason
  defp get_value_reason(reason) when is_atom(reason), do: reason
  defp get_value_reason({reason}), do: reason
end