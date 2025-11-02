# Valkey client

[![pub package](https://img.shields.io/pub/v/valkey_client.svg)](https://pub.dev/packages/valkey_client)
[![pub points](https://img.shields.io/pub/points/valkey_client.svg)](https://pub.dev/packages/valkey_client/score)


A modern, production-ready Dart client for Valkey (9.0.0+). Fully Redis 7.x compatible.

---

## ⚠️ Important Note: Connection Pooling

This client **does not include built-in connection pooling** in `v1.0.0`.

For high-concurrency production applications (like backend servers), you **MUST** use an external pooling package (like [`package:pool`](https://pub.dev/packages/pool)) to manage connections. Using `ValkeyClient.connect()` and `ValkeyClient.close()` for every request will result in poor performance.

Built-in connection pooling is a top priority for `v2.0.0` (see [Roadmap](https://github.com/infradise/valkey_client/wiki/Roadmap)).

---

## Features

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
* **Pub/Sub Ready:** `subscribe()` returns a `Subscription` object with a `Stream` and a `Future<void> ready` for easy and reliable message handling.
* **Production-Ready (Standalone/Sentinel):** `v1.0.0` is stable for production use in non-clustered environments (when used with a connection pool).

## Getting Started

### Prerequisites: Running a Valkey Server

This client requires a running Valkey server. For local development, we recommend Docker.

1.  Install a container environment like [Docker Desktop](https://www.docker.com/products/docker-desktop/) or [Rancher Desktop](https://rancherdesktop.io/).
2.  Start a Valkey server instance:

**Option 1: No Authentication (Default)**
```bash
docker run -d --name my-valkey -p 6379:6379 valkey/valkey:latest
````

**Option 2: With Password Only**
(Sets the password for the `default` user)

```bash
docker run -d --name my-valkey-auth -p 6379:6379 valkey/valkey:latest \
  --requirepass "my-super-secret-password"
```

**Option 3: With Username and Password (ACL)**
(Sets the password for the `default` user)

```bash
docker run -d --name my-valkey-acl -p 6379:6379 valkey/valkey:latest \
  --user default --pass "my-super-secret-password"
```

  * Valkey/Redis 6+ uses ACLs. To create a new user, change `--user default` to `--user my-user`.
  * The `-d` flag runs the container in "detached" mode. Remove it to see server logs in your terminal.

## Usage

See the **[Example](https://pub.dev/packages/valkey_client/example)** tab for comprehensive usage examples covering all command groups.

A simple example:

```dart
import 'package:valkey_client/valkey_client.dart';

void main() async {
  // 1. Configure the client
  final client = ValkeyClient(
    host: '127.0.0.1',
    port: 6379,
    // password: 'my-super-secret-password',
  );

  try {
    // 2. Connect
    await client.connect();
    
    // 3. Run commands
    await client.set('greeting', 'Hello, Valkey!');
    final value = await client.get('greeting');
    print(value); // Output: Hello, Valkey!
    
  } on ValkeyConnectionException catch (e) {
    print('Connection failed: $e');
  } on ValkeyServerException catch (e) {
    print('Server returned an error: $e');
  } finally {
    // 4. Close the connection
    await client.close();
  }
}
```

---

## Contributing

Your contributions are welcome\! Please check the [GitHub repository](https://github.com/infradise/valkey_client) for open issues or submit a Pull Request. For major changes, please open an issue first to discuss the approach.

---

## Maintained By

Maintained by the developers of [Visualkube](https://visualkube.com) at [Infradise Inc](https://visualkube.com/about-us). We believe in giving back to the Dart & Flutter community.

---

## License

This project is licensed under the **Apache License 2.0**.

⚠️ **License Change Notification (2025-10-29)**

This project was initially licensed under the MIT License. As of October 29, 2025 (v0.11.0 and later), the project has been re-licensed to the **Apache License 2.0**.

We chose Apache 2.0 for its robust, clear, and balanced terms, which benefit both users and contributors:

  * **Contributor Protection (Patent Defense):** Includes a defensive patent termination clause. This strongly deters users from filing patent infringement lawsuits against contributors (us).
  * **User Protection (Patent Grant):** Explicitly grants users a patent license for any contributor patents embodied in the code, similar to MIT.
  * **Trademark Protection (Non-Endorsement):** Includes a clause (Section 6) that restricts the use of our trademarks (like `Infradise Inc.` or `Visualkube`), providing an effect similar to the "non-endorsement" clause in the BSD-3 license.

**License Compatibility:** Please note that the Apache 2.0 license is **compatible with GPLv3**, but it is **not compatible with GPLv2**.

All versions published prior to this change remain available under the MIT License. All future contributions and versions will be licensed under Apache License 2.0.