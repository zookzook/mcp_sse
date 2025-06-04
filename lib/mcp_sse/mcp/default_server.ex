defmodule MCP.DefaultServer do
  @moduledoc false

  # Default implementation of the MCPServer behaviour.
  # Provides basic functionality and stubs for optional callbacks.
  use MCPServer

  require Logger

  @protocol_version "2024-11-05"

  @impl true
  def handle_ping(_conn, request_id) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{}
     }}
  end

  @impl true
  def handle_initialize(_conn, request_id, params) do
    Logger.info("Client initialization params: #{inspect(params, pretty: true)}")

    case validate_protocol_version(params["protocolVersion"]) do
      :ok ->
        # Only include capabilities for implemented callbacks
        {:ok,
         %{
           jsonrpc: "2.0",
           id: request_id,
           result: %{
             protocolVersion: @protocol_version,
             capabilities: %{
               tools: %{
                 listChanged: true
               }
             },
             serverInfo: %{
               name: "SSE Demo MCP Server",
               version: "0.1.0"
             }
           }
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def handle_list_tools(_conn, request_id, _params) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         tools: [
           %{
             name: "upcase",
             description: "Converts text to uppercase",
             inputSchema: %{
               type: "object",
               required: ["text"],
               properties: %{
                 text: %{
                   type: "string",
                   description: "The text to convert to uppercase"
                 }
               }
             },
             outputSchema: %{
               type: "object",
               required: ["output"],
               properties: %{
                 output: %{
                   type: "string",
                   description: "The uppercase version of the input text"
                 }
               }
             }
           }
         ]
       }
     }}
  end

  @impl true
  def handle_call_tool(
        _conn,
        request_id,
        %{"name" => "upcase", "arguments" => %{"text" => text}} = params
      ) do
    Logger.debug("Handling upcase tool call with params: #{inspect(params)}")

    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         content: [
           %{
             type: "text",
             text: String.upcase(text)
           }
         ]
       }
     }}
  end

  def handle_call_tool(_conn, request_id, %{"name" => unknown_tool} = params) do
    Logger.warning("Unknown tool called: #{unknown_tool} with params: #{inspect(params)}")

    {:error,
     %{
       jsonrpc: "2.0",
       id: request_id,
       error: %{
         code: -32601,
         message: "Method not found",
         data: %{
           name: unknown_tool
         }
       }
     }}
  end
end
