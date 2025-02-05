defmodule MCPSse.MixProject do
  use Mix.Project

  @version "0.1.3"
  @source_url "https://github.com/kend/mcp_sse"

  def project do
    [
      app: :mcp_sse,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Hex
      description: "Server-Sent Events (SSE) implementation of the Model Context Protocol (MCP)",
      package: package(),

      # Docs
      name: "MCP SSE",
      docs: docs(),
      source_url: @source_url
    ]
  end

  defp package do
    [
      maintainers: ["Ken Barker"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "MCP Protocol" => "https://modelcontextprotocol.io/introduction"
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MCP.SSE, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.14"},
      {:plug_cowboy, "~> 2.6", only: :test},

      # Documentation
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  # Specify which paths to compile per environment
  defp elixirc_paths(:dev), do: ["lib", "dev"]
  defp elixirc_paths(_), do: ["lib"]
end
