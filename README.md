[![pub package](https://img.shields.io/pub/v/valkey_client.svg)](https://pub.dev/packages/valkey_client)

# Introduction

The `valkey_client` is a smart client for Valkey and Redis, supporting Standalone, Sentinel, and Cluster modes with auto-failover, smart connection pooling, sharded Pub/Sub, multi-key operations, command timeouts, RESP3 parsing, type-safe exceptions, and logger.

## Helpers

👉 To browse Redis/Valkey data, you can use [Keyscope](https://plugins.jetbrains.com/plugin/29250-keyscope), a native Redis/Valkey IDE to edit key-value data in your databases.  
👉 To access Redis/Valkey servers on Kubernetes, you can use [Visualkube Jet](https://plugins.jetbrains.com/plugin/29143-visualkube-jet), a native Kubernetes IDE for multi‑cluster access and real-time watch.

> **Keyscope** and **Visualkube Jet** are plugins for Android Studio and JetBrains IDEs.

## Features
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

## Getting Started

This section describe how to install a `Valkey` or `Redis` Server on your local environment.

### Kubernetes: Local Setup

1. Run [Rancher Desktop](https://rancherdesktop.io/) to set up a local `Kubernetes` cluster.
2. In **Android Studio** or a **JetBrains IDE**:  
   - Go to **Plugin > Visualkube Jet > Cluster Manager**  
   - Connect one or more `Kubernetes` clusters  
   - Navigate to **Helm > Charts**  
   - Search for `redis`, `redis-cluster`, `valkey`, or `valkey-cluster`  
   - Install and choose a target cluster
3. In **Android Studio** or a **JetBrains IDE**:  
   - Go to **Plugin > Keyscope > Cluster Manager**  
   - Add a connection and choose **Standalone**, **Cluster**, or **Sentinel** mode  
   - Double‑click your `myRedis` or `myValkey` server  
   - Double‑click **Database**  
   - Double‑click a **Key type**  
   - Click keys to view their values

### Docker: Local Standalone Setup

This client requires a running `Valkey` or `Redis` server to connect to. For local development and testing, we strongly recommend using Docker.

1.  Install a container environment like [Docker Desktop](https://www.docker.com/products/docker-desktop/).
2.  Start a [Valkey](https://hub.docker.com/r/valkey/valkey) or [Redis](https://hub.docker.com/_/redis) server instance by running one of the following commands in your terminal:

**Option 1: No Authentication (Default)**

```bash
# Valkey (latest, e.g., 9.0.0)
docker run -d --name my-valkey -p 6379:6379 valkey/valkey:latest

# Redis (latest, e.g., 8.2.3)
docker run -d --name my-redis -p 6379:6379 redis:latest
```

**Option 2: With Password Only**
(This sets the password for the `default` user. Use with `username: null` in the client.)

```bash
# Valkey (latest, e.g., 9.0.0)
docker run -d --name my-valkey-auth -p 6379:6379 valkey/valkey:latest \
  --requirepass "my-super-secret-password"

# Redis (latest, e.g., 8.2.3)
docker run -d --name my-redis-auth -p 6379:6379 redis:latest \
  --requirepass "my-super-secret-password"
```

**Option 3: With Username and Password (ACL)**
(This sets the password for the `default` user. Use with `username: 'default'` in the client.)

```bash
# Valkey (latest, e.g., 9.0.0)
docker run -d --name my-valkey-acl -p 6379:6379 valkey/valkey:latest \
  --user default --pass "my-super-secret-password"

# Redis (latest, e.g., 8.2.3)
docker run -d --name my-redis-acl -p 6379:6379 redis:latest \
  --user default --pass "my-super-secret-password"
```

  * Valkey/Redis 6+ uses ACLs. The `default` user exists by default. To create a new user instead, simply change `--user default` to `--user my-user`.

*(Note: The '-d' flag runs the container in "detached" mode (in the background). You can remove it if you want to see the server logs directly in your terminal.)*


### Docker Compose: Local Cluster Setup

The **Usage (Group 3)** examples require a running Valkey Cluster or Redis Cluster.

Setting up a cluster on Docker Desktop (macOS/Windows) is notoriously complex due to the networking required for NAT (mapping internal container IPs to `127.0.0.1`).

To solve this and encourage contributions, the GitHub repository provides a pre-configured, one-command setup file.

**File Location:**

  * [`setup/cluster-mode/prod/valkey_macos.yaml`](https://github.com/infradise/valkey_client/blob/main/setup/cluster-mode/prod/valkey_macos.yaml)
  * [`setup/cluster-mode/prod/redis_macos.yaml`](https://github.com/infradise/valkey_client/blob/main/setup/cluster-mode/prod/redis_macos.yaml)

Each provided YAML file is a Docker Compose configuration that launches a 6-node (3 Master, 3 Replica) cluster. It is already configured to handle all IP announcement (e.g., `--cluster-announce-ip`) and networking challenges automatically.

**How to Run the Cluster:**

1.  Download the `valkey_macos.yaml` or `redis_macos.yaml` file from the repository.
2.  In your terminal, navigate to the file's location.
3.  To start the cluster, run one of the following commands:
    ```sh
    # To start Valkey Cluster
    docker compose -f valkey_macos.yaml up --force-recreate

    # To start Redis Cluster
    docker compose -f redis_macos.yaml up --force-recreate
    ```
4.  Wait for the `cluster-init` service to log `✅ Cluster is stable and all slots are covered!`.

Your 6-node cluster is now running on `127.0.0.1:7001-7006`, and you can successfully run the **Usage (Group 3)** examples.

**Note:** This configuration starts from port `7001` (instead of the common `7000`) because port 7000 is often reserved by the macOS Control Center (AirPlay Receiver) service.


## Developer Experience Improvements

To enhance DX for both Redis and Valkey developers, we provide fully compatible aliases. You can use the class names you are most comfortable with.

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

### Redis

`RedisClient` is available as an alias of `ValkeyClient` to enhance developer experience (DX).

You can use either `ValkeyClient` or `RedisClient`.  
Both classes and helper functions are fully compatible — choose whichever name feels natural for your project.

### Quick Example (RedisClient)

```dart
// You can import RedisClient directly — no need to switch to ValkeyClient.
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

👉 All examples below use ValkeyClient, but you can replace it with RedisClient without any changes.  
**Note**: Not all examples are fully interchangeable yet, but we plan to make them 100% compatible.


### Valkey

`valkey_client` supports **Standalone, Sentinel, and Cluster** environments.
New users are encouraged to start with **Group 1**. Production applications should use **Group 2** (for Standalone/Sentinel) or **Group 3** (for Cluster).



### Group 1: Standalone/Sentinel (Single Connection)

This is the most basic way to connect and run commands using the `ValkeyClient` class. It is recommended for new users, simple tests, and scripts. (See more examples in the **[Example tab](https://pub.dev/packages/valkey_client/example)**.)

#### 1\. Basic: Connection Patterns (from [example/valkey\_client\_example.dart](https://github.com/infradise/valkey_client/blob/main/example/valkey_client_example.dart))

`ValkeyClient` can be configured via its constructor (`fixedClient`) or by passing settings to the `connect()` method (`flexibleClient`).

```dart
// 1. "Fixed Client": Constructor-based configuration
// (Match your server setup from the "Getting Started" section)

// Option 1: No Authentication
final fixedClient = ValkeyClient(host: '127.0.0.1', port: 6379);

// Option 2: Password Only
// final fixedClient = ValkeyClient(host: '127.0.0.1', port: 6379, password: 'my-super-secret-password');

// Option 3: Username + Password (ACL)
// final fixedClient = ValkeyClient(host: '127.0.0.1', port: 6379, username: 'default', password: 'my-super-secret-password');

try {
  await fixedClient.connect();
  print(await fixedClient.ping()); // Output: PONG
} finally {
  await fixedClient.close();
}


// 2. "Flexible Client": Method-based configuration
// This pattern is useful for managing connections dynamically.
final flexibleClient = ValkeyClient(); // No config in constructor
try {
  await flexibleClient.connect(
    host: '127.0.0.1',
    port: 6379,
    // password: 'my-super-secret-password'
  );
  print(await flexibleClient.ping()); // Output: PONG
} finally {
  await flexibleClient.close();
}
```

#### 2\. Standard: Basic Usage (from [example/simple\_example.dart](https://github.com/infradise/valkey_client/blob/main/example/simple_example.dart))

This is the standard `try-catch-finally` structure to handle exceptions and ensure `close()` is always called.

```dart
import 'package:valkey_client/valkey_client.dart';

void main() async {
  final client = ValkeyClient(host: '127.0.0.1', port: 6379);

  try {
    await client.connect();
    
    await client.set('greeting', 'Hello, Valkey!');
    final value = await client.get('greeting');
    print(value); // Output: Hello, Valkey!

  } on ValkeyConnectionException catch (e) {
    print('Connection failed: $e');
  } on ValkeyServerException catch (e) {
    print('Server returned an error: $e');
  } finally {
    // Always close the connection
    await client.close();
  }
}
```

#### Atomic Counters

```dart
// Atomic increment/decrement operations
await client.set('score', '10');
final newScore = await client.incr('score'); // 11
await client.decrBy('score', 5); // 6
```



#### 3\. Application: Pub/Sub (from [example/valkey\_client\_example.dart](https://github.com/infradise/valkey_client/blob/main/example/valkey_client_example.dart))

`ValkeyClient` supports Pub/Sub. `subscribe()` returns a `Subscription` object, and you **must** `await sub.ready` to ensure the subscription is active before publishing.

```dart
  // Use two clients: one to subscribe, one to publish
  final subscriber = ValkeyClient(host: '127.0.0.1', port: 6379);
  final publisher = ValkeyClient(host: '127.0.0.1', port: 6379);
  StreamSubscription<ValkeyMessage>? listener;

  try {
    await Future.wait([subscriber.connect(), publisher.connect()]);
    
    final channel = 'news:updates';

    // 1. Subscribe and get the Subscription object
    final sub = subscriber.subscribe([channel]);
    
    // 2. MUST await sub.ready before publishing
    print('Waiting for subscription confirmation...');
    await sub.ready.timeout(Duration(seconds: 2));
    print('Subscription confirmed!');

    // 3. Listen to the message stream
    listener = sub.messages.listen((message) {
      print('📬 Received: ${message.message} (from channel: ${message.channel})');
    });

    // 4. Publish messages
    await publisher.publish(channel, 'valkey_client v2.0.0 has been released!');

    await Future.delayed(Duration(seconds: 1)); // Wait to receive message

  } catch (e) {
    print('❌ Pub/Sub Example Failed: $e');
  } finally {
    await listener?.cancel();
    await Future.wait([subscriber.close(), publisher.close()]);
    print('Pub/Sub clients closed.');
  }
```



### Group 2: Production Pool (Standalone/Sentinel)

#### Connection Pooling

For all applications — and especially for **production server environments** with high concurrency — it is **strongly recommended** to use the built-in **`ValkeyPool`** class instead of managing single `ValkeyClient` connections or connecting/closing individual clients.

The pool manages connections efficiently, preventing performance issues and resource exhaustion.

See below for both **basic** and **application** pooling examples for concurrent requests, including acquiring/releasing connections, handling wait queues, and choosing the right approach for your workload.

#### 1\. Basic: Pool Usage (from [example/simple\_pool\_example.dart](https://github.com/infradise/valkey_client/blob/main/example/simple_pool_example.dart))

Acquire a connection with `pool.acquire()` and return it with `pool.release()`.

```dart
import 'package:valkey_client/valkey_client.dart';

void main() async {
  // 1. Define connection settings for the pool
  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6379,
    // password: 'my-super-secret-password',
  );

  // 2. Create a pool (e.g., max 10 connections)
  final pool = ValkeyPool(connectionSettings: settings, maxConnections: 10);
  ValkeyClient? client;

  try {
    // 3. Acquire a client from the pool
    client = await pool.acquire();
    
    // 4. Run commands
    await client.set('greeting', 'Hello from ValkeyPool!');
    final value = await client.get('greeting');
    print(value); // Output: Hello from ValkeyPool!
    
  } on ValkeyConnectionException catch (e) {
    print('Connection or pool acquisition failed: $e');
  } on ValkeyServerException catch (e) {
    print('Server returned an error: $e');
  } finally {
    // 5. Release the client back to the pool
    if (client != null) {
      pool.release(client);
    }
    // 6. Close the pool when the application shuts down
    await pool.close();
  }
}
```

#### 2\. Application: Concurrent Pool Handling (from [example/pool\_example.dart](https://github.com/infradise/valkey_client/blob/main/example/pool_example.dart))

This shows how `ValkeyPool` handles concurrent requests up to `maxConnections` and uses a wait queue when the pool is full.

```dart
import 'dart:async';
import 'package:valkey_client/valkey_client.dart';

/// Helper function to simulate a web request using the pool.
Future<void> handleRequest(ValkeyPool pool, String userId) async {
  ValkeyClient? client;
  try {
    // 1. Acquire connection (waits if pool is full)
    print('[$userId] Acquiring connection...');
    client = await pool.acquire().timeout(Duration(seconds: 2));
    print('[$userId] Acquired!');

    // 2. Use connection
    await client.set('user:$userId', 'data');
    await Future.delayed(Duration(milliseconds: 500)); // Simulate work

  } on ValkeyException catch (e) {
    print('[$userId] Valkey Error: $e');
  } on TimeoutException {
    print('[$userId] Timed out waiting for a connection!');
  } finally {
    // 3. Release connection back to pool
    if (client != null) {
      print('[$userId] Releasing connection...');
      pool.release(client);
    }
  }
}

Future<void> main() async {
  final settings = ValkeyConnectionSettings(host: '127.0.0.1', port: 6379);
  
  // Create a pool with a max of 3 connections
  final pool = ValkeyPool(connectionSettings: settings, maxConnections: 3);

  print('Simulating 5 concurrent requests with a pool size of 3...');

  // 3. Simulate 5 concurrent requests
  final futures = <Future>[
    handleRequest(pool, 'UserA'),
    handleRequest(pool, 'UserB'),
    handleRequest(pool, 'UserC'), // These 3 get connections immediately
    handleRequest(pool, 'UserD'), // This one will wait
    handleRequest(pool, 'UserE'), // This one will wait
  ];

  await Future.wait(futures);
  await pool.close();
}
```

#### Smart Release

`ValkeyPool` now supports **Smart Release**. You don\'t need to manually discard connections that have changed state (e.g., inside a Transaction or Pub/Sub) when releasing it.

```dart
// Just use release()!
// The pool automatically detects if the client is dirty (Stateful) or closed
// and efficiently discards/replaces it if necessary.
pool.release(client);
```



### Group 3: Cluster Mode (Advanced)

This group is for connecting to a Valkey **Cluster Mode** environment.

#### Sharded Pub/Sub

ValkeyClusterClient for Cluster (from [example/cluster\_sharded\_pubsub\_example.dart](https://github.com/infradise/valkey_client/blob/main/example/cluster_sharded_pubsub_example.dart))

Sharded Pub/Sub reduces network traffic in cluster environments by routing messages only to the node responsible for the channel's slot.

```dart
// 1. Subscribe to sharded channels
// In Cluster mode, this automatically routes to the correct nodes.
final sub = client.ssubscribe(['shard:news:{sports}', 'shard:news:{tech}']);
await sub.ready;

// 2. Handle incoming messages
sub.messages.listen((msg) {
  print('Received on ${msg.channel}: ${msg.message}');
});

// 3. Publish to a specific shard
await client.spublish('shard:news:{sports}', 'Lakers won!');

// 4. Unsubscribe
await sub.unsubscribe();
```

**Note:** You can also use `ssubscribe` and `spublish` with `ValkeyClient` (Standalone) on compatible servers (Redis 7.0+ / Valkey 9.0+). See ValkeyClient for Standalone (from [example/sharded\_pubsub\_example.dart](https://github.com/infradise/valkey_client/blob/main/example/sharded_pubsub_example.dart))


#### Automatic Routing (from [example/cluster\_client\_example.dart](https://github.com/infradise/valkey_client/blob/main/example/cluster_client_example.dart))

Use `ValkeyClusterClient`. This client **auto-discovers** the cluster topology via `CLUSTER SLOTS` on `connect()` and **auto-routes** commands like `SET`/`GET` to the correct node.

```dart
import 'package:valkey_client/valkey_client.dart';

void main() async {
  // 1. Define initial seed nodes (only one is needed)
  final initialNodes = [
    ValkeyConnectionSettings(
      host: '127.0.0.1',
      port: 7001, // Connect to any node in the cluster
    ),
  ];

  // 2. Create the cluster client
  final client = ValkeyClusterClient(initialNodes);

  try {
    // 3. Connect (this fetches topology and builds pools)
    print('Connecting to cluster...');
    await client.connect();
    print('✅ Cluster connected and slot map loaded.');

    // 4. Run commands (will be auto-routed)
    print('\nRunning SET command for "key:A"...');
    await client.set('key:A', 'Hello from Node A');
    
    print('Running SET command for "key:B"...');
    await client.set('key:B', 'Hello from Node B');

    print('GET response for "key:A": ${await client.get("key:A")}');
    print('GET response for "key:B": ${await client.get("key:B")}');

  } on ValkeyException catch (e) {
    print('\n❌ Cluster Error: $e');
  } finally {
    // 5. Close all pooled cluster connections
    print('\nClosing all cluster connections...');
    await client.close();
  }
}
```

#### Automatic Failover

`ValkeyClusterClient` is resilient to node failures. If a master node crashes or becomes unreachable:

1.  The client detects the connection failure (e.g., `SocketException`).
2.  It automatically refreshes the cluster topology from remaining nodes.
3.  It finds the new master node and retries the command.

This happens transparently to the user. You do not need to catch connection exceptions for failovers.


#### Multi-key Operations: Scatter-Gather with Pipelined GETs (from [example/cluster\_mget\_example.dart](https://github.com/infradise/valkey_client/blob/main/example/cluster_mget_example.dart))

`ValkeyClusterClient` supports `MGET` even if keys are distributed across different nodes. It uses a Scatter-Gather strategy with pipelining to ensure high performance and correct ordering.

```dart
// Retrieve values from multiple nodes in parallel
final results = await client.mget(['key:A', 'key:B', 'key:C']);
print(results); // ['Value-A', 'Value-B', 'Value-C']
```

#### Manual Topology Fetch (from [example/cluster\_auto\_discovery\_example.dart](https://github.com/infradise/valkey_client/blob/main/example/cluster_auto_discovery_example.dart))

If you need to manually inspect the topology, you can use a standard `ValkeyClient` (single connection) to call `clusterSlots()` directly.

```dart
import 'package:valkey_client/valkey_client.dart';

void main() async {
  final client = ValkeyClient(host: '127.0.0.1', port: 7001);

  try {
    await client.connect();
    print('✅ Connected to cluster node at 127.0.0.1:7001');

    print('\nFetching cluster topology using CLUSTER SLOTS...');
    final List<ClusterSlotRange> slotRanges = await client.clusterSlots();

    print('Cluster topology loaded. Found ${slotRanges.length} slot ranges:');
    for (final range in slotRanges) {
      print('--------------------');
      print('  Slots: ${range.startSlot} - ${range.endSlot}');
      print('  Master: ${range.master.host}:${range.master.port}');
    }
  } on ValkeyException catch (e) {
    print('\n❌ Error: $e');
  } finally {
    await client.close();
  }
}
```


### Logging Configuration

By default, the client logs are disabled (`ValkeyLogLevel.off`).
You can enable logging globally to debug connection or parsing issues.

```dart
// Enable detailed logging
ValkeyClient.setLogLevel(ValkeyLogLevel.info);

// Disable logging (default)
ValkeyClient.setLogLevel(ValkeyLogLevel.off);
```
