/*
 * Copyright 2026 Infradise Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:collection';
import 'package:valkey_client/valkey_client.dart';

/// Manages a pool of [ValkeyClient] connections with robust resource tracking.
///
/// This is the recommended class for high-concurrency applications
/// as it avoids the overhead of creating new connections for every request.
///
/// v1.7.0 Features:
/// - **Smart Release:** Automatically discards stateful (dirty) connections.
/// - **Idempotency:** Safe to call release/discard multiple times.
/// - **Leak Prevention:** Tracks all created connections to prevent leaks.
class ValkeyPool {
  final ValkeyConnectionSettings _connectionSettings;
  final int _maxConnections;

  // --- Pool State (Robust Tracking) ---

  /// All connections managed by this pool (Leased + Idle).
  /// Used to verify ownership and prevent leaks.
  final Set<ValkeyClient> _allClients = {};

  /// Connections currently waiting to be reused.
  final Queue<ValkeyClient> _idleClients = Queue();

  /// Connections currently leased out to users.
  final Set<ValkeyClient> _leasedClients = {};

  /// Requests waiting for a connection to become available.
  final Queue<Completer<ValkeyClient>> _waitQueue = Queue();

  /// Flag to prevent new acquires after close() is called.
  bool _isClosing = false;

  /// Returns the total number of connections managed by this pool.
  int get totalConnectionCount => _allClients.length;

  /// Returns the number of connections currently idle.
  int get idleConnectionCount => _idleClients.length;

  /// Returns the number of connections currently in use.
  int get leasedConnectionCount => _leasedClients.length;

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
  ///
  /// (The acquired client **MUST** be returned using [release]
  /// when done.)
  Future<ValkeyClient> acquire() async {
    if (_isClosing) {
      throw ValkeyClientException(
          'Pool is closing, cannot acquire new connections.');
    }

    // 1. Try to reuse an idle connection
    while (_idleClients.isNotEmpty) {
      final client = _idleClients.removeFirst();

      // [Vital Check] Double-check connectivity before handing out
      if (!client.isConnected) {
        // Was closed externally while idle. Discard and try next.
        await discard(client);
        continue;
      }

      _leasedClients.add(client);
      return client;
    }

    // 2. No idle connections, create new if allowed
    if (_allClients.length < _maxConnections) {
      return _createNewClientAndLease();
    }

    // 3. Pool is full, wait for a connection
    final completer = Completer<ValkeyClient>();
    _waitQueue.add(completer);
    return completer.future;
  }

  /// Helper to create, track, and lease a new client.
  Future<ValkeyClient> _createNewClientAndLease() async {
    try {
      final client = ValkeyClient(
        host: _connectionSettings.host,
        port: _connectionSettings.port,
        username: _connectionSettings.username,
        password: _connectionSettings.password,
        commandTimeout: _connectionSettings.commandTimeout,
        // connectTimeout: _connectionSettings.connectTimeout,

        // [v2.0.0] Pass SSL options from Pool settings to the Client
        useSsl: _connectionSettings.useSsl,
        sslContext: _connectionSettings.sslContext,
        onBadCertificate: _connectionSettings.onBadCertificate,
      );
      await client.connect();

      _allClients.add(client);
      _leasedClients.add(client);
      return client;
    } catch (e) {
      // Creation failed, no tracking needed as it wasn't added
      throw ValkeyConnectionException(
          'Failed to create new pool connection: $e', e);
    }
  }

  /// Releases a connection back to the pool.
  /// Automatically discards if the client is closed or stateful (Smart Release).
  ///
  /// ```dart
  /// final client = await pool.acquire();
  /// try {
  ///   await client.set('key', 'value');
  /// } finally {
  ///   pool.release(client);
  /// }
  /// ```
  ///
  /// - If the client is **stateful** (e.g., Pub/Sub mode), it is automatically **discarded**.
  /// - If the client does not belong to this pool or was already released, this does nothing (Safe).
  void release(ValkeyClient client) {
    // 1. Ownership & State Check
    if (!_allClients.contains(client)) {
      // Already discarded or foreign client. Ignore safely.
      return;
    }

    if (!_leasedClients.contains(client)) {
      // Already released (idle) or inconsistent state. Ignore safely.
      return;
    }

    // Check if connection is dead
    if (!client.isConnected) {
      discard(client);
      return;
    }

    // 2. Smart Discard: Check if client is dirty
    if (client.isStateful) {
      // Client is in Pub/Sub or Transaction mode. Cannot reuse.
      discard(client);
      return;
    }

    // 3. Normal Release: Move from Leased to Idle
    _leasedClients.remove(client);

    // 4. Handover to waiter OR make idle
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      _leasedClients.add(client); // Moved back to leased for the waiter
      completer.complete(client);
    } else {
      _idleClients.add(client);
    }
  }

  /// Explicitly discards a connection, removing it from the pool and closing it.
  ///
  /// Use this if the connection is broken or no longer needed.
  /// Safe to call multiple times.
  Future<void> discard(ValkeyClient client) async {
    // 1. Ownership Check
    if (!_allClients.contains(client)) {
      return; // Already gone. Safe.
    }

    // 2. Remove from all trackers
    _allClients.remove(client);
    _leasedClients.remove(client);
    _idleClients.remove(client);

    // 3. Close the physical connection
    // We await this to ensure resources are freed, but ignore errors.
    try {
      await client.close();
    } catch (_) {
      // Ignore errors during close
    }

    // 4. Fill the void: If there are waiters, create a NEW connection
    // We freed up a slot in _allClients, so we can honor a waiter.
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      try {
        final newClient = await _createNewClientAndLease();
        completer.complete(newClient);
      } catch (e) {
        // If creation fails, we can't satisfy the waiter now.
        // We must error the waiter to avoid deadlock.
        completer.completeError(e);
      }
    }
  }

  /// Closes all connections and the pool itself.
  Future<void> close() async {
    _isClosing = true;

    // 1. Cancel waiters
    while (_waitQueue.isNotEmpty) {
      _waitQueue.removeFirst().completeError(
          ValkeyClientException('Pool is closing, request cancelled.'));
    }

    // 2. Close all clients (Idle + Leased)
    final futures = _allClients.map((c) => c.close());
    // final futures = <Future<void>>[];
    // for (final client in _allClients) {
    //   futures.add(client.close());
    // }

    await Future.wait(futures);

    _allClients.clear();
    _idleClients.clear();
    _leasedClients.clear();
  }
}
