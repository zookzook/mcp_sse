# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.5] - 2025-04-11
### Added
- CI/CD work h/t @trubesv
- JSON RPC response testing h/t @trubesv
- pre-commit hooks and documentation cleanup h/t @trubesv

## [0.1.4] - 2025-04-08
### Changed
- Added missing message routing for MCP servers h/t @trubesv

## [0.1.3] - 2025-02-05
### Added
- Added configuration option for SSE keepalive timeout
- Support for disabling keepalive pings by setting `:sse_keepalive_timeout` to `:infinity`

## [0.1.2] - 2025-02-05
### Fixed
- Fixed connection cleanup when SSE connection is closed before initialization
- Added proper cleanup of ConnectionState process on connection close
- Improved error handling for connection registry lookups

## [0.1.1] - 2025-02-04
### Changed
- Fixed application configuration key from `:sse_demo` to `:mcp_sse`
- Improved documentation and examples
- Moved example server to dev-only compilation

### Added
- Added proper Hex.pm package configuration
- Added documentation for Hex.pm
- Added CHANGELOG.md

## [0.1.0] - 2025-02-03
### Added
- Initial release
- Basic MCP over SSE implementation
- Support for Phoenix and Plug applications
- Built-in connection management
- Default MCP server implementation
- Example server for development
- Full MCP support including:
  - Connection initialization
  - Tool registration and execution
  - Automatic ping/keepalive
  - Error handling
  - Session management

[0.1.5]: https://github.com/kend/mcp_sse/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/kend/mcp_sse/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/kend/mcp_sse/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/kend/mcp_sse/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/kend/mcp_sse/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/kend/mcp_sse/releases/tag/v0.1.0
