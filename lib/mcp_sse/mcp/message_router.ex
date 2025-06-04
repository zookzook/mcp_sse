defmodule MCP.MessageRouter do
  @moduledoc false

  # Internal routing implementation
  # Routes MCP JSON-RPC messages to appropriate server implementations.
  # Provides default handling for basic messages like ping.

  require Logger

  @doc false
  def handle_message(_conn, %{"method" => "notifications/initialized"} = message) do
    Logger.info("Received initialized notification")
    Logger.debug("Full message: #{inspect(message, pretty: true)}")
    # Notifications don't expect responses
    {:ok, nil}
  end

  @doc false
  def handle_message(conn, %{"method" => method, "id" => id} = message) do
    server_implementation = Application.get_env(:mcp_sse, :mcp_server, MCP.DefaultServer)
    Logger.info("Routing MCP message - Method: #{method}, ID: #{id}")
    Logger.debug("Full message: #{inspect(message, pretty: true)}")

    case method do
      "ping" ->
        Logger.debug("Handling ping request")
        server_implementation.handle_ping(conn, id)

      "initialize" ->
        Logger.info(
          "Handling initialize request with params: #{inspect(message["params"], pretty: true)}"
        )

        server_implementation.handle_initialize(conn, id, message["params"])

      "completion/complete" ->
        Logger.debug(
          "Handling complete request with params: #{inspect(message["params"], pretty: true)}"
        )

        server_implementation.handle_complete(conn, id, message["params"])

      "prompts/list" ->
        Logger.debug("Handling prompts list request")
        server_implementation.handle_list_prompts(conn, id, message["params"])

      "prompts/get" ->
        Logger.debug(
          "Handling prompt get request with params: #{inspect(message["params"], pretty: true)}"
        )

        server_implementation.handle_get_prompt(conn, id, message["params"])

      "resources/list" ->
        Logger.debug("Handling resources list request")
        server_implementation.handle_list_resources(conn, id, message["params"])

      "resources/read" ->
        Logger.debug(
          "Handling resource read request with params: #{inspect(message["params"], pretty: true)}"
        )

        server_implementation.handle_read_resource(conn, id, message["params"])

      "tools/list" ->
        Logger.debug("Handling tools list request")
        server_implementation.handle_list_tools(conn, id, message["params"])

      "tools/call" ->
        Logger.debug(
          "Handling tool call request with params: #{inspect(message["params"], pretty: true)}"
        )

        server_implementation.handle_call_tool(conn, id, message["params"])

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
  def handle_message(_conn, unknown_message) do
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
