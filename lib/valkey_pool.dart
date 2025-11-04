import 'dart:async';
import 'package:valkey_client/valkey_client_base.dart';
import 'package:valkey_client/valkey_client.dart'; // Import the concrete implementation

// TODO: Add src/pool_manager.dart

/// Manages a pool of [ValkeyClient] connections.
///
/// This is the recommended class for high-concurrency applications
/// as it avoids the overhead of creating new connections for every request.
class ValkeyPool {
  final ValkeyConnectionSettings _connectionSettings;
  final int _maxConnections;

  // TODO: Add internal queue/list to hold clients
  // final Queue<_ManagedConnection> _availableConnections = Queue();
  // int _connectionsInUse = 0;

  /// Creates a new connection pool.
  ///
  /// [connectionSettings]: The settings used to create new connections.
  /// [maxConnections]: The maximum number of concurrent connections allowed.
  ValkeyPool({
    required ValkeyConnectionSettings connectionSettings,
    int maxConnections = 10, // Default to 10 max connections
  })  : _connectionSettings = connectionSettings,
        _maxConnections = maxConnections;

  /// Acquires a client connection from the pool.
  ///
  /// If the pool is full (`maxConnections` reached), this will wait
  /// until a connection is released back into the pool.
  ///
  /// The acquired client **MUST** be returned using [release]
  /// when done.
  Future<ValkeyClient> acquire() async {
    // TODO: Implement pooling logic
    // 1. Check if any client is available in _availableConnections
    // 2. If yes, remove and return it.
    // 3. If no, check if _connectionsInUse < _maxConnections
    // 4. If yes, create a new ValkeyClient, connect() it, and return it.
    // 5. If no (pool is full), wait using a Completer...

    // For now, just create a new client (placeholder)
    final client = ValkeyClient(
      host: _connectionSettings.host,
      port: _connectionSettings.port,
      username: _connectionSettings.username,
      password: _connectionSettings.password,
    );
    await client.connect();
    return client;
  }

  /// Releases a [client] back into the pool, making it available for reuse.
  ///
  /// Call this in a `finally` block to ensure connections are always returned.
  /// ```dart
  /// final client = await pool.acquire();
  /// try {
  ///   await client.set('key', 'value');
  /// } finally {
  ///   pool.release(client);
  /// }
  /// ```
  void release(ValkeyClient client) {
    // TODO: Implement release logic
    // 1. Check if client is healthy (e.g., client.ping()?)
    // 2. If healthy, add to _availableConnections.
    // 3. If unhealthy, client.close() and create a new one?
    // 4. Check if anyone is waiting for a connection and complete their future.

    // For now, just close the client (placeholder)
    client.close();
  }

  /// Closes all connections in the pool and shuts down the pool.
  Future<void> close() async {
    // TODO: Implement close logic
    // 1. Close all clients in _availableConnections
    // 2. Handle connections currently in use (wait for release? force close?)
  }
}