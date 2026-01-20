# Changelog

## 2.4.1
* **Built-in Logger**
    * **New Feature**: `setEnableValkeyLog()` in `ValkeyLogger`
    * **Example Update**: `built_in_logger_example.dart`
* **Currently Connected Host and Port Information Provider**
    * **New Feature**: `currentConnectionConfig` to get `ValkeyConnectionSettings` in `ValkeyClient`
    * **New Example:** `get_currently_connected_host_info.dart`

## 2.4.0

* **Built-in Logger**
    * Exposed the `built-in logger` functionality for external use.
    * **New Example:** `built_in_logger_example.dart`

## 2.3.0

* **Linter**: Applied strict linter rules project-wide.

## 2.2.0

### Added
- **Replica Read & Load Balancing:** Introduced `ReadPreference` (Master, PreferReplica, ReplicaOnly) to intelligently scale out read operations to replica nodes.
    - `master`: Always read from master (default).
    - `preferReplica`: Read from replicas if available, otherwise fall back to master.
    - `replicaOnly`: Enforce reading only from replicas.
- **Load Balancing Strategies:** Added `LoadBalancingStrategy` (RoundRobin, Random) for distributing read traffic among replicas.
    - `roundRobin`: Distribute requests sequentially.
    - `random`: Select a replica randomly.
- **Replica Discovery:** Added automatic discovery of replica nodes using `INFO REPLICATION` command in Standalone/Sentinel modes.
- **Config Updates:** Updated `ValkeyConnectionSettings` to include `readPreference` and `loadBalancingStrategy` parameters.
- **Explicit Replica Configuration**: Added `explicitReplicas` to `ValkeyConnectionSettings` to manually define replica nodes, solving connectivity issues in some environments (e.g., Docker/NAT) where auto-discovery fails.


## 2.1.0

### Added
- **Database Selection Support:** Added `database` parameter to `ValkeyConnectionSettings` and `ValkeyClient` constructors to automatically `SELECT` a database upon connection.
- **Server Metadata API:** Introduced `client.metadata` property and `ServerMetadata` class to expose server information:
    - `serverName`: Detects 'valkey' or 'redis'.
    - `version`: Server version string.
    - `mode`: Running mode (standalone, cluster, sentinel).
    - `maxDatabases`: The maximum number of available databases.
- **Valkey 9.0+ Compatibility:** Implemented logic to detect `cluster-databases` config, enabling support for **Numbered Clusters** (multiple databases in cluster mode) specific to Valkey 9.0+.


## 2.0.0

### Added
- **Enterprise SSL/TLS Support:** Implemented full support for encrypted connections (`SecureSocket`) across Standalone, Pool, and Cluster clients.
    - **Configuration:** Added `useSsl`, `sslContext`, and `onBadCertificate` options to `ValkeyConnectionSettings`.
    - **Cloud Ready:** Fully compatible with managed services requiring TLS (AWS ElastiCache, Azure Cache for Redis, GCP Memorystore).
    - **Dev Friendly:** Supports self-signed certificates via the `onBadCertificate` callback for local development.


## 1.8.0

### Added
- **Automatic Cluster Failover:** Implemented topology refresh and retry logic on connection failures. The client now automatically detects dead nodes, updates the cluster map, and redirects commands to the new master node, ensuring high availability during server outages.


## 1.7.0

### Added
- **Connection Pool Hardening (Smart Release):** `ValkeyPool` now automatically detects and discards "dirty" connections (e.g., inside a Transaction or Pub/Sub mode) or closed connections upon release. This prevents pool pollution and ensures that acquired connections are always clean and ready for use.
- **Enhanced Developer Experience:** Expanded `Redis` aliases in `redis_client.dart`. Added aliases for Exceptions (`RedisException`, `RedisConnectionException`, etc.), Configuration (`RedisConnectionSettings`), and Data Models (`RedisMessage`), allowing for a seamless migration from other Redis clients.
- **Robust Resource Management:** Implemented strict ownership tracking within `ValkeyPool` to prevent resource leaks and ensure thread safety. `release()` and `discard()` are now idempotent and safe to call multiple times.
- **Client Introspection:** `ValkeyClient` now exposes `isStateful` and `isConnected` properties, which support the new smart pooling logic and allow for custom connection management.


