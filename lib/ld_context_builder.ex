defmodule ExLaunchDark.LDContextBuilder do
  @moduledoc """
  Module for building LaunchDarkly context objects.
  """

  @spec build_context(ExLaunchDark.Adapter.context()) ::
          :ldclient_context.single_context() | :ldclient_context.multi_context()
  def build_context(%ExLaunchDark.LDMultiContextStruct{contexts: contexts})
      when is_list(contexts) do
    validate_multi_context!(contexts)

    contexts
    # reuse single-context builder
    |> Enum.map(&build_context/1)
    |> :ldclient_context.new_multi_from()
  end

  def build_context(context_struct) do
    context_struct
    |> validate_context()
    |> to_ld_context()
  end

  defp validate_multi_context!([]),
    do: raise("Context Error: multi-context must contain at least one context")

  defp validate_multi_context!(contexts) do
    kinds = Enum.map(contexts, & &1.kind)

    if length(kinds) != length(Enum.uniq(kinds)) do
      raise("Context Error: multi-context contains duplicate kinds: #{inspect(kinds)}")
    end

    :ok
  end

  defp validate_context(%{key: nil}), do: raise("Context Error: key cannot be nil")
  defp validate_context(%{kind: nil}), do: raise("Context Error: kind cannot be nil")
  defp validate_context(context_struct), do: context_struct

  defp to_ld_context(%{key: key, kind: kind, attributes: attributes}) do
    :ldclient_context.new(key, kind)
    |> set_context_attributes(attributes)
  end

  @spec set_context_attributes(:ldclient_context.single_context(), map()) ::
          :ldclient_context.single_context()
  defp set_context_attributes(context, attributes) do
    Enum.reduce(attributes, context, fn {attr_key, attr_value}, acc ->
      :ldclient_context.set(attr_key, attr_value, acc)
    end)
  end
end
