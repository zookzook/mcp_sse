defmodule MCP.MessageRouterTest do
  use ExUnit.Case, async: true
  require Logger
  import ExUnit.CaptureLog

  # Mock MCP Server for testing
  defmodule MockMCPServer do
    @behaviour MCPServer

    @impl true
    def handle_ping(request_id) do
      {:ok, %{jsonrpc: "2.0", id: request_id, result: "pong"}}
    end

    @impl true
    def handle_initialize(request_id, params) do
      capabilities = params["capabilities"]
      {:ok, %{jsonrpc: "2.0", id: request_id, result: %{"capabilities" => capabilities}}}
    end

    @impl true
    def handle_list_tools(request_id, _params) do
      {:ok, %{jsonrpc: "2.0", id: request_id, result: %{tools: []}}}
    end

    @impl true
    def handle_call_tool(request_id, params) do
      {:ok, %{jsonrpc: "2.0", id: request_id, result: %{tool_result: params["name"]}}}
    end
  end

  setup do
    # Configure the mock server for testing
    Application.put_env(:mcp_sse, :mcp_server, MockMCPServer)

    on_exit(fn ->
      # Reset the configuration after each test
      Application.delete_env(:mcp_sse, :mcp_server)
    end)
  end

  describe "handle_message/1" do
    test "handles initialized notification" do
      message = %{
        "method" => "notifications/initialized",
        "jsonrpc" => "2.0"
      }

      assert {:ok, nil} = MCP.MessageRouter.handle_message(message)
    end

    test "handles ping request" do
      message = %{
        "method" => "ping",
        "id" => "123",
        "jsonrpc" => "2.0"
      }

      assert {:ok, response} = MCP.MessageRouter.handle_message(message)
      assert response.id == "123"
      assert response.result == "pong"
    end

    test "handles initialize request" do
      message = %{
        "method" => "initialize",
        "id" => "456",
        "params" => %{
          "capabilities" => %{"version" => "1.0"}
        },
        "jsonrpc" => "2.0"
      }

      assert {:ok, response} = MCP.MessageRouter.handle_message(message)
      assert response.id == "456"
      assert response.result["capabilities"]["version"] == "1.0"
    end

    test "handles tools/list request" do
      message = %{
        "method" => "tools/list",
        "id" => "789",
        "params" => %{},
        "jsonrpc" => "2.0"
      }

      assert {:ok, response} = MCP.MessageRouter.handle_message(message)
      assert response.id == "789"
      assert Map.has_key?(response.result, :tools)
    end

    test "handles tools/call request" do
      message = %{
        "method" => "tools/call",
        "id" => "101",
        "params" => %{
          "name" => "test_tool"
        },
        "jsonrpc" => "2.0"
      }

      assert {:ok, response} = MCP.MessageRouter.handle_message(message)
      assert response.id == "101"
      assert response.result.tool_result == "test_tool"
    end

    test "returns method not found error for unsupported method" do
      message = %{
        "method" => "unsupported_method",
        "id" => "999",
        "jsonrpc" => "2.0"
      }

      log =
        capture_log(fn ->
          assert {:error, response} = MCP.MessageRouter.handle_message(message)
          assert response.id == "999"
          assert response.error.code == -32601
          assert response.error.message == "Method not found"
          assert response.error.data.name == "unsupported_method"
        end)

      assert log =~ "Received unsupported method: unsupported_method"
    end

    test "returns invalid request error for malformed message" do
      message = %{
        "invalid" => "message"
      }

      log =
        capture_log(fn ->
          assert {:error, response} = MCP.MessageRouter.handle_message(message)
          assert response.id == nil
          assert response.error.code == -32600
          assert response.error.message == "Invalid Request"
          assert response.error.data.received == message
        end)

      assert log =~ "Received invalid message format:"
    end
  end
end
