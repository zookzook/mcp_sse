defmodule MCP.MessageRouter do
  @moduledoc false

  # Internal routing implementation
  # Routes MCP JSON-RPC messages to appropriate server implementations.
  # Provides default handling for basic messages like ping.

  require Logger

  @doc false
  def handle_message(%{"method" => "notifications/initialized"} = message) do
    Logger.info("Received initialized notification")
    Logger.debug("Full message: #{inspect(message, pretty: true)}")
    # Notifications don't expect responses
    {:ok, nil}
  end

  @doc false
  def handle_message(%{"method" => method, "id" => id} = message) do
    server_implementation = Application.get_env(:mcp_sse, :mcp_server, MCP.DefaultServer)
    Logger.info("Routing MCP message - Method: #{method}, ID: #{id}")
    Logger.debug("Full message: #{inspect(message, pretty: true)}")

    case method do
      "ping" ->
        Logger.debug("Handling ping request")
        server_implementation.handle_ping(id)

      "initialize" ->
        Logger.info(
          "Handling initialize request with params: #{inspect(message["params"], pretty: true)}"
        )

        server_implementation.handle_initialize(id, message["params"])

      "tools/list" ->
        Logger.debug("Handling tools list request")
        server_implementation.handle_list_tools(id, message["params"])

      "tools/call" ->
        Logger.debug(
          "Handling tool call request with params: #{inspect(message["params"], pretty: true)}"
        )

        server_implementation.handle_call_tool(id, message["params"])

      other ->
        Logger.warning("Received unsupported method: #{other}")

        {:error,
         %{
           jsonrpc: "2.0",
           id: id,
           error: %{
             code: -32601,
             message: "Method not found",
             data: %{
               name: other
             }
           }
         }}
    end
  end

  @doc false
  def handle_message(unknown_message) do
    Logger.error("Received invalid message format: #{inspect(unknown_message, pretty: true)}")

    {:error,
     %{
       jsonrpc: "2.0",
       id: nil,
       error: %{
         code: -32600,
         message: "Invalid Request",
         data: %{
           received: unknown_message
         }
       }
     }}
  end
end
