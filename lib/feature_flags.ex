defmodule ExLaunchDark.FeatureFlags do
  @moduledoc """
  Unified interface for feature flag operations.

  This module provides a single, consistent API for client services to interact with feature flags.
  The underlying adapter (LaunchDarkly or in-memory) is automatically selected based on configuration.

  ## Configuration

  Configure the adapter in your config.exs:

      config :ex_launch_dark,
        adapter: ExLaunchDark.LDAdapter  # or ExLaunchDark.InMemoryAdapter

  ## Examples

      # Get a feature flag value
      {:ok, value, reason} = ExLaunchDark.FeatureFlags.get_flag(:my_project, "feature-key", context, false)

      # Track an event (LaunchDarkly adapter only)
      :ok = ExLaunchDark.FeatureFlags.track_event(:my_project, "event-name", context)

      # Get all flags (LaunchDarkly adapter only)
      flags_state = ExLaunchDark.FeatureFlags.get_all_flags(:my_project, context)
  """

  alias ExLaunchDark.LDAdapter
  alias ExLaunchDark.InMemoryAdapter
  alias ExLaunchDark.LDContextStruct

  @type context :: ExLaunchDark.Adapter.context()
  @type project_key :: ExLaunchDark.Adapter.project_key()
  @type flag_key :: ExLaunchDark.Adapter.flag_key()
  @type reason :: ExLaunchDark.Adapter.reason()

  @doc """
  Gets the value of a feature flag for the given context.

  ## Parameters
    - `project_key`: The project identifier (atom)
    - `flag_key`: The feature flag key (string or binary)
    - `context`: The context for evaluation (user, organization, etc.)
    - `default_value`: The default value to return if flag evaluation fails

  ## Returns
    - `{:ok, value, reason}` - Flag evaluation succeeded
    - `{:error, default_value, reason}` - Flag evaluation failed
    - `{:null, default_value, reason}` - Flag not found or undefined

  ## Examples

      iex> context = %ExLaunchDark.LDContextStruct{key: "user-123", kind: "user"}
      iex> ExLaunchDark.FeatureFlags.get_flag(:my_project, "new-feature", context, false)
      {:ok, true, :target_match}
  """
  @spec get_flag(project_key(), flag_key(), context(), any()) ::
          {:ok, any(), reason()} | {:error, any(), reason()} | {:null, any(), reason()}
  def get_flag(project_key, flag_key, context, default_value) do
    adapter = get_adapter()
    adapter.get_feature_flag_value(project_key, flag_key, context, default_value)
  end

  @doc """
  Tracks a custom event for a given context.

  Only supported when using the LaunchDarkly adapter. Will raise an error if called with InMemoryAdapter.

  ## Parameters
    - `project_key`: The project identifier (atom)
    - `event_name`: The name of the event to track
    - `context`: The context associated with the event
    - `event_data`: Optional additional event data (default: %{})

  ## Returns
    - `:ok` - Event tracked successfully

  ## Examples

      iex> context = %ExLaunchDark.LDContextStruct{key: "user-123", kind: "user"}
      iex> ExLaunchDark.FeatureFlags.track_event(:my_project, "purchase", context, %{amount: 99.99})
      :ok
  """
  @spec track_event(project_key(), String.t(), LDContextStruct.t(), map()) :: :ok
  def track_event(project_key, event_name, context, event_data \\ %{}) do
    case get_adapter() do
      LDAdapter ->
        LDAdapter.track_event(project_key, event_name, context, event_data)

      InMemoryAdapter ->
        raise "track_event is not supported by InMemoryAdapter"
    end
  end

  @doc """
  Retrieves the state of all feature flags for a given context.

  Only supported when using the LaunchDarkly adapter. Will raise an error if called with InMemoryAdapter.

  ## Parameters
    - `project_key`: The project identifier (atom)
    - `context`: The context for evaluation

  ## Returns
    - Feature flags state map

  ## Examples

      iex> context = %ExLaunchDark.LDContextStruct{key: "user-123", kind: "user"}
      iex> ExLaunchDark.FeatureFlags.get_all_flags(:my_project, context)
      %{...}
  """
  @spec get_all_flags(project_key(), LDContextStruct.t()) :: :ldclient_eval.feature_flags_state()
  def get_all_flags(project_key, context) do
    case get_adapter() do
      LDAdapter ->
        LDAdapter.get_all_flags(project_key, context)

      InMemoryAdapter ->
        raise "get_all_flags is not supported by InMemoryAdapter"
    end
  end

  @doc """
  Returns the currently configured adapter module.

  Defaults to `ExLaunchDark.LDAdapter` if not configured.

  ## Examples

      iex> ExLaunchDark.FeatureFlags.get_adapter()
      ExLaunchDark.LDAdapter
  """
  @spec get_adapter() :: module()
  def get_adapter do
    Application.get_env(:ex_launch_dark, :adapter, LDAdapter)
  end

  @doc """
  Checks if the current adapter is the in-memory adapter.

  Useful for conditional logic in tests or development environments.

  ## Examples

      iex> ExLaunchDark.FeatureFlags.using_in_memory_adapter?()
      false
  """
  @spec using_in_memory_adapter?() :: boolean()
  def using_in_memory_adapter? do
    get_adapter() == InMemoryAdapter
  end

  @doc """
  Checks if the current adapter is the LaunchDarkly adapter.

  ## Examples

      iex> ExLaunchDark.FeatureFlags.using_ld_adapter?()
      true
  """
  @spec using_ld_adapter?() :: boolean()
  def using_ld_adapter? do
    get_adapter() == LDAdapter
  end
end
