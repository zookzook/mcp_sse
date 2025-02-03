defmodule MCPSse.Application do
  @moduledoc """
  Provides the OTP Application behaviour for MCPSse.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SSE.ConnectionRegistry
    ]

    opts = [strategy: :one_for_one, name: MCPSse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
