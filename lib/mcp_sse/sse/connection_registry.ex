defmodule SSE.ConnectionRegistry do
  @moduledoc """
  Manages the ETS table for SSE connections.
  This module ensures the table is created when the application starts.
  """
  use GenServer

  @table_name :sse_connections

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    table = :ets.new(@table_name, [:set, :public, :named_table])
    {:ok, %{table: table}}
  end

  @doc """
  Returns the table name for use in other modules.
  """
  def table_name, do: @table_name
end
