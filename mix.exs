defmodule MCPSse.MixProject do
  use Mix.Project

  def project do
    [
      app: :mcp_sse,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MCPSse.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.14"},
      {:plug_cowboy, "~> 2.6", only: :test}
    ]
  end
end
