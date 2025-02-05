defmodule SSE.ConnectionState do
  @moduledoc false
  # Internal state management for SSE connections
  use GenServer

  alias SSE.ConnectionRegistry

  require Logger

  # 30 seconds for initialization
  @init_timeout 30_000
  # 30 minutes in milliseconds
  @inactivity_timeout 30 * 60 * 1000

  # State transitions
  # :connected -> :initialized -> :ready

  @doc false
  def start_link(session_id) do
    GenServer.start_link(__MODULE__, session_id)
  end

  @doc false
  @impl true
  def init(session_id) do
    # Start initialization timeout
    Process.send_after(self(), :init_timeout, @init_timeout)

    {:ok,
     %{
       session_id: session_id,
       state: :connected,
       init_received: false,
       initialized_received: false,
       last_activity: System.monotonic_time(:millisecond),
       # Add reference to the timeout timer
       timeout_ref: nil,
       # Store SSE process pid
       sse_pid: nil
     }}
  end

  @doc false
  def handle_initialize(pid) do
    GenServer.call(pid, :handle_initialize)
  end

  @doc false
  def handle_initialized(pid) do
    GenServer.call(pid, :handle_initialized)
  end

  @doc false
  def ready?(pid) do
    GenServer.call(pid, :ready?)
  end

  @doc false
  def record_activity(pid) do
    GenServer.call(pid, :record_activity)
  end

  @doc false
  def check_activity_timeout(pid) do
    GenServer.call(pid, :check_activity_timeout)
  end

  @doc false
  def set_sse_pid(pid, sse_pid) do
    GenServer.call(pid, {:set_sse_pid, sse_pid})
  end

  @doc false
  def cleanup(pid) do
    GenServer.stop(pid, :normal)
  end

  @impl true
  def handle_call(:handle_initialize, _from, state) do
    new_state = %{state | init_received: true, last_activity: System.monotonic_time(:millisecond)}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:handle_initialized, _from, %{init_received: true} = state) do
    new_state = %{
      state
      | initialized_received: true,
        state: :ready,
        last_activity: System.monotonic_time(:millisecond)
    }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:handle_initialized, _from, state) do
    {:reply, {:error, :not_initialized}, state}
  end

  @impl true
  def handle_call(:ready?, _from, %{state: :ready} = state) do
    {:reply, true, state}
  end

  @impl true
  def handle_call(:ready?, _from, state) do
    {:reply, false, state}
  end

  @impl true
  def handle_call({:set_sse_pid, sse_pid}, _from, state) do
    # Schedule initial inactivity timeout
    timeout_ref = schedule_inactivity_timeout(sse_pid)
    {:reply, :ok, %{state | sse_pid: sse_pid, timeout_ref: timeout_ref}}
  end

  @impl true
  def handle_call(:record_activity, _from, state) do
    # Cancel existing timeout
    if state.timeout_ref, do: Process.cancel_timer(state.timeout_ref)
    # Schedule new timeout
    timeout_ref = schedule_inactivity_timeout(state.sse_pid)

    new_state = %{
      state
      | last_activity: System.monotonic_time(:millisecond),
        timeout_ref: timeout_ref
    }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:check_activity_timeout, _from, state) do
    current_time = System.monotonic_time(:millisecond)
    time_since_activity = current_time - state.last_activity

    if time_since_activity >= @inactivity_timeout do
      {:reply, {:error, :activity_timeout}, state}
    else
      {:reply, :ok, state}
    end
  end

  @impl true
  def handle_info(:init_timeout, %{state: :ready} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:init_timeout, %{session_id: session_id} = state) do
    Logger.warning("Initialization timeout for session #{session_id}")
    # Look up the connection safely
    case :ets.lookup(ConnectionRegistry.table_name(), session_id) do
      [{^session_id, pid, _state_pid}] ->
        send(pid, :init_timeout)

      _ ->
        Logger.debug("Connection already removed from registry for session #{session_id}")
    end

    {:noreply, state}
  end

  defp schedule_inactivity_timeout(sse_pid) do
    Process.send_after(sse_pid, :inactivity_timeout, @inactivity_timeout)
  end
end
