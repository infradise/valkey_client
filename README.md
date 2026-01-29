# valkey_client ⚡

[![pub package](https://img.shields.io/pub/v/valkey_client.svg)](https://pub.dev/packages/valkey_client)
[![CT](https://github.com/infradise/valkey_client/actions/workflows/valkey_client_ct.yaml/badge.svg)](https://github.com/infradise/valkey_client/actions/workflows/valkey_client_ct.yaml)

### Dart client for Redis and Valkey

The **valkey_client** is a high-performance, cluster-aware Dart client for Redis and Valkey.

## Overview
- Data format: RedisJSON; ValkeyJSON
- Deployment modes: Standalone; Sentinel; Cluster
- Scalability: Scalable replica reads offloading; smart load balancing
- Reliability: Automatic failover; smart connection pooling
- Messaging: Sharded Pub/Sub for scalable messaging
- Operations: Multi-key operations; configurable command timeouts
- Protocol: RESP3 parsing with type-safe exceptions
- Observability: Built-in logging
- Security: SSL/TLS support
- Valkey 9.0+ Features Support
  - Numbered clusters: Intelligent database selection for seamless cluster management

## Need help?

1. Still using Redis instead of Valkey? Check out [Developer Experience Improvements](https://github.com/infradise/valkey_client/wiki/Developer-Experience-Improvements)
2. No GUI for Redis/Valkey? Try [Keyscope Jet](https://keyscope.dev)
3. Looking for a GUI built with `valkey_client`? Try [Keyscope](https://pub.dev/packages/keyscope)
4. Need real‑time watch for Redis/Valkey pods and services across multiple K8s clusters? Try [Visualkube Jet](https://jet.visualkube.com)

## Features

* **Generic Commands:** Added `scan`
* **JSON Commands:** Introduced RedisJSON; ValkeyJSON - JSON-based document formats for storing structured payloads.
  * `jsonArrAppendEnhanced`, `jsonArrIndexEnhanced`, `jsonArrInsertEnhanced`, `jsonArrLenEnhanced`, `jsonArrPopEnhanced`, `jsonArrTrimEnhanced`, `jsonObjKeysEnhanced`, `jsonStrAppendEnhanced`, `jsonStrLenEnhanced`
  * `jsonDebug`, `jsonResp`, `jsonToggle`, `jsonType`
  * `jsonObjKeys`, `jsonObjLen`, `jsonStrAppend`, `jsonStrLen`
  * `jsonClear`, `jsonForget`, `jsonMGet`, `jsonMSet`, `jsonNumIncrBy`,`jsonNumMultBy`, `jsonMergeForce`
  * `jsonArrAppend`, `jsonArrIndex`, `jsonArrInsert`, `jsonArrLen`, `jsonArrPop`,`jsonArrTrim`
  * `jsonGet`, `jsonSet`, `jsonDel`, `jsonMerge`
* **Redis/Valkey Module Detector:** Introduced to get Redis and Valkey module list and information. (e.g., `json`, `search`, `ldap`, `bf`, etc.)
* **JSON Module Checker:** Introduced to check JSON module names in advance before running logic.
* **Scalable Replica Reads:** Boost read performance by offloading read-only commands (e.g., `GET`, `EXISTS`) to replica nodes. Supports `ReadPreference` settings (`master`, `preferReplica`, `replicaOnly`) to control traffic flow.
* **Smart Load Balancing :** Built-in load balancing strategies (`Round-Robin`, `Random`) to efficiently distribute read traffic across available replicas.
* **Automatic Replica Discovery:** Automatically detects and connects to replica nodes via `INFO REPLICATION` (Standalone/Sentinel) to maintain an up-to-date pool of connections.
* **Explicit Replica Configuration**: Added `explicitReplicas` to `ValkeyConnectionSettings` to manually define replica nodes, solving connectivity issues in some environments where auto-discovery fails.
* **Smart Database Selection:** First-class support for selecting databases (0-15+) on connection. Automatically detects **Valkey 9.0+ Numbered Clusters** to enable multi-database support in cluster mode, while maintaining backward compatibility with Redis Clusters (DB 0 only).
* **Server Metadata Discovery:** Access server details via `client.metadata` (Version, Mode, Server Name, Max Databases) to write adaptive logic for Valkey vs. Redis.
* **Enterprise Security:** Native SSL/TLS support for secure communication. Fully compatible with major cloud providers (AWS, Azure, GCP) and supports custom security contexts (including self-signed certificates).
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


