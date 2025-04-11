defmodule MCP.SSE.JsonRpcValidatorTest do
  use ExUnit.Case, async: true

  alias MCP.Test.JsonRpcSchema

  describe "JSON-RPC schema resolution" do
    test "resolves result schema" do
      assert ExJsonSchema.Schema.resolve(JsonRpcSchema.result_schema())
    end

    test "resolves error schema" do
      assert ExJsonSchema.Schema.resolve(JsonRpcSchema.error_schema())
    end
  end

  describe "JSON-RPC schema validation" do
    test "accepts a valid result" do
      result = %{
        jsonrpc: "2.0",
        id: "test-123",
        result: %{
          data: "some result data"
        }
      }

      assert JsonRpcSchema.valid?(JsonRpcSchema.result_schema(), result)
    end

    test "accepts a valid error" do
      error = %{
        jsonrpc: "2.0",
        id: "test-123",
        error: %{
          code: -32601,
          message: "Method not found",
          data: %{
            name: "unsupported_method"
          }
        }
      }

      assert JsonRpcSchema.valid?(JsonRpcSchema.error_schema(), error)
    end

    test "rejects a result with a missing jsonrpc version" do
      result = %{
        id: "test-123",
        result: %{
          data: "some result data"
        }
      }

      refute JsonRpcSchema.valid?(JsonRpcSchema.result_schema(), result)
    end

    test "rejects a result with an incorrect jsonrpc version" do
      result = %{
        jsonrpc: "1.0",
        id: "test-123",
        result: %{
          data: "some result data"
        }
      }

      refute JsonRpcSchema.valid?(JsonRpcSchema.result_schema(), result)
    end

    test "rejects a result with a missing id" do
      result = %{
        jsonrpc: "2.0",
        result: %{
          data: "some result data"
        }
      }

      refute JsonRpcSchema.valid?(JsonRpcSchema.result_schema(), result)
    end

    test "accepts a result with a nil id" do
      result = %{
        jsonrpc: "2.0",
        id: nil,
        result: %{
          data: "some result data"
        }
      }

      assert JsonRpcSchema.valid?(JsonRpcSchema.result_schema(), result)
    end

    test "rejects an error with missing required fields" do
      error = %{
        jsonrpc: "2.0",
        id: "test-123",
        error: %{
          code: -32601
        }
      }

      refute JsonRpcSchema.valid?(JsonRpcSchema.error_schema(), error)
    end

    test "rejects a response with both result and error" do
      response = %{
        jsonrpc: "2.0",
        id: "test-123",
        result: %{
          data: "some data"
        },
        error: %{
          code: -32601,
          message: "Method not found"
        }
      }

      refute JsonRpcSchema.valid?(JsonRpcSchema.result_schema(), response)
      refute JsonRpcSchema.valid?(JsonRpcSchema.error_schema(), response)
    end
  end
end
