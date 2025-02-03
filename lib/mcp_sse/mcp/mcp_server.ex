defmodule MCPServer do
  @moduledoc """
  Behaviour definition for MCP servers.
  Implements required message handlers based on the MCP specification.

  ## Usage

  ```elixir
  defmodule MyApp.Server do
    use MCPServer

    # Implement required callbacks
    @impl true
    def handle_ping(request_id) do
      {:ok, %{jsonrpc: "2.0", id: request_id, result: "pong"}}
    end

    @impl true
    def handle_initialize(request_id, params) do
      # Your initialization logic
    end

    # Optionally implement other callbacks
    @impl true
    def handle_list_tools(request_id, _params) do
      {:ok, %{jsonrpc: "2.0", id: request_id, result: %{tools: []}}}
    end
  end
  ```

  """

  @protocol_version "2024-11-05"

  defmacro __using__(_opts) do
    quote do
      @behaviour MCPServer
      require Logger

      # Built-in message routing
      def handle_message(%{"method" => "notifications/initialized"} = message) do
        Logger.info("Received initialized notification")
        Logger.debug("Full message: #{inspect(message, pretty: true)}")
        {:ok, nil}
      end

      def handle_message(%{"method" => method, "id" => id} = message) do
        Logger.info("Routing MCP message - Method: #{method}, ID: #{id}")
        Logger.debug("Full message: #{inspect(message, pretty: true)}")

        case method do
          "ping" ->
            Logger.debug("Handling ping request")
            handle_ping(id)

          "initialize" ->
            Logger.info(
              "Handling initialize request with params: #{inspect(message["params"], pretty: true)}"
            )

            handle_initialize(id, message["params"])

          "tools/list" ->
            Logger.debug("Handling tools list request")
            handle_list_tools(id, message["params"])

          "tools/call" ->
            Logger.debug(
              "Handling tool call request with params: #{inspect(message["params"], pretty: true)}"
            )

            handle_call_tool(id, message["params"])

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

      # Default implementations for optional callbacks
      def handle_complete(_request_id, _params), do: {:error, "Not implemented"}
      def handle_list_prompts(_request_id, _params), do: {:error, "Not implemented"}
      def handle_get_prompt(_request_id, _params), do: {:error, "Not implemented"}
      def handle_list_resources(_request_id, _params), do: {:error, "Not implemented"}
      def handle_read_resource(_request_id, _params), do: {:error, "Not implemented"}
      def handle_list_tools(_request_id, _params), do: {:error, "Not implemented"}
      def handle_call_tool(_request_id, _params), do: {:error, "Not implemented"}

      # Allow overriding any of the defaults
      defoverridable handle_complete: 2,
                     handle_list_prompts: 2,
                     handle_get_prompt: 2,
                     handle_list_resources: 2,
                     handle_read_resource: 2,
                     handle_list_tools: 2,
                     handle_call_tool: 2

      # Helper functions
      def validate_protocol_version(client_version) do
        cond do
          is_nil(client_version) ->
            {:error, "Protocol version is required"}

          client_version != unquote(@protocol_version) ->
            {:error,
             "Unsupported protocol version. Server supports: #{unquote(@protocol_version)}"}

          true ->
            :ok
        end
      end
    end
  end

  @doc """
  Handle ping request
  """
  @callback handle_ping(request_id :: String.t() | integer()) ::
              {:ok, map()} | {:error, String.t()}

  @doc """
  Handle initialization request with client capabilities
  """
  @callback handle_initialize(request_id :: String.t() | integer(), params :: map()) ::
              {:ok, map()} | {:error, String.t()}

  @doc """
  Handle completion request for prompts or resources
  """
  @callback handle_complete(request_id :: String.t() | integer(), params :: map()) ::
              {:ok, map()} | {:error, String.t()}

  @doc """
  Handle request to list available prompts
  """
  @callback handle_list_prompts(request_id :: String.t() | integer(), params :: map()) ::
              {:ok, map()} | {:error, String.t()}

  @doc """
  Handle request to get a specific prompt
  """
  @callback handle_get_prompt(request_id :: String.t() | integer(), params :: map()) ::
              {:ok, map()} | {:error, String.t()}

  @doc """
  Handle request to list available resources
  """
  @callback handle_list_resources(request_id :: String.t() | integer(), params :: map()) ::
              {:ok, map()} | {:error, String.t()}

  @doc """
  Handle request to read a specific resource
  """
  @callback handle_read_resource(request_id :: String.t() | integer(), params :: map()) ::
              {:ok, map()} | {:error, String.t()}

  @doc """
  Handle request to list available tools
  """
  @callback handle_list_tools(request_id :: String.t() | integer(), params :: map()) ::
              {:ok, map()} | {:error, String.t()}

  @doc """
  Handle request to call a specific tool
  """
  @callback handle_call_tool(request_id :: String.t() | integer(), params :: map()) ::
              {:ok, map()} | {:error, String.t()}

  @optional_callbacks [
    handle_complete: 2,
    handle_list_prompts: 2,
    handle_get_prompt: 2,
    handle_list_resources: 2,
    handle_read_resource: 2,
    handle_list_tools: 2,
    handle_call_tool: 2
  ]
end
