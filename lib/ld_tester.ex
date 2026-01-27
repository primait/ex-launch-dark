defmodule ExLaunchDark.LDTester do
  @moduledoc """
  A module for testing purposes.
  """
  require Logger

  alias ExLaunchDark.LDAdapter
  alias ExLaunchDark.LDContextStruct

  @spec test_flag_value_random_context(atom(), binary(), atom() | binary() | nil) ::
          binary() | nil
  def test_flag_value_random_context(project_id, flag_key, default \\ nil) do
    random_context = build_random_context()
    LDAdapter.get_feature_flag_value(project_id, flag_key, random_context, default)
  end

  @spec test_flag_value_context_kind(atom(), binary(), binary(), map() | nil) :: binary() | nil
  def test_flag_value_context_kind(project_id, flag_key, context_kind, context_attr \\ %{}) do
    random_context = build_random_context(%{"kind" => context_kind, "attributes" => context_attr})
    LDAdapter.get_feature_flag_value(project_id, flag_key, random_context, nil)
  end

  @spec test_flag_value_fixed_context(atom(), binary(), binary(), binary(), map() | nil) ::
          binary() | nil
  def test_flag_value_fixed_context(
        project_id,
        flag_key,
        context_kind,
        context_key,
        context_attr \\ %{}
      ) do
    flag_context = %LDContextStruct{
      kind: context_kind,
      key: context_key,
      attributes: context_attr
    }

    LDAdapter.get_feature_flag_value(project_id, flag_key, flag_context, nil)
  end

  @spec test_all_flags_state_random(atom(), binary()) :: binary() | nil
  def test_all_flags_state_random(project_id, context_kind) do
    random_context = build_random_context(%{"kind" => context_kind})
    LDAdapter.get_all_flags(project_id, random_context)
  end

  defp build_random_context(context_data \\ %{}) do
    %LDContextStruct{
      key: Map.get(context_data, "key", "key-#{:rand.uniform(10000)}"),
      kind: Map.get(context_data, "kind", "user"),
      attributes: Map.get(context_data, "attributes", %{})
    }
  end
end
