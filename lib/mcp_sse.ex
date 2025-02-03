defmodule MCPSse do
  @moduledoc """
  Main entry point for the MCPSse library.
  """

  @doc """
  Starts the MCPSse supervision tree.
  This is useful for testing and development.
  In production, you should add MCPSse to your application's dependencies.
  """
  def start do
    Application.ensure_all_started(:mcp_sse)
  end
end
