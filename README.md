[![pub package](https://img.shields.io/pub/v/valkey_client.svg)](https://pub.dev/packages/valkey_client)

# Valkey client

A modern, production-ready Dart client for Valkey (9.0.0+). Fully Redis 7.x compatible.

---

## Recommended Usage: Connection Pooling (v1.1.0+)

For all applications (especially high-concurrency production servers), it is **strongly recommended** to use the built-in **`ValkeyPool`** class instead of connecting/closing individual clients.

The pool manages connections efficiently, preventing performance issues and resource exhaustion.

(See the main `Usage` example below for a simple case, or the [**advanced pool example**](https://github.com/infradise/valkey_client/blob/main/example/pool_example.dart) for concurrent requests.)

---

## Features

* **Cluster Client (v1.3.0):** Added `ValkeyClusterClient` for automatic command routing in cluster mode.
    * This client automatically routes commands to the correct node.
    * We recommend using `ValkeyClient` for Standalone/Sentinel and `ValkeyClusterClient` for cluster environments.
    * *Note: Multi-key commands (like `MGET`) are planned for v1.4.0.*
* **Built-in Connection Pooling (v1.1.0):** `ValkeyPool` for efficient connection management (used by Standalone and Cluster clients).
* **Cluster Auto-Discovery (v1.2.0):** Added `client.clusterSlots()` to fetch cluster topology (via the `CLUSTER SLOTS` command), laying the foundation for full cluster support.
* **Command Timeout (v1.2.0):** Includes a built-in command timeout (via `ValkeyConnectionSettings`) to prevent client hangs on non-responsive servers.
* **Broad Command Support:**
    * Strings (`GET`, `SET`, `MGET`)
    * Hashes (`HSET`, `HGET`, `HGETALL`)
    * Lists (`LPUSH`, `RPUSH`, `LPOP`, `RPOP`, `LRANGE`)
    * Sets (`SADD`, `SREM`, `SMEMBERS`)
    * Sorted Sets (`ZADD`, `ZREM`, `ZRANGE`)
    * Key Management (`DEL`, `EXISTS`, `EXPIRE`, `TTL`)
    * Transactions (`MULTI`, `EXEC`, `DISCARD`)
    * Full Pub/Sub (`SUBSCRIBE`, `UNSUBSCRIBE`, `PSUBSCRIBE`, `PUNSUBSCRIBE`)
    * Pub/Sub Introspection (`PUBSUB CHANNELS`, `NUMSUB`, `NUMPAT`)
* **Robust Parsing:** Full RESP3 parser handling all core data types (`+`, `-`, `$`, `*`, `:`).
* **Type-Safe Exceptions:** Clear distinction between connection errors (`ValkeyConnectionException`), server errors (`ValkeyServerException`), and client errors (`ValkeyClientException`).
* **Pub/Sub Ready (Standalone/Sentinel):** `subscribe()` returns a `Subscription` object with a `Stream` and a `Future<void> ready` for easy and reliable message handling.
* **Production-Ready (Standalone/Sentinel):** `v1.0.0` is stable for production use in non-clustered environments (when used with a connection pool). This lays the foundation for the full cluster support planned for v2.0.0 (see [Roadmap](https://github.com/infradise/valkey_client/wiki/Roadmap#roadmap-towards-v200-production-ready-for-cluster-)).

## Getting Started

### Prerequisites: Running a Valkey Server

This client requires a running Valkey server to connect to. For local development and testing, we strongly recommend using Docker.

1.  Install a container environment like [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or [Rancher Desktop](https://rancherdesktop.io/)).
2.  Start a Valkey server instance by running one of the following commands in your terminal:

**Option 1: No Authentication (Default)**
```bash
docker run -d --name my-valkey -p 6379:6379 valkey/valkey:latest
````

**Option 2: With Password Only**
(This sets the password for the `default` user. Use with `username: null` in the client.)

```bash
docker run -d --name my-valkey-auth -p 6379:6379 valkey/valkey:latest \
  --requirepass "my-super-secret-password"
```

**Option 3: With Username and Password (ACL)**
(This sets the password for the `default` user. Use with `username: 'default'` in the client.)

```bash
docker run -d --name my-valkey-acl -p 6379:6379 valkey/valkey:latest \
  --user default --pass "my-super-secret-password"
```

  * Valkey/Redis 6+ uses ACLs. The `default` user exists by default. To create a new user instead, simply change `--user default` to `--user my-user`.

*(Note: The '-d' flag runs the container in "detached" mode (in the background). You can remove it if you want to see the server logs directly in your terminal.)*


## Usage

See the **[Example tab](https://pub.dev/packages/valkey_client/example)** for all examples. Additionally, the [**advanced pool example**](https://github.com/infradise/valkey_client/blob/main/example/pool_example.dart) and the [**cluster auto-discovery example**](https://github.com/infradise/valkey_client/blob/main/example/cluster_auto_discovery_example.dart) are linked to their respective files in the GitHub repository. Check the example folder for more examples.

A simple example (`simple_pool_example.dart`):

```dart
import 'package:valkey_client/valkey_client.dart';

void main() async {
  // 1. Define connection settings
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

---

## The Goal 🎯

The Dart ecosystem needs a high-performance, actively maintained client for the next generation of in-memory databases. This package aims to be the standard Dart client for **Valkey (9.0.0+)** while maintaining full compatibility with **Redis (7.x+)**.

It is designed primarily for server-side Dart applications (`server.dart`) requiring a robust and fast connection to Valkey.

## Planned Features

  * **Valkey 9.0.0+ Support:** Full implementation of the latest commands and features.
  * **RESP3 Protocol:** Built on the modern RESP3 protocol for richer data types and performance.
  * **High-Performance Async I/O:** Non-blocking, asynchronous networking.
  * **Connection Pooling:** Production-grade connection pooling suitable for high-concurrency backend servers.
  * **Type-Safe & Modern API:** A clean, easy-to-use API for Dart developers.

More details in the [Roadmap](https://github.com/infradise/valkey_client/wiki/Roadmap).

---

## Contributing

Your contributions are welcome\! Please check the [GitHub repository](https://github.com/infradise/valkey_client) for open issues or submit a Pull Request. For major changes, please open an issue first to discuss the approach.

---

## Maintained By

Maintained by the developers of [Visualkube](https://visualkube.com) at [Infradise Inc](https://visualkube.com/about-us). We believe in giving back to the Dart & Flutter community.

---

## License

This project is licensed under the **Apache License 2.0**.

**License Change Notification (2025-10-29)**

This project was initially licensed under the MIT License. As of October 29, 2025 (v0.11.0 and later), the project has been re-licensed to the **Apache License 2.0**.

We chose Apache 2.0 for its robust, clear, and balanced terms, which benefit both users and contributors:

  * **Contributor Protection (Patent Defense):** Includes a defensive patent termination clause. This strongly deters users from filing patent infringement lawsuits against contributors (us).
  * **User Protection (Patent Grant):** Explicitly grants users a patent license for any contributor patents embodied in the code, similar to MIT.
  * **Trademark Protection (Non-Endorsement):** Includes a clause (Section 6) that restricts the use of our trademarks (like `Infradise Inc.` or `Visualkube`), providing an effect similar to the "non-endorsement" clause in the BSD-3 license.

**License Compatibility:** Please note that the Apache 2.0 license is **compatible with GPLv3**, but it is **not compatible with GPLv2**.

All versions published prior to this change remain available under the MIT License. All future contributions and versions will be licensed under Apache License 2.0.