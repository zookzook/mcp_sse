defmodule MCP.SSE do
  @moduledoc false

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
  Starts the MCP.SSE supervision tree.
  This is useful for testing and development.
  In production, you should add MCP.SSE to your application's dependencies.
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
