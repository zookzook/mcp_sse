# Start the MCPSse application
{:ok, _} = MCPSse.start()

# Create a supervision tree for our example server
children = [
  MCPSse.Example.Server
]

# Start the supervisor
{:ok, _sup_pid} = Supervisor.start_link(children, strategy: :one_for_one)

# Print some helpful information
IO.puts("\nServer running at http://localhost:4000")
IO.puts("Press Ctrl+C to stop\n")

# Keep the script running by waiting on the supervisor
Process.sleep(:infinity)
