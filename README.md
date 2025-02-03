# MCP over SSE

## Installation

### For Phoenix Applications:

1. Add the required configuration to `config/config.exs`:

```elixir
# Configure MIME types for SSE
config :mime, :types, %{
  "text/event-stream" => ["sse"]
}

# Configure the MCP Server
config :nws_mcp_server, :mcp_server, MCP.DefaultServer
# config :nws_mcp_server, :mcp_server, YourApp.YourMCPServer
```

2. Add to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mcp_sse, "~> 0.1.0"}
  ]
end
```

3. Configure your router (`lib/your_app_web/router.ex`):

```elixir
pipeline :sse do
  plug :accepts, ["sse"]
end

scope "/" do
  pipe_through :sse
  get "/sse", SSE.ConnectionPlug, :call
  
  pipe_through :api
  post "/message", SSE.ConnectionPlug, :call
end
```

### For Plug Applications:

1. Add the required configuration to `config/config.exs`:

```elixir
# Configure MIME types for SSE
config :mime, :types, %{
  "text/event-stream" => ["sse"]
}

# Configure the MCP Server
config :your_app, :mcp_server, YourApp.YourMCPServer
```

2. Add to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mcp_sse, git: "https://github.com/kend/mcp_sse", override: true},
    {:plug_cowboy, "~> 2.6"}
  ]
end
```

3. Configure your router (`lib/your_app/router.ex`):

```elixir
defmodule YourApp.Router do
  use Plug.Router
  
  plug :match
  plug :dispatch

  forward "/sse", to: SSE.ConnectionPlug
  forward "/message", to: SSE.ConnectionPlug

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
```

Then update your config to use your implementation:

```elixir
config :nws_mcp_server, :mcp_server, YourApp.YourMCPServer
```

The `use MCPServer` macro provides:
- Built-in message routing
- Protocol version validation
- Default implementations for optional callbacks
- JSON-RPC error handling
- Logging

You only need to implement the required callbacks (`handle_ping/1` and `handle_initialize/2`) and any optional callbacks for features you want to support.

### Protocol Documentation

For detailed information about the Model Context Protocol, visit:
[Model Context Protocol Documentation](https://github.com/cursor-ai/model-context-protocol)

### Features

- Full MCP server implementation
- SSE connection management
- JSON-RPC message handling
- Tool registration and execution
- Session management
- Automatic ping/keepalive
- Error handling and validation

## Contributing

...

### Quick Demo

To see the MCP server in action:

1. Start the Phoenix server:
```bash
mix phx.server
```

2. In another terminal, run the demo client script:
```bash
elixir examples/mcp_client.exs
```

The client script will:
- Connect to the SSE endpoint
- Initialize the connection
- List available tools
- Call the upcase tool with example input
- Display the results of each step

This provides a practical demonstration of the MCP protocol flow and server capabilities.

## Other Notes

### Example Client Usage

```javascript
// Connect to SSE endpoint
const sse = new EventSource('/sse');

// Handle endpoint message
sse.addEventListener('endpoint', (e) => {
  const messageEndpoint = e.data;
  // Use messageEndpoint for subsequent JSON-RPC requests
});

// Send initialize request
fetch('/message?sessionId=YOUR_SESSION_ID', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    jsonrpc: '2.0',
    id: 1,
    method: 'initialize',
    params: {
      protocolVersion: '2024-11-05',
      capabilities: {}
    }
  })
});
```

### Pending Tasks

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/mcp_sse>.
