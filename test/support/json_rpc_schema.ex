defmodule MCP.Test.JsonRpcSchema do
  @moduledoc false

  def valid?(schema, data) do
    ExJsonSchema.Validator.valid?(schema, JSON.decode!(JSON.encode!(data)))
  end

  def result_schema do
    %{
      "type" => "object",
      "required" => ["jsonrpc", "id", "result"],
      "properties" => %{
        "jsonrpc" => %{
          "type" => "string",
          "enum" => ["2.0"]
        },
        "id" => %{
          "type" => ["string", "number", "null"]
        },
        "result" => %{
          "type" => "object"
        }
      },
      "not" => %{
        "required" => ["error"]
      }
    }
  end

  def error_schema do
    %{
      "type" => "object",
      "required" => ["jsonrpc", "id", "error"],
      "properties" => %{
        "jsonrpc" => %{
          "type" => "string",
          "enum" => ["2.0"]
        },
        "id" => %{
          "type" => ["string", "number", "null"]
        },
        "error" => %{
          "type" => "object",
          "required" => ["code", "message"],
          "properties" => %{
            "code" => %{
              "type" => "integer"
            },
            "message" => %{
              "type" => "string"
            },
            "data" => %{
              "type" => "object"
            }
          }
        }
      },
      "not" => %{
        "required" => ["result"]
      }
    }
  end
end
