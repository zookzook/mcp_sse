defmodule MCP.DefaultServerTest do
  use ExUnit.Case, async: true
  require Logger
  import ExUnit.CaptureLog

  alias MCP.DefaultServer
  alias MCP.Test.JsonRpcSchema

  @protocol_version "2024-11-05"

  describe "handle_ping/1" do
    test "returns pong response" do
      request_id = "ping-1"

      assert {:ok, response} = DefaultServer.handle_ping(%{}, request_id)
      assert JsonRpcSchema.valid?(JsonRpcSchema.result_schema(), response)

      assert response.jsonrpc == "2.0"
      assert response.id == request_id
      assert response.result == %{}
    end
  end

  describe "handle_initialize/2" do
    test "accepts valid protocol version" do
      request_id = "init-1"

      params = %{
        "protocolVersion" => @protocol_version,
        "capabilities" => %{
          "version" => "1.0"
        }
      }

      assert {:ok, response} = DefaultServer.handle_initialize(%{}, request_id, params)
      assert JsonRpcSchema.valid?(JsonRpcSchema.result_schema(), response)

      assert response.jsonrpc == "2.0"
      assert response.id == request_id
      assert response.result.protocolVersion == @protocol_version
      assert response.result.capabilities.tools.listChanged == true
      assert response.result.serverInfo.name == "SSE Demo MCP Server"
      assert response.result.serverInfo.version == "0.1.0"
    end

    test "rejects invalid protocol version" do
      request_id = "init-2"

      params = %{
        "protocolVersion" => "invalid-version",
        "capabilities" => %{
          "version" => "1.0"
        }
      }

      assert {:error, reason} = DefaultServer.handle_initialize(%{}, request_id, params)
      assert reason =~ "Unsupported protocol version"
    end

    test "requires protocol version" do
      request_id = "init-3"

      params = %{
        "capabilities" => %{
          "version" => "1.0"
        }
      }

      assert {:error, reason} = DefaultServer.handle_initialize(%{}, request_id, params)
      assert reason == "Protocol version is required"
    end
  end

  describe "handle_list_tools/2" do
    test "returns list of available tools" do
      request_id = "tools-1"
      params = %{}

      assert {:ok, response} = DefaultServer.handle_list_tools(%{}, request_id, params)
      assert JsonRpcSchema.valid?(JsonRpcSchema.result_schema(), response)

      assert response.jsonrpc == "2.0"
      assert response.id == request_id

      [tool] = response.result.tools

      assert tool.name == "upcase"
      assert tool.description == "Converts text to uppercase"
      assert tool.inputSchema.required == ["text"]
      assert tool.outputSchema.required == ["output"]
    end
  end

  describe "handle_call_tool/2" do
    test "handles upcase tool correctly" do
      request_id = "tool-1"

      params = %{
        "name" => "upcase",
        "arguments" => %{
          "text" => "hello world"
        }
      }

      assert {:ok, response} = DefaultServer.handle_call_tool(%{}, request_id, params)
      assert JsonRpcSchema.valid?(JsonRpcSchema.result_schema(), response)

      assert response.jsonrpc == "2.0"
      assert response.id == request_id

      [content] = response.result.content

      assert content.type == "text"
      assert content.text == "HELLO WORLD"
    end

    test "handles unknown tool" do
      request_id = "tool-2"

      params = %{
        "name" => "unknown_tool",
        "arguments" => %{}
      }

      log =
        capture_log(fn ->
          assert {:error, response} = DefaultServer.handle_call_tool(%{}, request_id, params)
          assert JsonRpcSchema.valid?(JsonRpcSchema.error_schema(), response)

          assert response.jsonrpc == "2.0"
          assert response.id == request_id
          assert response.error.code == -32601
          assert response.error.message == "Method not found"
          assert response.error.data.name == "unknown_tool"
        end)

      assert log =~ "Unknown tool called: unknown_tool"
    end
  end
end
