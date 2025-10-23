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