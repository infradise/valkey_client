import 'dart:async';
import 'package:valkey_client/valkey_client.dart';
// import 'package:valkey_client/valkey_cluster_client_base.dart';
import 'cluster_hash.dart';
import 'cluster_slot_map.dart';
import 'logging.dart';

/// The concrete implementation of [ValkeyClusterClientBase].
///
/// This client manages connections to all master nodes in a Valkey Cluster,
/// automatically routing commands to the correct node based on the key's hash slot.
class ValkeyClusterClient implements ValkeyClusterClientBase {
  static final _log = ValkeyLogger('ValkeyClusterClient');

  /// The initial nodes to connect to for discovering the cluster topology.
  final List<ValkeyConnectionSettings> _initialNodes;

  /// The connection settings (like timeout) to use for all pooled connections.
  /// (We take the settings from the *first* initial node).
  final ValkeyConnectionSettings _defaultSettings;

  /// Maximum number of redirections allowed before throwing an exception.
  final int _maxRedirects; // (v1.5.0+)

  /// Manages the mapping of slots to nodes.
  /// This is the "brain" of the router.
  ClusterSlotMap? _slotMap;

  /// A map of connection pools, one for each master node.
  /// The key is the node's unique ID (e.g., "host:port").
  final Map<String, ValkeyPool> _nodePools = {};

  bool _isClosed = false;

  /// Stores the NAT mapping rule, e.g., {'192.168.65.254': '127.0.0.1'}
  Map<String, String> _hostMap = {};

