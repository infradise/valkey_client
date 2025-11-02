# Changelog

## 1.0.0

**🎉 First Production-Ready Stable Release (Standalone/Sentinel) 🎉**

This release marks the first stable version of `valkey_client` suitable for production use in Standalone and Sentinel environments. All core data types, transactions, and Pub/Sub features are implemented and tested.

### Changed
* **Production-Ready Cleanup:** Removed all internal debug `print` statements.
* **Error Handling:** Replaced standard `Exceptions` with specific exception classes (`ValkeyConnectionException`, `ValkeyServerException`, `ValkeyClientException`, `ValkeyParsingException`) for robust error handling.
* **Logging:** Added an internal lightweight logger (via `ValkeyClient.setLogLevel(ValkeyLogLevel)`) instead of requiring `package:logging`. (Logging is `OFF` by default).

### Fixed
* **Test Suite:** Corrected several tests (e.g., `WRONGTYPE`, `EXECABORT`) to correctly expect the new specific exception types (`ValkeyServerException`).
* **Lints:** Addressed `constant_identifier_names` lint for `ValkeyLogLevel` via `analysis_options.yaml`.

### Documentation
* **README.md:** Updated to reflect `v1.0.0` status. Added an **Important Note** regarding the lack of built-in connection pooling and recommending `package:pool`.
* **API Reference:** Added comprehensive Dart Doc comments for all public classes and methods in `valkey_client_base.dart` and `exceptions.dart`.


## 0.12.0

### Added
- **New Commands (Pub/Sub Introspection):** Added commands to inspect the Pub/Sub system state. These commands *do not* require the client to be in Pub/Sub mode.
  - `client.pubsubChannels([pattern])`: Lists active channels.
  - `client.pubsubNumSub(channels)`: Returns a `Map` of channels and their subscriber counts.
  - `client.pubsubNumPat()`: Returns the total number of pattern subscriptions.


## 0.11.0

### Added
- **Transactions:** Implemented basic transaction support.
  - `client.multi()`: Marks the start of a transaction block.
  - `client.exec()`: Executes all queued commands and returns their replies as a `List<dynamic>?`.
  - `client.discard()`: Flushes all commands queued in a transaction.
- **Client State:** The client now tracks transaction state (`_isInTransaction`). Most commands sent during this state will return `+QUEUED` (which the client now handles).


## 0.10.0

### Added
- **Advanced Pub/Sub:** Completed the core Pub/Sub feature set.
  - `client.unsubscribe()`: Unsubscribes from specific channels or all channels.
  - `client.psubscribe()`: Subscribes to patterns, returning a `Subscription` object.
  - `client.punsubscribe()`: Unsubscribes from specific patterns or all patterns.
- **`pmessage` Handling:** The client now correctly parses and emits `pmessage` (pattern message) events via the `ValkeyMessage` stream (with `pattern` field populated).
- **State Management:** Improved internal state management (`_isInPubSubMode`, `_resetPubSubState`) for handling mixed and multiple subscription/unsubscription scenarios.

### Fixed
- **Critical Pub/Sub Hang:** Fixed a complex bug where `await unsubscribe()` or `await punsubscribe()` would hang (timeout).
  - **Root Cause:** `SUBSCRIBE` and `PSUBSCRIBE` commands were incorrectly leaving their command `Completer`s in the `_responseQueue`.
  - **Symptom:** This caused the queue to become desynchronized, and subsequent `unsubscribe`/`punsubscribe` calls would process the stale `Completer` instead of their own, leading to an infinite wait.
- **Logic Refactor:** The `execute` method is now corrected to **not** add `Completer`s to the `_responseQueue` for any Pub/Sub management commands (`SUBSCRIBE`, `PSUBSCRIBE`, `UNSUBSCRIBE`, `PUNSUBSCRIBE`), as their futures are managed separately (e.g., `Subscription.ready` or the `Future<void>` returned by `unsubscribe`).


## 0.9.1

**Note:** This is the first version published to `pub.dev` with basic Pub/Sub support. Version 0.9.0 was unpublished due to bugs.

### Fixed

* **Critical Pub/Sub Bug:** Fixed the issue where the client would stop receiving Pub/Sub messages after the initial subscription confirmation, causing tests to time out. The root cause involved the handling of the `SUBSCRIBE` command's `Completer` interfering with the `StreamSubscription`.
* **Parser Logic:** Improved the internal parser logic (`_processBuffer`) to more reliably distinguish between Pub/Sub push messages and regular command responses, especially while in the subscribed state.
* **Test Logic:** Corrected the authentication failure test (`should throw an Exception when providing auth...`) to expect the actual error message returned by the server (`ERR AUTH...`) instead of a custom one.

### Changed
* **Pub/Sub Example:** Updated the Pub/Sub example (`example/valkey_client_example.dart`) to reflect the correct usage with the new `Subscription` object (including `await sub.ready`).


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

