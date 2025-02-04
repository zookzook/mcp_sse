defmodule MCPSse.Example.Server do
  @moduledoc false
  # A simple example server that demonstrates the SSE functionality.
  # This is just a simple Plug-based server to help test and verify the :mcp_sse library.

  use Plug.Router

  # Add parsers before matching
  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Jason
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
    IO.puts("Starting example server on port 4000...")
    Bandit.start_link(plug: __MODULE__, port: 4000)
  end
end
