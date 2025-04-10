// Connect to SSE endpoint
const sse = new EventSource('/sse');

// Handle endpoint message
sse.addEventListener('endpoint', (e) => {
  const messageEndpoint = e.data;
  // Use messageEndpoint for subsequent JSON-RPC requests
});

// Send initialize request
fetch('/message?sessionId=YOUR_SESSION_ID', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    jsonrpc: '2.0',
    id: 1,
    method: 'initialize',
    params: {
      protocolVersion: '2024-11-05',
      capabilities: {}
    }
  })
});