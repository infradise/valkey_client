# `valkey_client`

[](https://pub.dev/packages/valkey_client)

A modern, production-ready Dart client for Valkey (9.0.0+). Fully Redis 7.x compatible.

-----

## ⚠️ Under Active Development

**This package is currently in its early stages.**

It is under active development and is **not yet ready for production use**. We are building the foundation, starting with core connection logic. Do not use this in a production environment until version 1.0.0 is released.

## Getting Started

### Prerequisites: Running a Valkey Server

This client requires a running Valkey server to connect to. For local development and testing, we strongly recommend using Docker.

1.  Install a container environment like [Docker Desktop](https://www.docker.com/products/docker-desktop/) or [Rancher Desktop](https://rancherdesktop.io/).

2.  Start a Valkey server instance by running the following command in your terminal:

    ```bash
    docker run -d --name my-valkey -p 6379:6379 valkey/valkey:latest
    ```

    This will run the latest Valkey server in the background and map it to `localhost:6379`.

## Usage

Here is a basic example of how to connect and close the client.

```dart
import 'package:valkey_client/valkey_client.dart';

void main() async {
  // IMPORTANT: Make sure a Valkey server is running.
  // See the 'Getting Started' section for Docker instructions.

  final client = ValkeyClient();

  try {
    // 1. Connect to the server
    await client.connect(host: '127.0.0.1', port: 6379);
    print('✅ Connection successful!');

    // 2. Execute commands (coming in a future version)
    //
    // print('Sending PING...');
    // final response = await client.ping();
    // print('Server response: $response'); // Expected output: PONG

  } catch (e) {
    // Handle connection errors (e.g., server not running)
    print('❌ Connection failed: $e');
  } finally {
    // 3. Always close the connection when you are done.
    print('Closing connection...');
    await client.close();
  }
}
```

For more examples, check the `/example` folder.

## The Goal 🎯

The Dart ecosystem needs a high-performance, actively maintained client for the next generation of in-memory databases. This package aims to be the standard Dart client for **Valkey (9.0.0+)** while maintaining full compatibility with **Redis (7.x+)**.

It is designed primarily for server-side Dart applications (`server.dart`) requiring a robust and fast connection to Valkey.

## Planned Features

  * **Valkey 9.0.0+ Support:** Full implementation of the latest commands and features.
  * **RESP3 Protocol:** Built on the modern RESP3 protocol for richer data types and performance.
  * **High-Performance Async I/O:** Non-blocking, asynchronous networking.
  * **Connection Pooling:** Production-grade connection pooling suitable for high-concurrency backend servers.
  * **Type-Safe & Modern API:** A clean, easy-to-use API for Dart developers.

## Contributing

This project is just getting started. If you are interested in contributing to the development of the standard Valkey client for Dart, please check the **[GitHub repository](https://github.com/infradise/valkey_client)** or file an issue to discuss ideas.