  ValkeyClusterClient(
    this._initialNodes, {
    int maxRedirects = 5, // Default to 5 (v1.5.0+)
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

    _hostMap = {}; // Reset map on (re)connect

    ValkeyClient? tempClient;
    try {
      // 1-1. Get the host we are using to connect (e.g., '127.0.0.1')
      final initialHost = _defaultSettings.host; // e.g., '127.0.0.1'
      final initialPort = _defaultSettings.port; // e.g., 7001

      // 1-2. Create a temporary client to one of the initial nodes
      tempClient = ValkeyClient(
        host: initialHost,
        port: initialPort,
        commandTimeout: _defaultSettings.commandTimeout,
      );
      await tempClient.connect();

      // 2. Fetch the cluster topology (v1.2.0 feature)
      final ranges = await tempClient.clusterSlots();
      if (ranges.isEmpty) {
        // This happens if the 'cluster-init' script failed
        throw ValkeyClientException(
            'CLUSTER SLOTS returned an empty topology. Is the cluster stable?');
      }

      // --- BEGIN: Automatic NAT/Docker Mapping (v1.3.0) ---

      // 3. Find what the cluster calls the node we connected to.
      //    Find the announced IP for the node we connected to
      String? announcedHost;
      for (final range in ranges) {
        // Check master
        if (range.master.port == initialPort) {
          announcedHost = range.master.host;
          break;
        }
        // Check replicas
        for (final replica in range.replicas) {
          if (replica.port == initialPort) {
            announcedHost = replica.host;
            break;
          }
        }
        if (announcedHost != null) break;
      }

      if (announcedHost == null) {
        throw ValkeyClientException(
            'Failed to find initial node ($initialHost:$initialPort) in CLUSTER SLOTS response.');
      }

      // --- Keyman. Core Patch ---
      // 4. Create the mapping rule if IPs don't match
      // e.g., if initialHost = '127.0.0.1' and announcedHost = '192.168.65.254'
      if (initialHost != announcedHost) {
        // Only log if the user has enabled logging via ValkeyClient.setLogLevel()
        // \ We log this for debugging, using the client's static logger
        // \ ValkeyClient.setLogLevel(ValkeyLogLevel.info); // Ensure info is on
        _log.info(
            'Detected NAT/Docker environment: Mapping announced IP $announcedHost -> $initialHost');
        _hostMap[announcedHost] = initialHost;
      }

      // --- END: Automatic NAT/Docker Mapping ---

      // 5. Build the slot map (v1.3.0 Step 1)
      // final slotMap = ClusterSlotMap.fromRanges(ranges);
      // _slotMap = slotMap;
      _slotMap = ClusterSlotMap.fromRanges(ranges);

      // 6. Create connection pools for each master node
      for (final node in _slotMap!.masterNodes) {
        _getOrCreatePool(node);
      }
    } on ValkeyException {
      rethrow; // Re-throw known Valkey exceptions
    } catch (e) {
      throw ValkeyClientException('Failed to initialize cluster: $e');
    } finally {
      // 5. Close the temporary client
      await tempClient?.close();
    }
  }

  /// Helper to get or create a connection pool for a node.
  /// Applies Auto-NAT mapping.
  ValkeyPool _getOrCreatePool(ClusterNodeInfo node) {
    // for (final node in slotMap.masterNodes) {
    // node.host = '192.168.65.254', node.port = 7001, 7002, 7003

    // --- BEGIN FIX (v1.3.0) ---
    // Apply host mapping if provided
    // node.host here is '192.168.65.254'
    // final mappedHost = hostMapper?.call(node.host) ?? node.host; // It works too.
    // Apply mapping rule: Get '127.0.0.1' if it exists, otherwise use original
    // Apply the mapping rule CONSISTENTLY
    final mappedHost =
        _hostMap[node.host] ?? node.host; // '127.0.0.1' (Correct)
    // mappedHost is now '127.0.0.1'
    // --- END FIX ---

    final nodeId =
        '$mappedHost:${node.port}'; // Key is '127.0.0.1:7002' (Correct pool ID)

    if (_nodePools.containsKey(nodeId)) {
      // continue;
      return _nodePools[nodeId]!;
    }

    final nodeSettings = ValkeyConnectionSettings(
      host: mappedHost, // Use the MAPPED host (e.g., '127.0.0.1')
      port: node.port, // Use the correct port (e.g., 7002)
      commandTimeout: _defaultSettings.commandTimeout,
      // Note: Auth settings would need to be passed here if required
    );

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

  /// Helper to get a unique string ID for a node.
  String _getNodeId(ClusterNodeInfo node) {
    // Apply the auto-discovered mapping
    // This method MUST consistently use the same _hostMap
    // as the connect() method.
    // This method now *only* uses the automatic _hostMap.
    final mappedHost = _hostMap[node.host] ?? node.host;
    return '$mappedHost:${node.port}';
  }

  /// Internal helper to acquire, run, and release a client from the correct pool.
  /// This is the core of the routing logic.
  Future<T> _executeOnKey<T>(
      String key, Future<T> Function(ValkeyClient client) command) async {
    if (_slotMap == null || _isClosed) {
      throw ValkeyClientException(
          'Client is not connected. Call connect() first.');
    }

    int redirects = 0;

    // v1.5.0+: Retry Loop for Redirections
    while (true) {
      try {
        // 1. Find the correct node for this key (node.host will be '192.168.65.254')
        final node = _slotMap!.getNodeForKey(key);
        if (node == null) {
          throw ValkeyClientException(
              'Could not find a master node for key "$key" (Slot: ${getHashSlot(key)}).');
        }

        // // 2-1. Get the MAPPED pool ID (e.g., '127.0.0.1:7002')
        // final poolId = _getNodeId(node);
        // // 2-2. Find the correct pool for that node
        // final pool = _nodePools[poolId];
        // 2. Get the pool
        final pool = _getOrCreatePool(node);

        // TODO: REVIEW REQUIRED.
        // if (pool == null) {
        //   throw ValkeyClientException(
        //       'No connection pool found for node $poolId. Topology may be stale.');
        // }

        // 3. Acquire, execute, and release
        ValkeyClient? client;
        try {
          // The pool will connect to '127.0.0.1:7002'
          client = await pool.acquire();
          return await command(client);
        } finally {
          if (client != null) {
            pool.release(client);
          }
        }
      } on ValkeyServerException catch (e) {
        // Check for Redirection Errors
        final isMoved = e.message.startsWith('MOVED');
        final isAsk = e.message.startsWith('ASK');

        if (isMoved || isAsk) {
          redirects++;
          if (redirects > _maxRedirects) {
            throw ValkeyClientException(
                'Too many redirects ($redirects > $_maxRedirects). Last error: ${e.message}');
          }

          // Parse "MOVED <slot> <ip>:<port>"
          final parts = e.message.split(' ');

          // if (parts.length < 3) throw e; // Malformed error
          // TODO: REVIEW REQUIRED.
          if (parts.length < 3) rethrow; // Malformed error

          final slot = int.parse(parts[1]);
          final endpoint = parts[2];
          final endpointParts = endpoint.split(':');
          final targetHost = endpointParts[0];
          final targetPort = int.parse(endpointParts[1]);

          // Apply NAT mapping to the new target if needed
          // If we already have a mapping for this host, use it.
          // If not, we might be discovering a new NAT IP?
          // For simplicity, we check if targetHost matches our known 'announcedHost'
          // But here we just assume standard mapping logic applies.
          if (_hostMap.containsKey(targetHost)) {
            // Use existing mapping
          } else {
            // New host discovered? In simple NAT scenarios (like Docker),
            // all internal IPs usually map to the same external IP (localhost).
            // Heuristic: If we have *any* mapping, apply the targetHost -> mappedHost rule?
            // For now, let's stick to explicit _hostMap.
            // If targetHost is new, _getOrCreatePool will use it as is.
          }

          final targetNode =
              ClusterNodeInfo(host: targetHost, port: targetPort);

          if (isMoved) {
            // MOVED: 1. Update Slot Map, 2. Retry Loop
            _log.fine(
                'MOVED redirection: Slot $slot -> $targetHost:$targetPort');

            // We need to update the _slotMap to point this slot to targetNode
            // Note: ClusterSlotMap is currently immutable-ish in our implementation.
            // We should add a method to update it or create a mutable version.
            // For now, let's assume we add an update method to ClusterSlotMap or replace it.
            _slotMap!.updateSlot(slot, targetNode);

            continue; // Retry the loop (will use new map)
          } else {
            // ASK: 1. ASKING, 2. Execute Command
            _log.fine('ASK redirection: Slot $slot -> $targetHost:$targetPort');
            // return await _executeAsk(targetNode, command);
            // FIXME: REVIEW REQUIRED.
            return _executeAsk(targetNode, command);
          }
        }
        rethrow; // Other server errors
      }
    }
  }

  /// Handles ASK redirection: Sends ASKING then the command to the target node.
  Future<T> _executeAsk<T>(ClusterNodeInfo targetNode,
      Future<T> Function(ValkeyClient client) command) async {
    final pool = _getOrCreatePool(targetNode);
    ValkeyClient? client;
    try {
      client = await pool.acquire();
      // 1. Send ASKING
      await client.execute(['ASKING']);
      // 2. Send actual command
      return await command(client);
    } finally {
      if (client != null) {
        pool.release(client);
      }
    }
  }

  // --- Implemented Commands (from ValkeyCommandsBase) ---

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
  Future<String?> hget(String key, String field) =>
      _executeOnKey(key, (client) => client.hget(key, field));

  @override
  Future<int> hset(String key, String field, String value) =>
      _executeOnKey(key, (client) => client.hset(key, field, value));

  // (Note: We must implement ALL methods from ValkeyCommandsBase here)
  // ... (hgetall, lpush, lpop, sadd, zadd, etc. follow the same pattern)
  // (Implementation of all other commands is omitted for brevity)

  // --- Example: A command that doesn't exist on the base ---
  // --- Cluster-specific Admin Commands ---
  @override
  Future<Map<String, String>> pingAll([String? message]) async {
    final Map<String, String> results = {};
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

  // --- STUBS for remaining ValkeyCommandsBase methods ---
  // (These must be implemented to satisfy the interface)

  @override
  Future<Map<String, String>> hgetall(String key) =>
      _executeOnKey(key, (client) => client.hgetall(key));
  @override
  Future<int> lpush(String key, String value) =>
      _executeOnKey(key, (client) => client.lpush(key, value));
  @override
  Future<List<String?>> lrange(String key, int start, int stop) =>
      _executeOnKey(key, (client) => client.lrange(key, start, stop));
  @override
  Future<String?> lpop(String key) =>
      _executeOnKey(key, (client) => client.lpop(key));
  @override
  Future<int> rpush(String key, String value) =>
      _executeOnKey(key, (client) => client.rpush(key, value));
  @override
  Future<String?> rpop(String key) =>
      _executeOnKey(key, (client) => client.rpop(key));
  @override
  Future<int> sadd(String key, String member) =>
      _executeOnKey(key, (client) => client.sadd(key, member));
  @override
  Future<List<String?>> smembers(String key) =>
      _executeOnKey(key, (client) => client.smembers(key));
  @override
  Future<int> srem(String key, String member) =>
      _executeOnKey(key, (client) => client.srem(key, member));
  @override
  Future<int> zadd(String key, double score, String member) =>
      _executeOnKey(key, (client) => client.zadd(key, score, member));
  @override
  Future<List<String?>> zrange(String key, int start, int stop) =>
      _executeOnKey(key, (client) => client.zrange(key, start, stop));
  @override
  Future<int> zrem(String key, String member) =>
      _executeOnKey(key, (client) => client.zrem(key, member));
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

  @override
  Future<String> echo(String message) async {
    if (_nodePools.isEmpty) {
      throw ValkeyClientException(
          'Client is not connected. Call connect() first.');
    }

    // ECHO does not depend on a key slot.
    // We can execute it on any available node. We pick the first one.
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

  @override
  Subscription ssubscribe(List<String> channels) {
    if (_slotMap == null || _isClosed) {
      throw ValkeyClientException('Client is not connected.');
    }

    // 1. Scatter: Group channels by Node
    final Map<String, List<String>> nodeToChannels = {};
    for (final channel in channels) {
      final node = _slotMap!.getNodeForKey(channel);
      if (node == null) {
        throw ValkeyClientException('Could not find node for channel $channel');
      }
      final nodeId = _getNodeId(node);
      nodeToChannels.putIfAbsent(nodeId, () => []).add(channel);
    }

    // 2. Gather: Subscribe per node
    final List<Subscription> shardSubs = [];
    final StreamController<ValkeyMessage> controller = StreamController();
    final List<Future<void>> readyFutures = [];
    final List<ValkeyClient> acquiredClients = [];

    for (final entry in nodeToChannels.entries) {
      final nodeId = entry.key;
      final shardChannels = entry.value;
      final pool = _nodePools[nodeId];

      if (pool == null) continue;

      // Async setup
      final setupFuture = () async {
        try {
          // Acquire client (Will act as dedicated connection)
          final client = await pool.acquire();
          acquiredClients.add(client);

          // SSUBSCRIBE
          final sub = client.ssubscribe(shardChannels);
          shardSubs.add(sub);

          // Forward Messages
          sub.messages.listen(
            (msg) => controller.add(msg),
            onError: (e) => controller.addError(e),
            // Don't close controller on single shard done
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
    _log.warning(
        'Cluster sunsubscribe: Please use subscription.unsubscribe() instead.');
    // Best effort logic could go here, but for v1.6.0 we rely on the object.
  }

  // @override
  // Future<List<String?>> mget(List<String> keys) async {
  //   // MGET is complex as keys can span multiple nodes.
  //   // This requires a "scatter-gather" operation.
  //   // Stubbed for v1.3.0, requires separate implementation.
  //   throw UnimplementedError(
  //       'MGET (multi-node scatter-gather) is not yet implemented in v1.3.0 and is planned for v1.4.0.');
  // }

  @override
  Future<List<String?>> mget(List<String> keys) async {
    if (keys.isEmpty) return [];

    if (_slotMap == null || _isClosed) {
      throw ValkeyClientException(
          'Client is not connected. Call connect() first.');
    }

    // 1. Scatter: Group keys by node ID
    // Map<NodeId, List<originalIndex>>
    final Map<String, List<int>> nodeToIndices = {};

    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final node = _slotMap!.getNodeForKey(key);
      if (node == null) {
        throw ValkeyClientException(
            'Could not find a master node for key "$key" (Slot: ${getHashSlot(key)}).');
      }

      // TODO: REVIEW REQUIRED.
      final nodeId = _getNodeId(node);

      // Add the original index to the list for this node
      nodeToIndices.putIfAbsent(nodeId, () => []).add(i);
    }

    // 2. Execute: Send MGET commands to each node in parallel
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
            'No connection pool found for node $nodeId. Topology may be stale.');
      }

      // Launch async request
      // futures.add(_executeBatchMget(pool, nodeKeys));
      futures.add(_executeBatchMultiget(pool, nodeKeys));
      nodeIds.add(nodeId);
    }

    // 3. Gather: Wait for all results and re-assemble in original order
    final List<List<String?>> results = await Future.wait(futures);
    final finalResult = List<String?>.filled(keys.length, null);

    for (var i = 0; i < results.length; i++) {
      final nodeResult = results[i];
      final nodeId = nodeIds[i];
      final originalIndices = nodeToIndices[nodeId]!;

      // Sanity check
      if (nodeResult.length != originalIndices.length) {
        throw ValkeyClientException(
            'MGET response length mismatch from node $nodeId. Expected ${originalIndices.length}, got ${nodeResult.length}.');
      }

      // Map back to original positions
      for (var j = 0; j < originalIndices.length; j++) {
        final originalIndex = originalIndices[j];
        finalResult[originalIndex] = nodeResult[j];
      }
    }

    return finalResult;
  }

  /// Helper to execute MGET on a specific pool
  // Future<List<String?>> _executeBatchMget(
  //     ValkeyPool pool, List<String> keys) async {
  //   ValkeyClient? client;
  //   try {
  //     client = await pool.acquire();
  //     return await client.mget(keys);
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

      // FIX: Use Pipelining (multiple GETs) instead of MGET
      // This avoids CROSSSLOT errors while maintaining high performance
      // because ValkeyClient queues these commands and sends them in a batch.
      final futures = keys.map((key) => client!.get(key));

      return await Future.wait(futures);
    } finally {
      if (client != null) {
        pool.release(client);
      }
    }
  }

  // --- Inspection Helper (v1.5.0 Feature) ---
  /// Returns the [ClusterNodeInfo] of the master node that currently owns [key].
  /// Returns `null` if the client is not connected or the map is not loaded.
  ///
  /// This relies on the client's cached slot map, which is updated automatically
  /// when MOVED redirections occur.
  ClusterNodeInfo? getMasterFor(String key) => _slotMap?.getNodeForKey(key);

  // TESTING ONLY (test/valkey_cluster_redirection_test.dart)
  void debugCorruptSlotMap(String key, int wrongPort) {
    final slot = getHashSlot(key);
    // Point this slot to a wrong port (e.g., 7005 instead of 7001)
    // We assume localhost/127.0.0.1 for simplicity in tests
    final wrongNode = ClusterNodeInfo(host: '127.0.0.1', port: wrongPort);
    _slotMap!.updateSlot(slot, wrongNode);
  }
}

/// Helper class to manage multi-node subscriptions
class _ClusterSubscription implements Subscription {
  final List<Subscription> _shardSubs;
  final StreamController<ValkeyMessage> _controller;
  final Future<void> _allReady;
  final List<ValkeyClient> _clients; // Clients to close

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

    // 3. Hard-close clients to avoid polluting the pool (v1.6.0 workaround)
    // In v1.7.0, we will use pool.discard() or similar.
    for (final client in _clients) {
      await client.close();
    }
  }
}
