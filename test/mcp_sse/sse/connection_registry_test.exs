defmodule SSE.ConnectionRegistryTest do
  use ExUnit.Case, async: true

  alias SSE.ConnectionRegistry

  test "creates ETS table with correct properties" do
    table_name = ConnectionRegistry.table_name()

    assert :ets.info(table_name) != :undefined
    assert :ets.info(table_name, :type) == :set
    assert :ets.info(table_name, :protection) == :public
    assert :ets.info(table_name, :named_table) == true
  end

  test "table_name/0 returns consistent name" do
    assert is_atom(ConnectionRegistry.table_name())
    assert ConnectionRegistry.table_name() == ConnectionRegistry.table_name()
  end

  test "table is usable for basic operations" do
    table_name = ConnectionRegistry.table_name()
    test_key = "test_session"
    test_pid = self()

    test_state_pid =
      spawn(fn ->
        receive do
          :stop -> :ok
        end
      end)

    :ets.insert(table_name, {test_key, test_pid, test_state_pid})
    assert :ets.lookup(table_name, test_key) == [{test_key, test_pid, test_state_pid}]

    send(test_state_pid, :stop)
  end
end
