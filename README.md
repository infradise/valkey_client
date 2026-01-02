[![pub package](https://img.shields.io/pub/v/valkey_client.svg)](https://pub.dev/packages/valkey_client)

# valkey_client ⚡

The `valkey_client` is a high-performance, cluster-aware Dart client for Redis and Valkey.

## Overview
- Deployment modes: Standalone; Sentinel; Cluster
- Reliability: Automatic failover; smart connection pooling
- Messaging: Sharded Pub/Sub for scalable messaging
- Operations: Multi-key operations; configurable command timeouts
- Protocol: RESP3 parsing with type-safe exceptions
- Observability: Built-in logging
- Security: SSL/TLS support
- Valkey 9.0+ Support
  - Numbered clusters: Intelligent database selection for seamless cluster management

## Helpers

👉 To browse Redis/Valkey data, you can use [Keyscope](https://plugins.jetbrains.com/plugin/29250-keyscope), a native Redis/Valkey IDE to edit key-value data in your databases.  
👉 To access Redis/Valkey servers on Kubernetes, you can use [Visualkube Jet](https://plugins.jetbrains.com/plugin/29143-visualkube-jet), a native Kubernetes IDE for multi‑cluster access and real-time watch.

> **Keyscope** and **Visualkube Jet** are plugins for Android Studio and JetBrains IDEs.

## Features
  * **Smart Database Selection (v2.1.0+):** First-class support for selecting databases (0-15+) on connection. Automatically detects **Valkey 9.0+ Numbered Clusters** to enable multi-database support in cluster mode, while maintaining backward compatibility with Redis Clusters (DB 0 only).
  * **Server Metadata Discovery (v2.1.0+):** Access server details via `client.metadata` (Version, Mode, Server Name, Max Databases) to write adaptive logic for Valkey vs. Redis.
  * **Enterprise Security (v2.0.0+):** Native SSL/TLS support for secure communication. Fully compatible with major cloud providers (AWS, Azure, GCP) and supports custom security contexts (including self-signed certificates).
  * **Automatic Failover:** The client now survives node failures. If a master node goes down (connection refused/timeout), the client automatically refreshes the cluster topology and reroutes commands to the new master without throwing an exception.
  * **Connection Pool Hardening:** Implemented **Smart Release** mechanism. The pool automatically detects and discards "dirty" connections (e.g., inside Transaction or Pub/Sub) upon release, preventing pool pollution and resource leaks.
  * **Enhanced Developer Experience:** Expanded `Redis` aliases to include Exceptions, Configuration, and Data Models (`RedisException`, `RedisMessage`, etc.) for a seamless migration experience.
  * **Sharded Pub/Sub & Atomic Counters:** Added support for high-performance cluster messaging (`SPUBLISH`/`SSUBSCRIBE`) and atomic integer operations (`INCR`/`DECR`).
  * **Developer Experience:** Added `RedisClient` alias and smart redirection handling for better usability and stability.
  * **High Availability & Resilience:** Automatically and transparently handles cluster topology changes (`-MOVED` and `-ASK` redirections) to ensure robust failover, seamless scaling, and zero‑downtime operations.
  * **Multi-key Support:** Supports `MGET` across multiple nodes using smart Scatter-Gather pipelining.
  * **Cluster Client:** Added `ValkeyClusterClient` for automatic command routing in cluster mode.
      * This client automatically routes commands to the correct node.
      * We recommend using `ValkeyClient` for Standalone/Sentinel and `ValkeyClusterClient` for cluster environments.
  * **Built-in Connection Pooling:** `ValkeyPool` for efficient connection management (used by Standalone and Cluster clients).
  * **Cluster Auto-Discovery:** Added `client.clusterSlots()` to fetch cluster topology (via the `CLUSTER SLOTS` command), laying the foundation for full cluster support.
  * **Command Timeout:** Includes a built-in command timeout (via `ValkeyConnectionSettings`) to prevent client hangs on non-responsive servers.
  * **Robust Parsing:** Full RESP3 parser handling all core data types (`+`, `-`, `$`, `*`, `:`).
  * **Type-Safe Exceptions:** Clear distinction between connection errors (`ValkeyConnectionException`), server errors (`ValkeyServerException`), and client errors (`ValkeyClientException`).
  * **Pub/Sub Ready (Standalone/Sentinel):** `subscribe()` returns a `Subscription` object with a `Stream` and a `Future<void> ready` for easy and reliable message handling.
  * **Production-Ready (Standalone/Sentinel):** stable for production use in non-clustered environments.
  * **Production-Ready (Cluster):** stable for production use with full cluster support.

## Command Support
  * **Connection** (`PING`, `ECHO`, `QUIT` via `close()`)
  * **Cluster** (`CLUSTER SLOTS`, `ASKING`)
  * **Strings** (`GET`, `SET`, `MGET`, `INCR`, `DECR`, `INCRBY`, `DECRBY`)
  * **Hashes** (`HSET`, `HGET`, `HGETALL`)
  * **Lists** (`LPUSH`, `RPUSH`, `LPOP`, `RPOP`, `LRANGE`)
  * **Sets** (`SADD`, `SREM`, `SMEMBERS`)
  * **Sorted Sets** (`ZADD`, `ZREM`, `ZRANGE`)
  * **Key Management** (`DEL`, `EXISTS`, `EXPIRE`, `TTL`)
  * **Transactions** (`MULTI`, `EXEC`, `DISCARD`)
  * **Full Pub/Sub** (`PUBLISH`, `SUBSCRIBE`, `UNSUBSCRIBE`, `PSUBSCRIBE`, `PUNSUBSCRIBE`)
  * **Pub/Sub Introspection** (`PUBSUB CHANNELS`, `PUBSUB NUMSUB`, `PUBSUB NUMPAT`)
  * **Sharded Pub/Sub** (`SPUBLISH`, `SSUBSCRIBE`, `SUNSUBSCRIBE`) for efficient cluster messaging.

## Developer Experience Improvements

To enhance DX for both Redis and Valkey developers, we provide fully compatible aliases. You can use the class names you are most comfortable with.

- For instance, `RedisClient` is available as an alias of `ValkeyClient` to enhance developer experience (DX).
- Both classes and helper functions are fully compatible — choose whichever name feels natural for your project.

### Clients

| Role | Redis Alias | Valkey Class | Description |
| :--- | :--- | :--- | :--- |
| **Client** | `RedisClient` | `ValkeyClient` | Standard client for Standalone or Sentinel connections. |
| **Cluster** | `RedisClusterClient` | `ValkeyClusterClient` | Auto-routing client for Cluster environments. |
| **Pooling** | `RedisPool` | `ValkeyPool` | Manages connection pools for high-concurrency apps. |

### Configuration

| Role | Redis Alias | Valkey Class | Description |
| :--- | :--- | :--- | :--- |
| **Settings** | `RedisConnectionSettings` | `ValkeyConnectionSettings` | Configuration for host, port, password, and timeout. |
| **Logging** | `RedisLogLevel` | `ValkeyLogLevel` | Logging levels (info, warning, severe, off). |

### Data Models

| Role | Redis Alias | Valkey Class | Description |
| :--- | :--- | :--- | :--- |
| **Message** | `RedisMessage` | `ValkeyMessage` | Represents a message received via Pub/Sub. |

### Exceptions (Crucial for try-catch blocks)

| Role | Redis Alias | Valkey Class | Description |
| :--- | :--- | :--- | :--- |
| **Base Error** | `RedisException` | `ValkeyException` | The base class for all package-related exceptions. |
| **Network** | `RedisConnectionException` | `ValkeyConnectionException` | Thrown when connection fails or drops. |
| **Server** | `RedisServerException` | `ValkeyServerException` | Thrown when the server returns an error (e.g., `-ERR`). |
| **Usage** | `RedisClientException` | `ValkeyClientException` | Thrown on invalid client usage (e.g., misuse of API). |
| **Parsing** | `RedisParsingException` | `ValkeyParsingException` | Thrown when the response cannot be parsed (RESP3). |


## Usage

Refer to the [Wiki](https://github.com/infradise/valkey_client/wiki) page in our GitHub repository to see more examples.

### 1\. Example for Standalone or Sentinel environment 

<table>
<tr>
<td>

**`For Redis users`**

```dart
import 'package:valkey_client/redis_client.dart';

void main() async {
  final client = RedisClient();
  try {
    await client.connect(
      host: '127.0.0.1',
      port: 6379
    );
    await client.set('key', 'value');
    print(await client.get('key'));

  } catch (e) {
    print('❌ Failed: $e');
  } finally {
    await client.close();
  }
}
```

</td>
<td>

**`For Valkey users`**

```dart
import 'package:valkey_client/valkey_client.dart';

void main() async {
  final client = ValkeyClient();
  try {
    await client.connect(
      host: '127.0.0.1',
      port: 6379
    );
    await client.set('key', 'value');
    print(await client.get('key'));

  } catch (e) {
    print('❌ Failed: $e');
  } finally {
    await client.close();
  }
}
```

</td>
</tr>
</table>


### 2\. Example for Cluster environment

<table>
<tr>
<td>

**`For Redis users`**

```dart
import 'package:valkey_client/redis_client.dart';

void main() async {

  final nodes = [
    RedisConnectionSettings(
      host: '127.0.0.1',
      port: 7001,
    ),
  ];

  final client = RedisClusterClient(nodes);
  try {
    await client.connect();
    
    await client.set('key', 'value');
    print(await client.get('key'));

  } catch (e) {
    print('❌ Failed: $e');
  } finally {
    await client.close();
  }
}
```

</td>
<td>

**`For Valkey users`**

```dart
import 'package:valkey_client/valkey_client.dart';

void main() async {

  final nodes = [
    ValkeyConnectionSettings(
      host: '127.0.0.1',
      port: 7001,
    ),
  ];

  final client = ValkeyClusterClient(nodes);
  try {
    await client.connect();

    await client.set('key', 'value');
    print(await client.get('key'));

  } catch (e) {
    print('❌ Failed: $e');
  } finally {
    await client.close();
  }
}
```

</td>
</tr>
</table>


