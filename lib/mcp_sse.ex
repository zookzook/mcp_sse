defmodule MCP.SSE do
  @moduledoc """
  Main entry point for the MCPSse library.
  Provides the OTP Application behaviour.
  """
  use Application

  @impl true
  def start(_type, _args) do
    case already_started?() do
      true ->
        {:ok, self()}

      false ->
        children = [
          SSE.ConnectionRegistry
        ]

        opts = [strategy: :one_for_one, name: MCP.SSE.Supervisor]
        Supervisor.start_link(children, opts)
    end
  end

  @doc """
  Starts the MCPSse supervision tree.
  This is useful for testing and development.
  In production, you should add MCPSse to your application's dependencies.
  """
  def start do
    Application.ensure_all_started(:mcp_sse)
  end

  # Check if the registry is already started
  defp already_started? do
    case Process.whereis(MCP.SSE.Supervisor) do
      nil -> false
      _pid -> true
    end
  end
end
