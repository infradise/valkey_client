# Changelog

## 0.4.0

### Added
- **Upgraded RESP Parser:** Implemented a full recursive parser.
  - The parser now supports **Arrays (`*`)**, completing the core RESP implementation.
- **New Command:** Added `client.mget()` (Multiple GET) which relies on the new array parser.
- **Internal:** Refactored the parser logic into a `_BufferReader` for cleaner, more robust parsing.

## 0.3.0

### Added
- **New Commands:** Added `client.set()` and `client.get()` methods.
- **Upgraded RESP Parser:** The internal parser now supports **Bulk Strings (`$`)**.
- This enables handling standard string values (e.g., `GET mykey`) and `null` replies (e.g., `GET non_existent_key`).

## 0.2.0

### Added
- **Command Execution Pipeline:** Implemented the core `execute` method to send commands and process responses via a queue.
- **PING Command:** Added the first user-facing command: `client.ping()`.
- **Basic RESP Parser:** Added an internal parser to handle simple string (`+`) and error (`-`) responses, preparing for full RESP3 support.

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

