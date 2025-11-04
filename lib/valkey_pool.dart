import 'dart:async';
import 'dart:collection'; // Import Queue
// import 'package:valkey_client/valkey_client_base.dart';
import 'package:valkey_client/valkey_client.dart'; // Import the concrete implementation
// import 'package:valkey_client/src/exceptions.dart'; // Import exceptions

// TODO: Add src/pool_manager.dart

/// Manages a pool of [ValkeyClient] connections.
///
/// This is the recommended class for high-concurrency applications
/// as it avoids the overhead of creating new connections for every request.
class ValkeyPool {
  final ValkeyConnectionSettings _connectionSettings;
  final int _maxConnections;

  /// --- Pool State ---
  /// Available clients ready for use.
  final Queue<ValkeyClient> _availableConnections = Queue();

  /// Number of connections currently in use (acquired).
  int _connectionsInUse = 0;

  /// Requests waiting for a connection to become available.
  final Queue<Completer<ValkeyClient>> _waitQueue = Queue();

  /// Flag to prevent new acquires after close() is called.
  bool _isClosing = false;
  // --------------------

  /// Creates a new connection pool.
  ///
  /// [connectionSettings]: The settings used to create new connections.
  /// [maxConnections]: The maximum number of concurrent connections allowed. Default to 10 max connections.
  ValkeyPool({
    required ValkeyConnectionSettings connectionSettings,
    int maxConnections = 10,
  })  : _connectionSettings = connectionSettings,
        _maxConnections = maxConnections {
    if (_maxConnections <= 0) {
      throw ArgumentError('maxConnections must be a positive integer.');
    }
  }

  /// Acquires a client connection from the pool.
  ///
  /// If the pool is full (`maxConnections` reached), this will wait
  /// until a connection is released back into the pool.
  Future<ValkeyClient> acquire() async {
    if (_isClosing) {
      throw ValkeyClientException(
          'Pool is closing, cannot acquire new connections.');
    }

    // 1. Check if a client is available in the pool
    while (_availableConnections.isNotEmpty) {
      final client = _availableConnections.removeFirst();

      // Health check on acquire
      try {
        // Check if the client is still healthy
        await client.ping().timeout(Duration(seconds: 2));
        // Health check passed, return the client
        _connectionsInUse++;
        return client;
      } catch (e) {
        // Health check failed, client is unhealthy
        // Destroy this client and try the next one in the queue
        await client.close();
        _connectionsInUse--; // Decrement count for the bad client we acquired and closed
        // Loop continues to try the next available client
      }
    }

    // 2. No healthy clients available, check if we can create a new connection
    if (_connectionsInUse < _maxConnections) {
      _connectionsInUse++;
      try {
        // Create, connect, and return a new client
        return await _createNewClient();
      } catch (e) {
        // If creation fails, decrement count and rethrow
        _connectionsInUse--;
        rethrow;
      }
    }

    // 3. Pool is full, wait for a connection
    final completer = Completer<ValkeyClient>();
    _waitQueue.add(completer);
    return completer.future;
  }

  /// Internal helper to create and connect a new client.
  Future<ValkeyClient> _createNewClient() async {
    final client = ValkeyClient(
      host: _connectionSettings.host,
      port: _connectionSettings.port,
      username: _connectionSettings.username,
      password: _connectionSettings.password,
    );
    try {
      await client.connect();
      return client;
    } catch (e) {
      // Ensure client is cleaned up if connect() fails
      await client.close(); // close() calls _cleanup()
      throw ValkeyConnectionException(
          'Failed to create new pool connection: $e', e);
    }
  }

  /// Releases a [client] back into the pool, making it available for reuse.
  void release(ValkeyClient client) {
    if (_isClosing) {
      // If pool is closing, just destroy the client
      client.close();
      return;
    }

    // 1. Check if anyone is waiting in the queue
    if (_waitQueue.isNotEmpty) {
      // Yes, pass this client directly to the oldest waiter
      final completer = _waitQueue.removeFirst();
      // We don't add to _availableConnections, count remains the same
      // We should check client health first
      _checkHealthAndPass(client, completer);
    } else {
      // 2. No one is waiting, add client back to the pool
      _connectionsInUse--;
      _availableConnections.add(client);
    }
  }

  /// Helper to check client health (e.g., PING) before reusing.
  void _checkHealthAndPass(
      ValkeyClient client, Completer<ValkeyClient> completer) async {
    try {
      // Simple health check. Does PING still work?
      final response = await client.ping().timeout(Duration(seconds: 2));
      if (response != 'PONG') {
        throw ValkeyClientException(
            'Health check failed (response was not PONG).');
      }
      // Health check passed, pass client to waiter
      completer.complete(client);
    } catch (e) {
      // Health check failed.
      // 1. Destroy the bad client
      await client.close();
      _connectionsInUse--; // Decrement count for the bad client

      // 2. Try to create a *new* client for the waiter
      try {
        final newClient = await _createNewClient();
        _connectionsInUse++; // Increment for the new client
        completer.complete(newClient); // Give new client to waiter
      } catch (newError) {
        // Failed to create replacement client
        // Pass the *creation* error to the original waiter
        completer.completeError(newError);
      }
    }
  }

  /// Closes all connections in the pool and shuts down the pool.
  Future<void> close() async {
    _isClosing = true;

    // 1. Reject any pending waiters
    while (_waitQueue.isNotEmpty) {
      _waitQueue.removeFirst().completeError(
          ValkeyClientException('Pool is closing, request cancelled.'));
    }

    // 2. Close all available connections
    final closeFutures = <Future<void>>[];
    while (_availableConnections.isNotEmpty) {
      closeFutures.add(_availableConnections.removeFirst().close());
    }

    await Future.wait(closeFutures);

    // Note: Connections currently in use will be closed
    // when they are returned via release()
    _connectionsInUse = 0; // Reset count
  }
}
