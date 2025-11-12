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
    this._initialNodes,
  ) : _defaultSettings = _initialNodes.first {
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
        // We log this for debugging, using the client's static logger
        ValkeyClient.setLogLevel(ValkeyLogLevel.info); // Ensure info is on
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

        final nodeSettings = ValkeyConnectionSettings(
          host: mappedHost, // Use the MAPPED host (e.g., '127.0.0.1')
          port: node.port, // Use the correct port (e.g., 7002)
          commandTimeout: _defaultSettings.commandTimeout,
          // Note: Auth settings would need to be passed here if required
        );

        final nodeId =
            '$mappedHost:${node.port}'; // Key is '127.0.0.1:7002' (Correct pool ID)
        if (_nodePools.containsKey(nodeId)) continue;

        final pool = ValkeyPool(connectionSettings: nodeSettings);
        _nodePools[nodeId] = pool;
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

    // 1. Find the correct node for this key (node.host will be '192.168.65.254')
    final node = _slotMap!.getNodeForKey(key);
    if (node == null) {
      throw ValkeyClientException(
          'Could not find a master node for key "$key" (Slot: ${getHashSlot(key)}).');
    }

    // 2-1. Get the MAPPED pool ID (e.g., '127.0.0.1:7002')
    final poolId = _getNodeId(node);
    // 2-2. Find the correct pool for that node
    final pool = _nodePools[poolId];
    if (pool == null) {
      throw ValkeyClientException(
          'No connection pool found for node $poolId. Topology may be stale.');
    }

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

  @override
  Future<List<String?>> mget(List<String> keys) async {
    // MGET is complex as keys can span multiple nodes.
    // This requires a "scatter-gather" operation.
    // Stubbed for v1.3.0, requires separate implementation.
    throw UnimplementedError(
        'MGET (multi-node scatter-gather) is not yet implemented in v1.3.0 and is planned for v1.4.0.');
  }
}
