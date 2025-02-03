# MCP over SSE

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mcp_sse` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mcp_sse, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/mcp_sse>.

## Quick Demo

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

## Installation

To use these modules in your Phoenix or Plug-based application:

1. Copy the following directories to your project:
   - `lib/mcp` - Core MCP implementation
   - `lib/sse` - SSE connection handling

2. Add required dependencies to your `mix.exs`:
```elixir
def deps do
  [
    {:jason, "~> 1.2"},       # JSON encoding/decoding
    {:plug, "~> 1.14"},       # If not using Phoenix
    {:phoenix, "~> 1.7.18"}   # If using Phoenix
  ]
end
```

## Configuration

1. Configure MIME types for SSE in `config/config.exs`:
```elixir
config :mime, :types, %{
  "text/event-stream" => ["sse"]
}
```

2. Set up the SSE connection registry in your application.ex:
```elixir
def start(_type, _args) do
  children = [
    # ... other children ...
    SSE.ConnectionRegistry,  # This will handle the ETS table creation
    # ... rest of your supervision tree
  ]
  
  opts = [strategy: :one_for_one, name: YourApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

3. Configure your router:

For Phoenix:
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

For Plug:
```elixir
forward "/sse", to: SSE.ConnectionPlug
forward "/message", to: SSE.ConnectionPlug
```

## Implementing Your MCP Server

1. Create a module using the `MCPServer` behaviour:

```elixir
defmodule YourApp.Server do
  use MCPServer

  @impl true
  def handle_ping(request_id) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: "pong"
     }}
  end

  @impl true
  def handle_initialize(request_id, params) do
    case validate_protocol_version(params["protocolVersion"]) do
      :ok ->
        {:ok,
         %{
           jsonrpc: "2.0",
           id: request_id,
           result: %{
             protocolVersion: "2024-11-05",
             capabilities: %{
               tools: %{
                 listChanged: true
               }
             },
             serverInfo: %{
               name: "Your MCP Server",
               version: "0.1.0"
             }
           }
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def handle_list_tools(request_id, _params) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         tools: [
           # Define your tools here
           %{
             name: "your_tool",
             description: "Your tool description",
             inputSchema: %{
               type: "object",
               required: ["input"],
               properties: %{
                 input: %{
                   type: "string",
                   description: "Input description"
                 }
               }
             },
             outputSchema: %{
               type: "object",
               required: ["output"],
               properties: %{
                 output: %{
                   type: "string",
                   description: "Output description"
                 }
               }
             }
           }
         ]
       }
     }}
  end

  @impl true
  def handle_call_tool(request_id, %{"name" => "example", "arguments" => %{"input" => input}}) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         content: [
           %{
             type: "text",
             text: "Processed: #{input}"
           }
         ]
       }
     }}
  end
end
```

2. Configure your server implementation in `config/config.exs`:
```elixir
config :your_app, :mcp_server, YourApp.Server
```

The `use MCPServer` macro provides:
- Built-in message routing
- Protocol version validation
- Default implementations for optional callbacks
- JSON-RPC error handling
- Logging

You only need to implement the required callbacks (`handle_ping/1` and `handle_initialize/2`) and any optional callbacks for features you want to support.

## Protocol Documentation

For detailed information about the Model Context Protocol, visit:
[Model Context Protocol Documentation](https://github.com/cursor-ai/model-context-protocol)

## Features

- Full MCP server implementation
- SSE connection management
- JSON-RPC message handling
- Tool registration and execution
- Session management
- Automatic ping/keepalive
- Error handling and validation

## Example Client Usage

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

