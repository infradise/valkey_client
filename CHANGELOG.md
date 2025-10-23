# Changelog

## 0.1.0

This is the first functional release, implementing the core connection logic.

### Added
- **Core Connection:** Implemented the initial client connection logic.
  - `connect()`: Connects to the Valkey server.
  - `close()`: Closes the connection.
  - `onConnected`: A `Future` that completes when the connection is established.
- **Documentation:**
  - Added public API documentation (`lib/valkey_client.dart`).
  - Added a comprehensive usage example (`example/valkey_client_example.dart`).
- **Testing:**
  - Added unit tests for connection, connection failure, and disconnection scenarios.

## 0.0.1

- Initial version. (Placeholder)

