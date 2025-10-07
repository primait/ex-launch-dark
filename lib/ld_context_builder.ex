defmodule ExLaunchDark.LDContextBuilder do
  @moduledoc """
  Module for building LaunchDarkly context objects.
  """

  @spec build_context(ExLaunchDark.LDContextStruct.t()) :: :ld_context
  def build_context(context_struct) do
    context_struct
    |> validate_context()
    |> to_ld_context()
  end

  defp validate_context(%{key: nil} = _context_struct), do: raise "Context Error: key cannot be nil"
  defp validate_context(%{kind: nil} = _context_struct), do: raise "Context Error: kind cannot be nil"
  defp validate_context(context_struct), do: context_struct

  defp to_ld_context(%{key: key, kind: kind, attributes: attributes}) do
    :ldclient_context.new(key, kind)
    |> set_context_attributes(attributes)
  end

  defp set_context_attributes(context, attributes) do
    Enum.reduce(attributes, context, fn {attr_key, attr_value}, acc ->
      :ldclient_context.set(attr_key, attr_value, acc)
    end)
  end
end