# MCP over SSE

This library provides a simple implementation of the Model Context Protocol (MCP) over Server-Sent Events (SSE).

For more information about the Model Context Protocol, visit:
[Model Context Protocol Documentation](https://modelcontextprotocol.io/introduction)

## Installation

### For Phoenix Applications:

1. Add the required configuration to `config/config.exs`:

```elixir
# Configure MIME types for SSE
config :mime, :types, %{
  "text/event-stream" => ["sse"]
}

# Configure the MCP Server
config :mcp_sse, :mcp_server, MCP.DefaultServer
# config :mcp_sse, :mcp_server, YourApp.YourMCPServer
```

2. Add to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mcp_sse, "~> 0.1.4"}
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

### For Plug Applications with Bandit:

1. Create a new Plug application with supervision:

```bash
mix new your_app --sup
```

2. Add the required configuration to `config/config.exs`:

```elixir
import Config

# Configure MIME types for SSE
config :mime, :types, %{
  "text/event-stream" => ["sse"]
}

# Configure the MCP Server
config :mcp_sse, :mcp_server, YourApp.MCPServer
```

3. Add dependencies to `mix.exs`:

```elixir
def deps do
  [
    {:mcp_sse, "~> 0.1.4"},
    {:plug, "~> 1.14"},
    {:bandit, "~> 1.2"}
  ]
end
```

4. Configure your router (`lib/your_app/router.ex`):

```elixir
defmodule YourApp.Router do
  use Plug.Router

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["text/*"],
    json_decoder: JSON

  plug :match
  plug :ensure_session_id
  plug :dispatch

  # Middleware to ensure session ID exists
  def ensure_session_id(conn, _opts) do
    case get_session_id(conn) do
      nil ->
        # Generate a new session ID if none exists
        session_id = generate_session_id()
        %{conn | query_params: Map.put(conn.query_params, "sessionId", session_id)}
      _session_id ->
        conn
    end
  end

  # Helper to get session ID from query params
  defp get_session_id(conn) do
    conn.query_params["sessionId"]
  end

  # Generate a unique session ID
  defp generate_session_id do
    Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)
  end

  forward "/sse", to: SSE.ConnectionPlug
  forward "/message", to: SSE.ConnectionPlug

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
```

5. Set up your application supervision (`lib/your_app/application.ex`):

```elixir
defmodule YourApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Bandit, plug: YourApp.Router, port: 4000}
    ]

    opts = [strategy: :one_for_one, name: YourApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Session Management

The MCP SSE server requires a session ID for each connection. The router automatically:
- Uses an existing session ID from query parameters if provided
- Generates a new session ID if none exists
- Ensures all requests to `/sse` and `/message` endpoints have a valid session ID

### Configuration Options

The Bandit server can be configured with additional options in your application module:

```elixir
# Example with custom port and HTTPS
children = [
  {Bandit,
    plug: YourApp.Router,
    port: System.get_env("PORT", "4000") |> String.to_integer(),
    scheme: :https,
    certfile: "priv/cert/selfsigned.pem",
    keyfile: "priv/cert/selfsigned_key.pem"
  }
]
```

The `use MCPServer` macro provides:
- Built-in message routing
- Protocol version validation
- Default implementations for optional callbacks
- JSON-RPC error handling
- Logging

You only need to implement the required callbacks (`handle_ping/1` and `handle_initialize/2`) and any optional callbacks for features you want to support.

## Protocol Specification

For detailed information about the Model Context Protocol, visit:
[Model Context Protocol Specification](https://modelcontextprotocol.io/specification/2024-11-05/index)

## Features

- Full MCP server implementation
- SSE connection management
- JSON-RPC message handling
- Tool registration and execution
- Session management
- Automatic ping/keepalive
- Error handling and validation

## Contributing

...

## Quick Demo

To see the MCP server in action:

1. Start the example server in one terminal:
```bash
elixir dev/example_server.exs
```

2. In another terminal, run the demo client script:
```bash
elixir dev/example_client.exs
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

### SSE Keepalive

The SSE connection sends periodic keepalive pings to prevent connection timeouts.
You can configure the ping interval or disable it entirely:

```elixir
# In config/config.exs

# Set custom ping interval (in milliseconds)
config :mcp_sse, :sse_keepalive_timeout, 30_000  # 30 seconds

# Or disable pings entirely
config :mcp_sse, :sse_keepalive_timeout, :infinity
```

### MCP Response Formatting

When implementing tool responses in your MCP server, the content must follow the MCP specification for content types.
The response content should be formatted as one of these types:

```elixir
# Text content
{:ok,
 %{
   jsonrpc: "2.0",
   id: request_id,
   result: %{
     content: [
       %{
         type: "text",
         text: "Your text response here"
       }
     ]
   }
 }}

# Image content
{:ok,
 %{
   jsonrpc: "2.0",
   id: request_id,
   result: %{
     content: [
       %{
         type: "image",
         data: "base64_encoded_image_data",
         mimeType: "image/png"
       }
     ]
   }
 }}

# Resource reference
{:ok,
 %{
   jsonrpc: "2.0",
   id: request_id,
   result: %{
     content: [
       %{
         type: "resource",
         resource: %{
           name: "resource_name",
           description: "resource description"
         }
       }
     ]
   }
 }}
```

For structured data like JSON, you should convert it to a formatted string:

```elixir
def handle_call_tool(request_id, %{"name" => "list_companies"} = _params) do
  companies = fetch_companies()  # Your data fetching logic

  {:ok,
   %{
     jsonrpc: "2.0",
     id: request_id,
     result: %{
       content: [
         %{
           type: "text",
           text: JSON.encode!(companies, pretty: true)
         }
       ]
     }
   }}
end
```

For more details on response formatting, see the [MCP Content Types Specification](https://spec.modelcontextprotocol.io/specification/2024-11-05/basic/messages/#responses).
