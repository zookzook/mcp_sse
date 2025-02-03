defmodule SSE.ConnectionStateTest do
  use ExUnit.Case, async: true
  require Logger
  import ExUnit.CaptureLog

  alias SSE.ConnectionState

  setup do
    session_id = "test-session-#{:rand.uniform(1000)}"
    {:ok, pid} = ConnectionState.start_link(session_id)

    # Set up ETS table if it doesn't exist
    if :ets.whereis(:sse_connections) == :undefined do
      :ets.new(:sse_connections, [:named_table, :public])
    end

    on_exit(fn ->
      # Clean up any test data but don't delete the table
      :ets.match_delete(:sse_connections, {session_id, :_, :_})
    end)

    %{session_id: session_id, pid: pid}
  end

  describe "state transitions" do
    test "starts in connected state", %{pid: pid} do
      refute ConnectionState.ready?(pid)
    end

    test "transitions through initialization sequence", %{pid: pid} do
      # Initial state
      refute ConnectionState.ready?(pid)

      # After initialize
      assert :ok = ConnectionState.handle_initialize(pid)
      refute ConnectionState.ready?(pid)

      # After initialized
      assert :ok = ConnectionState.handle_initialized(pid)
      assert ConnectionState.ready?(pid)
    end

    test "requires initialize before initialized", %{pid: pid} do
      assert {:error, :not_initialized} = ConnectionState.handle_initialized(pid)
      refute ConnectionState.ready?(pid)
    end
  end

  describe "activity tracking" do
    test "records activity", %{pid: pid} do
      assert :ok = ConnectionState.record_activity(pid)
      assert :ok = ConnectionState.check_activity_timeout(pid)
    end

    test "tracks SSE pid", %{pid: pid} do
      test_pid = self()
      assert :ok = ConnectionState.set_sse_pid(pid, test_pid)
    end
  end

  describe "timeouts" do
    test "handles initialization timeout when not ready", %{pid: pid, session_id: session_id} do
      # Insert our test connection
      :ets.insert(:sse_connections, {session_id, self(), pid})

      log =
        capture_log(fn ->
          # Trigger timeout manually
          send(pid, :init_timeout)

          # Assert we receive the timeout message
          assert_receive :init_timeout
        end)

      assert log =~ "Initialization timeout for session #{session_id}"
    end

    test "ignores initialization timeout when ready", %{pid: pid} do
      # Complete initialization
      ConnectionState.handle_initialize(pid)
      ConnectionState.handle_initialized(pid)

      # Trigger timeout manually
      send(pid, :init_timeout)

      # Assert we don't receive the timeout message
      refute_receive :init_timeout
    end
  end
end
