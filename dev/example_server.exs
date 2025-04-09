# Simple MCP server to demonstrate protocol flow
Mix.install([
  {:plug, "~> 1.14"},
  {:bandit, "~> 1.5"},
  {:mcp_sse, path: "."}  # Use the local package
])

# Configure the MIME types for SSE
Application.put_env(:mime, :types, %{"text/event-stream" => ["sse"]})

# Configure the MCP Server for this example
Application.put_env(:mcp_sse, :mcp_server, MCP.DefaultServer)

defmodule MCPSse.Example.Server do
  @moduledoc false
  # A simple example server that demonstrates the SSE functionality.
  # This is just a simple Plug-based server to help test and verify the :mcp_sse library.

  use Plug.Router
  require Logger

  # Add parsers before matching
  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: JSON
  )

  plug(:match)
  plug(:dispatch)

  forward("/", to: SSE.ConnectionPlug)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 5000
    }
  end

  def start_link(_opts \\ []) do
    Logger.info("Starting example server on port 4000...")
    Logger.info("Press Ctrl+C to stop")
    {:ok, _} = Bandit.start_link(plug: __MODULE__, port: 4000)
  end
end

# Start the MCPSse application
Application.ensure_all_started(:mcp_sse)

# Create a supervision tree for our example server
children = [
  MCPSse.Example.Server
]

# Start the supervisor
{:ok, _sup_pid} = Supervisor.start_link(children, strategy: :one_for_one)

# Keep the script running by waiting on the supervisor
Process.sleep(:infinity)
