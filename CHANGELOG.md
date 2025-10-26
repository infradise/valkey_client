# Changelog

## 0.9.0

**Note:** This version was not published to `pub.dev` due to unresolved issues in the Pub/Sub implementation found during testing.

### Added
- **New Commands (Pub/Sub):** Added basic Publish/Subscribe functionality.
  - `client.publish()`: Posts a message to a channel.
  - `client.subscribe()`: Subscribes to channels and returns a `Stream<ValkeyMessage>` for receiving messages.
- **Push Message Handling:** The internal parser and client logic were updated to handle asynchronous push messages (like pub/sub messages) separate from command responses.
- **`ValkeyMessage` Class:** Introduced a class to represent incoming pub/sub messages.

### Known Limitations
- Once subscribed, only `UNSUBSCRIBE`, `PUNSUBSCRIBE`, `PING`, and `QUIT` commands are allowed by Redis/Valkey. The client currently enforces this restriction partially. Full `unsubscribe` logic is not yet implemented.
- Pattern subscription (`PSUBSCRIBE`, `PUNSUBSCRIBE`) is not yet supported.


## 0.8.0

### Added
- **New Commands (Key Management):** Added commands for managing keys.
  - `client.del()`
  - `client.exists()`
  - `client.expire()` (set timeout in seconds)
  - `client.ttl()` (get remaining time to live)
- These commands primarily return `Integer` responses.


## 0.7.0

### Added
- **New Commands (Sets):** Added commands for working with Sets.
  - `client.sadd()` / `client.srem()`
  - `client.smembers()`
- **New Commands (Sorted Sets):** Added commands for working with Sorted Sets (leaderboards).
  - `client.zadd()` / `client.zrem()`
  - `client.zrange()` (by index)
- These commands utilize the existing `Integer`, `Array`, and `Bulk String` parsers.


## 0.6.0

### Added
- **New Commands (Lists):** Added commands for working with Lists.
  - `client.lpush()` / `client.rpush()`
  - `client.lpop()` / `client.rpop()`
  - `client.lrange()`
- These commands utilize the existing `Integer`, `Bulk String`, and `Array` parsers.


## 0.5.0

### Added
- **New Commands (Hashes):** Added `client.hset()`, `client.hget()`, and `client.hgetall()`.
- **Upgraded RESP Parser:** The internal parser now supports **Integers (`:`)**.
- `hset` returns an `int` (`1` for new field, `0` for update).
- `hgetall` conveniently returns a `Map<String, String>`.

### Fixed
- **Critical Auth Bug:** Fixed a bug where `connect()` would time out (hang) if authentication failed (e.g., providing a password to a no-auth server).
- **Test Stability (`FLUSHDB`):** Fixed flaky command tests (like `HSET` returning `0` instead of `1`) by adding `FLUSHDB` to `setUpAll`, ensuring a clean database for each test run.
- **Test Logic:** Fixed the authentication failure test to expect the *actual* server error message (e.g., `ERR AUTH`) instead of a custom one.

### Changed
- **Test Suite:** Refactored the entire test setup (`valkey_client_test.dart`) to use a `checkServerStatus()` helper. This reliably checks server availability *before* defining tests, preventing false skips and cleaning up the test logic.


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