## 1.6.0

### Added
- **Sharded Pub/Sub Support:** Implemented `SPUBLISH`, `SSUBSCRIBE`, and `SUNSUBSCRIBE`.
  - Enables high-performance messaging in Cluster mode by routing messages only to specific shards instead of broadcasting to all nodes.
  - Fully compatible with Redis 7.0+ and Valkey 9.0+.
- **Atomic Counters:** Added `INCR`, `DECR`, `INCRBY`, and `DECRBY` commands for atomic integer operations.
- **Connection Helper:** Added `ECHO` command support.
- **Subscription Enhancements:** The `Subscription` object now has an `.unsubscribe()` method, allowing easier lifecycle management directly from the subscription instance.

### Changed
- **Internal Parser:** Updated the RESP parser to handle `smessage`, `ssubscribe`, and `sunsubscribe` push message types.


## 1.5.0

### Added
- **High Availability & Resilience:** Implemented transparent handling for Cluster Redirections (`-MOVED` and `-ASK`).
  - The client now automatically retries commands on the correct node when a slot migration or failover occurs.
  - **`-MOVED` Handling:** Automatically updates the internal `ClusterSlotMap` and redirects the request to the new master.
  - **`-ASK` Handling:** Successfully handles temporary slot migrations by sending `ASKING` commands to the target node.
- **Developer Experience:** Added `RedisClient` alias. You can now use `RedisClient` interchangeably with `ValkeyClient` for a familiar development experience.
- **Configuration:** Added `maxRedirects` parameter to `ValkeyClusterClient` (default: `5`) to control the maximum number of retries before throwing an exception.
- **Inspection Helper:** Added `getMasterFor(key)` method to retrieve the `ClusterNodeInfo` currently responsible for a specific key. This is useful for debugging topology changes.

### Changed
- **Robustness:** `ValkeyClusterClient` no longer fails immediately upon encountering topology changes but attempts to recover using the new redirection logic.


## 1.4.0

### Added
- **Multi-key Command Support (MGET):** Implemented `mget` support for `ValkeyClusterClient`.
  - **Core Update:** Updated `ValkeyClusterClient` to handle multi-key operations gracefully.
  - **Strategy:** Uses a **Scatter-Gather** strategy to group keys by node.
  - **Performance:** Utilizes **Pipelining** (sending multiple `GET` commands concurrently) instead of a single `MGET` to avoid `CROSSSLOT` errors while maintaining high performance.
  - **Ordering:** Correctly re-assembles results in the requested order.

### Fixed
- **Logging:** Removed the unintended forced logging (`INFO` level) during cluster NAT detection. The client now correctly respects the user's globally configured log level.


## 1.3.0

### Added
- **Cluster Client (v1.3.0):** Introduced the new `ValkeyClusterClient` for automatic command routing in cluster mode.
  - This cluster-aware client fetches the topology using `clusterSlots()` during the `connect()` call.
  - Automatically detects NAT/Docker environments by comparing the initial connection IPs with `CLUSTER SLOTS` response, enabling correct routing without manual configuration. 
  - Fetches topology using `clusterSlots()` on `connect()`.
  - Manages internal `ValkeyPool`s for each discovered master node.
  - Automatically routes single-key commands (`GET`, `SET`, `HSET`, etc.) to the correct node using the `getHashSlot` calculator.
