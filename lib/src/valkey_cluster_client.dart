/*
 * Copyright 2025-2026 Infradise Inc.
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
import '../valkey_client.dart';
import 'cluster_hash.dart';
import 'cluster_slot_map.dart';

/// The concrete implementation of [ValkeyClusterClientBase].
///
/// This client manages connections to all master nodes in a Valkey Cluster,
/// automatically routing commands to the correct node based on the key's hash
/// slot.
///
/// Features:
/// - **Auto-Discovery:** Fetches cluster topology on connection.
/// - **Smart Routing:** Directs commands to the master node owning the key's
/// slot.
/// - **Resilience (v1.8.0+):** Automatically handles `-MOVED` / `-ASK` redirections and
///   refreshes topology on connection failures (Failover).
///   - **Automatic Failover:** Detects connection failures and refreshes
/// topology.
///   - **Topology Refresh:** Queries available nodes to update the slot map.
/// - **NAT Support:** Automatically detects and maps Docker/NAT IP addresses.
class ValkeyClusterClient implements ValkeyClusterClientBase {
  static final _log = ValkeyLogger('ValkeyClusterClient');

  /// Time to wait before refreshing topology after a connection failure.
  /// allowing the cluster some time to elect a new master.
  static const Duration _failoverWait = Duration(milliseconds: 200);

  /// The initial nodes provided by the user to bootstrap the connection.
  /// The initial nodes to connect to for discovering the cluster topology.
  final List<ValkeyConnectionSettings> _initialNodes;

  /// Default connection settings (timeout, auth) derived from the first seed
  /// node (to use for all pooled connections).
  final ValkeyConnectionSettings _defaultSettings;

  /// Maximum number of retries/redirects before throwing an exception.
  final int _maxRedirects;

  /// Manages the mapping of slots (0-16383) to master nodes.
  ClusterSlotMap? _slotMap;

  /// A map of connection pools, keyed by the node's address "host:port" (one
  /// for each master node).
  /// The key uses the *mapped* address (e.g., localhost:7001) suitable for
  /// connection.
  final Map<String, ValkeyPool> _nodePools = {};

  bool _isClosed = false;

  /// Stores the NAT mapping rule: { 'Internal IP' : 'External IP' }.
  /// e.g., {'192.168.65.254': '127.0.0.1'}
  Map<String, String> _hostMap = {};

  ValkeyClusterClient(
    this._initialNodes, {
    int maxRedirects = 5,
  })  : _defaultSettings = _initialNodes.first,
        _maxRedirects = maxRedirects {
    if (_initialNodes.isEmpty) {
      throw ArgumentError('At least one initial node must be provided.');
    }
  }

  @override
  Future<void> connect() async {
    if (_slotMap != null) return; // Already connected
    if (_isClosed) {
      throw ValkeyClientException(
          'Client is closed and cannot be reconnected.');
    }

    _hostMap = {}; // Reset NAT map on (re)connect

    // Initial Topology Fetch
    // We treat the initial connection as a "Refresh" to populate the map.
    await _refreshTopology(isInitial: true);

    // Pre-warm Connection Pools
    // \ We must ensure that pools for all discovered master nodes are created immediately.
    // \ This allows methods like pingAll() to work right after connect().
    if (_slotMap != null) {
      for (final node in _slotMap!.masterNodes) {
        _getOrCreatePool(node);
      }
    }
  }

  /// Retrieves or creates a connection pool for a specific cluster node.
  /// Applies Auto-NAT mapping ( NAT mapping automatically).
  ValkeyPool _getOrCreatePool(ClusterNodeInfo node) {
    // for (final node in slotMap.masterNodes) {
    // node.host = '192.168.65.254', node.port = 7001, 7002, 7003

    // --- BEGIN FIX (v1.3.0) ---
    // Apply host mapping if provided
    // node.host here is '192.168.65.254'
    // final mappedHost = hostMapper?.call(node.host) ?? node.host; // It works too.
    // Apply mapping rule: Get '127.0.0.1' if it exists, otherwise use original
    // Apply the mapping rule CONSISTENTLY
    // Apply NAT mapping: Use external IP if mapped, otherwise original.
    final mappedHost =
        _hostMap[node.host] ?? node.host; // '127.0.0.1' (Correct)
    // mappedHost is now '127.0.0.1'
    // --- END FIX ---

    final nodeId =
        '$mappedHost:${node.port}'; // Key is '127.0.0.1:7002' (Correct pool ID)

    if (_nodePools.containsKey(nodeId)) {
      return _nodePools[nodeId]!;
    }

    final nodeSettings = ValkeyConnectionSettings(
      host: mappedHost, // Use the MAPPED host (e.g., '127.0.0.1')
      port: node.port, // Use the correct port (e.g., 7002)
      // commandTimeout: _defaultSettings.commandTimeout,
      username: _defaultSettings.username,
      password: _defaultSettings.password,
      commandTimeout: _defaultSettings.commandTimeout,
      connectTimeout: _defaultSettings.connectTimeout,
      // [v2.0.0] Apply SSL settings to the new pool
      useSsl: _defaultSettings.useSsl,
      sslContext: _defaultSettings.sslContext,
      onBadCertificate: _defaultSettings.onBadCertificate,
    );

    // Create a new pool.
    // v1.7.0 Smart Release is handled inside ValkeyPool
    final pool = ValkeyPool(connectionSettings: nodeSettings);
    _nodePools[nodeId] = pool;

    return pool;
  }

  @override
  Future<void> close() async {
    _isClosed = true;
    _slotMap = null;
    final futures = _nodePools.values.map((pool) => pool.close());
    await Future.wait(futures);
    _nodePools.clear();
  }

  /// Returns a unique identifier for a node, respecting NAT mapping.
  String _getNodeId(ClusterNodeInfo node) {
    // Apply the auto-discovered mapping
    // This method MUST consistently use the same _hostMap
    // as the connect() method.
    // This method now *only* uses the automatic _hostMap.
    final mappedHost = _hostMap[node.host] ?? node.host;
    return '$mappedHost:${node.port}';
  }

  // --- v1.8.0+ Core Routing Logic (Failover & Redirection/Refresh) ---

  /// Internal helper to execute commands with automatic routing and failover.
  /// Executes a command on the master node responsible for [key].
  ///
  /// Handles:
  /// 1. **Routing:** Finds the correct node via CRC16.
  /// 2. **Redirection:** Handles `-MOVED` (topology change) and `-ASK`
  /// (migration).
  /// 3. **Failover:** Detects connection failures, refreshes topology, and
  /// retries.
  Future<T> _executeOnKey<T>(
      String key, Future<T> Function(ValkeyClient client) command) async {
    if (_slotMap == null || _isClosed) {
      throw ValkeyClientException(
          'Client is not connected. Call connect() first.');
    }

    var attempts = 0;
    Object? lastError;

    // Retry loop handles: 1. MOVED/ASK, 2. Connection Failures (Failover)
    while (attempts <= _maxRedirects) {
      try {
        // Locate the master node
        // Find the correct node for this key (node.host will be
        // '192.168.65.254')
        final node = _slotMap!.getNodeForKey(key);
        if (node == null) {
          // If map is empty or stale/broken, try refreshing once
          if (attempts == 0) {
            _log.info(
                'No node map found for key "$key". Refreshing topology...');
            await _refreshTopology();
            attempts++;
            continue;
          }
          throw ValkeyClientException(
              'Could not find a master node for key "$key" '
              '(Slot: ${getHashSlot(key)}).');
        }

        // Get the connection pool
        final pool = _getOrCreatePool(node);

        // Acquire, execute, and release (Execute Command)
        ValkeyClient? client;
        try {
          // The pool will connect to '127.0.0.1:7002'
          client = await pool.acquire();
          return await command(client);
        } finally {
          if (client != null) {
            pool.release(client); // v1.7.0 Smart Release handles cleanup
          }
        }
      } on ValkeyConnectionException catch (e) {
        // Failover Handling: The mapped node is unreachable (Network error / Node down).
        lastError = e;
        attempts++;
        _log.warning(
            'Connection failed to mapped node. Refreshing topology... (Attempt $attempts/$_maxRedirects)');

        // Wait to allow cluster state to propagate/failover to complete.
        await Future<void>.delayed(_failoverWait);

        try {
          await _refreshTopology();
        } catch (refreshErr) {
          _log.severe('Topology refresh failed during failover: $refreshErr');
          // \ Loop again, maybe next attempt works or we hit maxRedirects
          // \ Get refresh error and continue loop to retry or fail by maxRedirects
        }
        continue;
      } on ValkeyServerException catch (e) {
        lastError = e;

        // Check for Redirection Errors
        final isMoved = e.message.startsWith('MOVED');
        final isAsk = e.message.startsWith('ASK');

        if (isMoved || isAsk) {
          attempts++;
          if (attempts > _maxRedirects) break; // Will throw at end

          // Parse Redirection: "MOVED <slot> <ip>:<port>"
          final parts = e.message.split(' ');

          if (parts.length < 3) rethrow; // Malformed error

          final slot = int.parse(parts[1]);
          final endpoint = parts[2];
          final endpointParts = endpoint.split(':');
          final targetHost = endpointParts[0];
          final targetPort = int.parse(endpointParts[1]);
          final targetNode =
              ClusterNodeInfo(host: targetHost, port: targetPort);

          if (isMoved) {
            // MOVED: 1. Update Slot Map, 2. Retry Loop
            _log.fine(
                'MOVED redirection: Slot $slot -> $targetHost:$targetPort');

            // Optimistically update the slot map for immediate correction
            _slotMap!.updateSlot(slot, targetNode);

            continue; // Retry with new node
          } else {
            // ASK: 1. ASKING, 2. Execute Command
            _log.fine('ASK redirection: Slot $slot -> $targetHost:$targetPort');
            return _executeAsk(targetNode, command);
          }
        }
        rethrow; // Other server errors (e.g., WRONGTYPE) are fatal
      } catch (e) {
        rethrow; // Unexpected errors
      }
    }

    throw ValkeyClientException(
        // 'Cluster operation failed after $attempts retries. Last error:
        // $lastError');
        'Cluster operation failed. Last error: $lastError');
  }

  /// Handles ASK redirection: Sends ASKING then the command to the target node.
  Future<T> _executeAsk<T>(ClusterNodeInfo targetNode,
      Future<T> Function(ValkeyClient client) command) async {
    final pool = _getOrCreatePool(targetNode);
    ValkeyClient? client;
    try {
      client = await pool.acquire();
      // 1. Send ASKING (before the actual command)
      await client.execute(['ASKING']);
      // 2. Send actual command
      return await command(client);
    } finally {
      if (client != null) {
        pool.release(client);
      }
    }
  }

  /// Refreshes the cluster topology by querying available nodes.
  ///
  /// This iterates through seed nodes and existing pool nodes, asking for
  /// `CLUSTER SLOTS`.
  /// It updates `_slotMap` and `_hostMap` upon success.
  Future<void> _refreshTopology({bool isInitial = false}) async {
    // 1. Gather candidates: Initial seeds (nodes) + Known active (pool) nodes
    final candidates = <ValkeyConnectionSettings>[..._initialNodes];

    // Add currently known active nodes (if any)
    if (!isInitial) {
      for (final nodeId in _nodePools.keys) {
        final parts = nodeId.split(':');
        if (parts.length == 2) {
          candidates.add(ValkeyConnectionSettings(
            // Get the host we are using to connect (e.g., '127.0.0.1')
            host: parts[0],
            port: int.parse(parts[1]),
            username: _defaultSettings.username,
            password: _defaultSettings.password,
            // Recommended: 2s for fast timeout for refresh/discovery
            commandTimeout: _defaultSettings.commandTimeout,
            connectTimeout: _defaultSettings.connectTimeout,
            // [v2.0.0] Inherit SSL settings for discovery candidates
            useSsl: _defaultSettings.useSsl,
            sslContext: _defaultSettings.sslContext,
            onBadCertificate: _defaultSettings.onBadCertificate,
          ));
        }
      }
    }

    // Shuffle to avoid hammering the same node or the dead node repeatedly
    candidates.shuffle();

    // 2. Query candidates: Try to fetch CLUSTER SLOTS from any candidate
    for (final nodeConfig in candidates) {
      ValkeyClient? tempClient;
      try {
        // Create a temporary client to one of the initial nodes
        tempClient = ValkeyClient(
          host: nodeConfig.host,
          port: nodeConfig.port,
          username: nodeConfig.username,
          password: nodeConfig.password,
          commandTimeout: nodeConfig.commandTimeout, // Recommended: 3s
          // connectTimeout: _defaultSettings.connectTimeout,
          // [v2.0.0] Use SSL for topology discovery connection
          useSsl: _defaultSettings.useSsl,
          sslContext: _defaultSettings.sslContext,
          onBadCertificate: _defaultSettings.onBadCertificate,
        );

        await tempClient.connect();
        // Fetch the cluster topology (v1.2.0 feature)
        final ranges = await tempClient.clusterSlots();

        // TODO: REVIEW REQUIRED -> REMOVE. NEED CONSENSUS.
        // if (ranges.isEmpty) {
        //   // This happens if the 'cluster-init' script failed
        //   throw ValkeyClientException(
        //       'CLUSTER SLOTS returned an empty topology. Is the cluster
        // stable?');
        // }

        if (ranges.isNotEmpty) {
          _log.info(
              'Topology refreshed via ${nodeConfig.host}:${nodeConfig.port}');

          // 3. NAT Mapping Discovery (Detection)
          _detectNatMapping(ranges, nodeConfig);

          // 4. Update Slot Map
          // Build the slot map (v1.3.0 Step 1)
          _slotMap = ClusterSlotMap.fromRanges(ranges);

          // TODO: REVIEW REQUIRED -> REMOVE. NEED CONSENSUS.
          // 5. Create connection pools for each master node
          // for (final node in _slotMap!.masterNodes) {
          //   _getOrCreatePool(node);
          // }

          return; // Success
        }
      }
      // TODO: REVIEW REQUIRED -> REMOVE. NEED CONSENSUS.
      // on ValkeyException {
      //   rethrow; // Re-throw known Valkey exceptions
      // }
      catch (e) {
        // Continue to next candidate (Try next candidate)

        // Log at fine level to avoid noise during normal failovers
        // _log.fine('Failed to refresh topology from
        // ${nodeConfig.host}:${nodeConfig.port}: $e');

        // throw ValkeyClientException('Failed to initialize cluster: $e');
      } finally {
        // Close the temporary client
        await tempClient?.close();
      }
    }

    throw ValkeyClientException(
        'Failed to refresh topology. All known nodes are unreachable.');
  }

  /// NAT Mapping Discovery
  ///
  /// Automatic NAT/Docker Mapping (v1.3.0)
  /// Helper to detect and register NAT mappings (Docker support).
  void _detectNatMapping(
      List<ClusterSlotRange> ranges, ValkeyConnectionSettings connectedNode) {
    // Find what the cluster calls the node we connected to.
    // Find the announced IP for the node we connected to
    String? announcedHost;

    // Find the 'announced' IP for the node we are currently connected to
    for (final range in ranges) {
      // Check master
      if (range.master.port == connectedNode.port) {
        announcedHost = range.master.host;
        break;
      }
      // Check replicas
      for (final r in range.replicas) {
        if (r.port == connectedNode.port) {
          announcedHost = r.host;
          break;
        }
      }
      if (announcedHost != null) break;
    }

    // TODO: REVIEW REQUIRED -> REMOVE. NEED CONSENSUS.
    // if (announcedHost == null) {
    //   throw ValkeyClientException(
    //     'Failed to find initial node ($initialHost:$initialPort) in CLUSTER
    //      SLOTS response.');
    // }

    // --- Keyman. Core Patch ---
    // If the announced IP differs from the connection IP: NAT.
    // \ Create the mapping rule if IPs don't match
    // \ e.g., if initialHost = '127.0.0.1' and announcedHost = '192.168.65.254'
    if (announcedHost != null && connectedNode.host != announcedHost) {
      // Only log if the user has enabled logging via ValkeyClient.setLogLevel()
      // \ We log this for debugging, using the client's static logger
      // \ ValkeyClient.setLogLevel(ValkeyLogLevel.info); // Ensure info is on
      _log.info(
          // 'Detected NAT/Docker environment: Mapping announced IP $announcedHost -> $initialHost'
          'NAT detected: Mapping Internal($announcedHost) -> '
          'External(${connectedNode.host})');
      _hostMap[announcedHost] = connectedNode.host;
    }
  }

  // --- Implemented Commands (Delegation from ValkeyCommandsBase) ---

  @override
  Future<String?> get(String key) =>
      _executeOnKey(key, (client) => client.get(key));

  @override
  Future<String> set(String key, String value) =>
      _executeOnKey(key, (client) => client.set(key, value));

  @override
  Future<int> del(String key) =>
      _executeOnKey(key, (client) => client.del(key));

  @override
  Future<int> exists(String key) =>
      _executeOnKey(key, (client) => client.exists(key));

  @override
  Future<String?> hGet(String key, String field) =>
      _executeOnKey(key, (client) => client.hGet(key, field));

  @override
  @Deprecated('Use [hGet] instead. This method will be removed in v4.0.0.')
  Future<String?> hget(String key, String field) => hGet(key, field);

  @override
  Future<int> hset(String key, String field, String value) =>
      _executeOnKey(key, (client) => client.hset(key, field, value));

  // --- STUBS for remaining ValkeyCommandsBase methods ---
  // (These must be implemented to satisfy the interface)

  // (Note: We must implement ALL methods from ValkeyCommandsBase here)
  // ... (hgetall, lpush, lpop, sadd, zadd, etc. follow the same pattern)
  // (Implementation of all other commands is omitted for brevity)

  @override
  Future<Map<String, String>> hgetall(String key) =>
      _executeOnKey(key, (client) => client.hgetall(key));
  @override
  Future<int> lpush(String key, String value) =>
      _executeOnKey(key, (client) => client.lpush(key, value));
  @override
  Future<int> rpush(String key, String value) =>
      _executeOnKey(key, (client) => client.rpush(key, value));
  @override
  Future<String?> lpop(String key) =>
      _executeOnKey(key, (client) => client.lpop(key));
  @override
  Future<String?> rpop(String key) =>
      _executeOnKey(key, (client) => client.rpop(key));
  @override
  Future<List<String?>> lrange(String key, int start, int stop) =>
      _executeOnKey(key, (client) => client.lrange(key, start, stop));
  @override
  Future<int> sadd(String key, String member) =>
      _executeOnKey(key, (client) => client.sadd(key, member));
  @override
  Future<int> srem(String key, String member) =>
      _executeOnKey(key, (client) => client.srem(key, member));
  @override
  Future<List<String?>> smembers(String key) =>
      _executeOnKey(key, (client) => client.smembers(key));
  @override
  Future<int> zadd(String key, double score, String member) =>
      _executeOnKey(key, (client) => client.zadd(key, score, member));
  @override
  Future<int> zrem(String key, String member) =>
      _executeOnKey(key, (client) => client.zrem(key, member));
  @override
  Future<List<String?>> zrange(String key, int start, int stop) =>
      _executeOnKey(key, (client) => client.zrange(key, start, stop));
  @override
  Future<int> expire(String key, int seconds) =>
      _executeOnKey(key, (client) => client.expire(key, seconds));
  @override
  Future<int> ttl(String key) =>
      _executeOnKey(key, (client) => client.ttl(key));

  // --- Atomic Counters ---
  @override
  Future<int> incr(String key) =>
      _executeOnKey(key, (client) => client.incr(key));
  @override
  Future<int> decr(String key) =>
      _executeOnKey(key, (client) => client.decr(key));
  @override
  Future<int> incrBy(String key, int amount) =>
      _executeOnKey(key, (client) => client.incrBy(key, amount));
  @override
  Future<int> decrBy(String key, int amount) =>
      _executeOnKey(key, (client) => client.decrBy(key, amount));

  @override
  Future<int> spublish(String channel, String message) =>
      // Sharded Pub/Sub routes based on the channel name's hash slot.
      _executeOnKey(channel, (client) => client.spublish(channel, message));

  // --- Multi-Key Commands (Multi-Node Scatter-Gather) ---

  @override
  Future<List<String?>> mget(List<String> keys) async {
    if (keys.isEmpty) return [];
    if (_slotMap == null || _isClosed) {
      throw ValkeyClientException(
          'Client is not connected. Call connect() first.');
    }

    // 1. Scatter: Group keys by node ID
    // Map<NodeId, List<originalIndex>>
    final nodeToIndices = <String, List<int>>{};
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final node = _slotMap!.getNodeForKey(key);
      if (node == null) {
        // If node mapping is missing, attempt one refresh to be safe
        await _refreshTopology();
        final newNode = _slotMap!.getNodeForKey(key);
        if (newNode == null) {
          throw ValkeyClientException('No node mapping found for key $key');
          // 'Could not find a master node for key "$key"
          //  (Slot: ${getHashSlot(key)}).'
        }
      }
      // Use non-nullable node after check
      final targetNode = _slotMap!.getNodeForKey(key)!;
      final nodeId = _getNodeId(targetNode);

      // Add the original index to the list for this node
      nodeToIndices.putIfAbsent(nodeId, () => []).add(i);
    }

    // 2. Execute: Send MGET commands to each node in parallel (Parallel
    //    requests to nodes)
    final futures = <Future<List<String?>>>[];
    final nodeIds = <String>[]; // To track which future belongs to which node

    for (final entry in nodeToIndices.entries) {
      final nodeId = entry.key;
      final indices = entry.value;

      // Extract the actual keys for this node
      final nodeKeys = indices.map((i) => keys[i]).toList();

      final pool = _nodePools[nodeId];
      if (pool == null) {
        throw ValkeyClientException(
            'No connection pool found for node $nodeId. '
            'Topology may be stale.');
      }

      // Launch async request
      futures.add(_executeBatchMultiget(
          pool, nodeKeys)); // Use instead of `_executeBatchMget`.
      nodeIds.add(nodeId);
    }

    // 3. Gather: Wait for all results and re-assemble in original order
    final results = await Future.wait(futures);
    final finalResult = List<String?>.filled(keys.length, null);

    for (var i = 0; i < results.length; i++) {
      final nodeResult = results[i];
      final nodeId = nodeIds[i];
      final originalIndices = nodeToIndices[nodeId]!;

      // TODO: REVIEW REQUIRED -> REMOVE. NEED CONSENSUS.
      // Sanity check
      // if (nodeResult.length != originalIndices.length) {
      //   throw ValkeyClientException(
      //       'MGET response length mismatch from node $nodeId. Expected
      //        ${originalIndices.length}, got ${nodeResult.length}.');
      // }

      // Map back to original positions
      for (var j = 0; j < originalIndices.length; j++) {
        final originalIndex = originalIndices[j];
        finalResult[originalIndex] = nodeResult[j];
      }
    }

    return finalResult;
  }

  // Helper to execute MGET on a specific pool
  // Future<List<String?>> _executeBatchMget(
  //     ValkeyPool pool, List<String> keys) async {
  //   ValkeyClient? client;
  //   try {
  //     client = await pool.acquire();
  //     return await client.mget(keys); // e: CROSSSLOT
  //   } finally {
  //     if (client != null) {
  //       pool.release(client);
  //     }
  //   }
  // }

  /// Helper to execute MGET logic on a specific pool using Pipelining.
  ///
  /// Instead of sending a single 'MGET' command (which fails with CROSSSLOT
  /// if keys belong to different slots), we send multiple 'GET' commands
  /// in a pipeline (concurrently) on the same connection.
  Future<List<String?>> _executeBatchMultiget(
      ValkeyPool pool, List<String> keys) async {
    ValkeyClient? client;
    try {
      client = await pool.acquire();

      // Pipelining: Send multiple GETs without awaiting individually
      // \ Use Pipelining (multiple GETs) instead of MGET
      // \ This avoids CROSSSLOT errors while maintaining high performance
      // \ because ValkeyClient queues these commands and sends them in a batch.
      final futures = keys.map((key) => client!.get(key));

      return await Future.wait(futures);
    } finally {
      if (client != null) {
        pool.release(client);
      }
    }
  }

  // --- Admin / Misc ---

  @override
  Future<String> echo(String message) async {
    if (_nodePools.isEmpty) {
      throw ValkeyClientException(
          'Client is not connected.'); // Call connect() first.
    }

    // ECHO is stateless; execute on any available pool (e.g., first one)
    // \ Execute on the first available pool
    //   \ - ECHO does not depend on a key slot.
    //   \ - We can execute it on any available node. We pick the first one.
    final pool = _nodePools.values.first;

    ValkeyClient? client;
    try {
      client = await pool.acquire();
      return await client.echo(message);
    } finally {
      if (client != null) {
        pool.release(client);
      }
    }
  }

  // --- Commands that doesn't exist on the base ---

  // --- Cluster-specific Admin Commands ---

  @override
  Future<Map<String, String>> pingAll([String? message]) async {
    final results = <String, String>{};
    // Iterate over all active pools (Masters)
    for (final entry in _nodePools.entries) {
      final nodeId = entry.key; // e.g., '127.0.0.1:7001'
      final pool = entry.value;

      ValkeyClient? client;
      try {
        client = await pool.acquire();
        results[nodeId] = await client.ping(message);
      } catch (e) {
        results[nodeId] = 'Error: $e';
      } finally {
        if (client != null) {
          pool.release(client);
        }
      }
    }
    return results;
  }

  // --- Pub/Sub (Sharded) ---

  @override
  Subscription ssubscribe(List<String> channels) {
    if (_slotMap == null || _isClosed) {
      throw ValkeyClientException('Client is not connected.');
    }

    // 1. Scatter: Group channels by Node
    final nodeToChannels = <String, List<String>>{};
    for (final channel in channels) {
      final node = _slotMap!.getNodeForKey(channel);
      if (node == null) {
        throw ValkeyClientException(
            'Could not find node for channel "$channel"');
      }
      final nodeId = _getNodeId(node);
      nodeToChannels.putIfAbsent(nodeId, () => []).add(channel);
    }

    // 2. Gather: Subscribe per node
    final shardSubs = <Subscription>[];
    final controller = StreamController<ValkeyMessage>();
    final readyFutures = <Future<void>>[];
    final acquiredClients = <ValkeyClient>[];

    // Create subscriptions per node
    for (final entry in nodeToChannels.entries) {
      final nodeId = entry.key;
      final shardChannels = entry.value;
      final pool = _nodePools[nodeId];

      if (pool == null) continue;

      // Async setup
      final setupFuture = () async {
        try {
          // Acquire a dedicated client for subscription
          final client = await pool.acquire();
          acquiredClients.add(client);

          final sub = client.ssubscribe(shardChannels);
          shardSubs.add(sub);

          // Forward messages to the main controller
          sub.messages.listen(
            // (msg) => controller.add(msg),
            // onError: (e) => controller.addError(e),
            controller.add,
            onError: controller.addError,
            // Do not close controller on single shard done
          );

          return sub.ready;
        } catch (e) {
          controller.addError(e);
          rethrow;
        }
      }();

      readyFutures.add(setupFuture.then((_) {}));
    }

    // 3. Return Composite Subscription
    return _ClusterSubscription(
      shardSubs,
      controller,
      Future.wait(readyFutures),
      acquiredClients,
    );
  }

  @override
  Future<void> sunsubscribe([List<String> channels = const []]) async {
    // TODO: REVIEW REQUIRED -> FIND BETTER APPROACH. NEED CONSENSUS.
    _log.warning(
        'Cluster sunsubscribe: Please use subscription.unsubscribe() instead '
        'for proper resource cleanup.');
  }

  // --- Inspection Helper (v1.5.0 Feature) ---
  /// Returns the [ClusterNodeInfo] of the master node that currently owns
  /// [key].
  /// Returns `null` if the client is not connected or the map is not loaded.
  ///
  /// This relies on the client's cached slot map, which is updated
  /// automatically when MOVED redirections occur.
  ClusterNodeInfo? getMasterFor(String key) => _slotMap?.getNodeForKey(key);

  /// DEBUG ONLY: Manually corrupts the slot map to test redirection logic.
  /// See `test/valkey_cluster_redirection_test.dart`
  void debugCorruptSlotMap(String key, int wrongPort) {
    final slot = getHashSlot(key);
    // Point this slot to a wrong port (e.g., 7005 instead of 7001)
    // Assume localhost/127.0.0.1 for testing convenience
    final wrongNode = ClusterNodeInfo(host: '127.0.0.1', port: wrongPort);
    _slotMap!.updateSlot(slot, wrongNode);
  }
}

/// Internal wrapper to manage subscriptions distributed across multiple
/// cluster nodes.
class _ClusterSubscription implements Subscription {
  final List<Subscription> _shardSubs;
  final StreamController<ValkeyMessage> _controller;
  final Future<void> _allReady;

  /// Clients to close
  ///
  /// Clients that are held by this subscription.
  /// They must be closed/released when unsubscribing.
  final List<ValkeyClient> _clients;

  _ClusterSubscription(
      this._shardSubs, this._controller, this._allReady, this._clients);

  @override
  Stream<ValkeyMessage> get messages => _controller.stream;

  @override
  Future<void> get ready => _allReady;

  @override
  Future<void> unsubscribe() async {
    // 1. Send unsubscribe commands (Delegate to children)
    await Future.wait(_shardSubs.map((s) => s.unsubscribe()));

    // 2. Close the controller
    await _controller.close();

    // 3. Clean up clients
    // Since v1.7.0, ValkeyPool detects closed/dirty clients.
    // We close them here, and the pool (if tracking them) handles the rest
    // or garbage collection takes over.
    for (final client in _clients) {
      await client.close(); // Discarded by pool logic or GC
    }
  }
}
