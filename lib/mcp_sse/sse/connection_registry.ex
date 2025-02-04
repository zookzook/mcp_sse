defmodule SSE.ConnectionRegistry do
  @moduledoc """
  Manages the ETS table for SSE connections.

  This module provides a centralized registry for Server-Sent Events (SSE) connections
  using an ETS table. It ensures the table is created when the application starts and
  provides access to the table name for other modules to interact with the connection data.
  """
  use GenServer

  @table_name :sse_connections

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  @impl true
  def init(_) do
    table = :ets.new(@table_name, [:set, :public, :named_table])
    {:ok, %{table: table}}
  end

  @doc """
  Returns the table name used for storing SSE connections.

  The table name is used by other modules to interact with the ETS table
  that stores SSE connection information.

  ## Returns

    * `:sse_connections` - The atom representing the ETS table name

  ## Examples

      iex> SSE.ConnectionRegistry.table_name()
      :sse_connections

  """
  def table_name, do: @table_name
end