- **`ValkeyCommandsBase`:** Created a new base interface (`lib/valkey_commands_base.dart`) to abstract common data commands, preventing code duplication between `ValkeyClientBase` and `ValkeyClusterClientBase`.
- **Internal (Hash Slot):** Added a dependency-free hash slot calculator (`lib/src/cluster_hash.dart`) implementing CRC-16/XMODEM.
- **Internal (Slot Map):** Added `ClusterSlotMap` (`lib/src/cluster_slot_map.dart`) to manage the mapping of slots to nodes efficiently.
- **Example (Cluster):** Added `example/cluster_client_example.dart` to demonstrate `ValkeyClusterClient` usage and its auto-NAT routing.
- **Testing (Cluster):** 
  - Added `test/cluster_hash_test.dart` for validating the CRC-16 hash slot calculator.
  - Added `test/valkey_cluster_client_test.dart` for integration testing of the new cluster client.

### Fixed
- **Critical `ValkeyClient` Hang (IPv6):** Fixed a bug in `ValkeyClient.connect` where connecting to `127.0.0.1` on macOS/Windows could hang indefinitely by attempting an IPv6 connection (`::1`) first. The client now forces `InternetAddress.loopbackIPv4` for loopback addresses.
- **Critical `ValkeyClusterClient` Routing Bug:** Fixed a bug where the client's NAT auto-detection logic (`_hostMap`) was not being used consistently, causing connection pools to be created with incorrect (internal) IPs.

### Known Limitations
- **`MGET`:** The `mget` command (defined in `ValkeyCommandsBase`) is **not** implemented in `ValkeyClusterClient` in this version and will throw an `UnimplementedError`. Multi-key scatter-gather operations are planned for **v1.4.0**.
- **`Transactions` & `Pub/Sub`:** Cluster-aware Transactions (which require multi-node coordination) and Sharded Pub/Sub (`SSUBSCRIBE`, `SPUBLISH`) are not implemented *in this version*. Sharded Pub/Sub is planned for **v1.6.0** as part of the v2.0.0 cluster roadmap.


## 1.2.0

### Added
- **Cluster Auto-Discovery (Foundation):** Implemented the `client.clusterSlots()` command. This is the first step towards full cluster support (v2.0.0), allowing the client to fetch the cluster's slot topology.
- **New Cluster Models:** Added `ClusterNodeInfo` and `ClusterSlotRange` (in `lib/src/cluster_info.dart`) to represent the parsed slot map returned by the server.
- **Internal (Parser):** Added a new, testable, top-level function `parseClusterSlotsResponse` (in `lib/src/cluster_slots_parser.dart`) to handle the complex `CLUSTER SLOTS` array response, respecting the `avoid_classes_with_only_static_members` lint rule.

### Fixed
- **Critical Hang Bug (Command Timeout):** Fixed a critical bug where the client would hang indefinitely if the server did not send a response (e.g., a standalone server receiving the `CLUSTER SLOTS` command).
- **`commandTimeout` Implementation:**
  - Added a `commandTimeout` (default 10s) property to `ValkeyConnectionSettings` and the `ValkeyClient` constructor.
  - `ValkeyPool` now correctly propagates this setting to newly created clients.
  - The core `execute` method now applies this timeout to all standard commands, throwing a `ValkeyClientException` on timeout.
- **Queue Desync Prevention:** The `onTimeout` handler now correctly removes the stale `Completer` from the `_responseQueue`, preventing potential desynchronization issues on late responses.

### Documentation
- **New Example:** Added `example/cluster_auto_discovery_example.dart` to demonstrate the usage of the new `clusterSlots()` command and its correct timeout behavior when run against a standalone (non-cluster) server.


## 1.1.0

### Added
- **Built-in Connection Pooling:** Implemented `ValkeyPool` for efficient, high-concurrency connection management.
  - Includes `pool.acquire()` and `pool.release()` methods.
  - Automatically handles connection creation up to `maxConnections`.
  - Implemented a wait queue for requests when the pool is full.
  - Added health checks (`PING`) on `acquire` to discard unhealthy connections.
- **`ValkeyConnectionSettings`:** Added a class to hold connection parameters for the pool.

### Fixed
- Fixed a bug in the pool's `release()` logic where unhealthy (closed) clients were incorrectly returned to the pool, causing errors on reuse.


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

