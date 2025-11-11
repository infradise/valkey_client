import 'dart:async';
import 'package:valkey_client/valkey_client.dart';
// import 'package:valkey_client/valkey_cluster_client_base.dart';
import 'package:valkey_client/src/cluster_hash.dart';
import 'package:valkey_client/src/cluster_slot_map.dart';

/// The concrete implementation of [ValkeyClusterClientBase].
///
/// This client manages connections to all master nodes in a Valkey Cluster,
/// automatically routing commands to the correct node based on the key's hash slot.
class ValkeyClusterClient implements ValkeyClusterClientBase {
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

  ValkeyClusterClient(
    List<ValkeyConnectionSettings> initialNodes,
  )   : _initialNodes = initialNodes,
        _defaultSettings = initialNodes.first {
    if (initialNodes.isEmpty) {
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

    ValkeyClient? tempClient;
    try {
      // 1. Create a temporary client to one of the initial nodes
      tempClient = ValkeyClient(
        host: _defaultSettings.host,
        port: _defaultSettings.port,
        commandTimeout: _defaultSettings.commandTimeout,
      );
      await tempClient.connect();

      // 2. Fetch the cluster topology (v1.2.0 feature)
      final ranges = await tempClient.clusterSlots();

      // 3. Build the slot map (v1.3.0 Step 1)
      final slotMap = ClusterSlotMap.fromRanges(ranges);
      _slotMap = slotMap;

      // 4. Create connection pools for each master node
      for (final node in slotMap.masterNodes) {
        final nodeSettings = ValkeyConnectionSettings(
          host: node.host,
          port: node.port,
          commandTimeout: _defaultSettings.commandTimeout,
          // Note: Auth settings would need to be passed here if required
        );
        final pool = ValkeyPool(connectionSettings: nodeSettings);
        _nodePools[_getNodeId(node)] = pool;
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
  String _getNodeId(ClusterNodeInfo node) => '${node.host}:${node.port}';

  /// Internal helper to acquire, run, and release a client from the correct pool.
  /// This is the core of the routing logic.
  Future<T> _executeOnKey<T>(
      String key, Future<T> Function(ValkeyClient client) command) async {
    if (_slotMap == null || _isClosed) {
      throw ValkeyClientException(
          'Client is not connected. Call connect() first.');
    }

    // 1. Find the correct node for this key
    final node = _slotMap!.getNodeForKey(key);
    if (node == null) {
      throw ValkeyClientException(
          'Could not find a master node for key "$key" (Slot: ${getHashSlot(key)}).');
    }

    // 2. Find the correct pool for that node
    final pool = _nodePools[_getNodeId(node)];
    if (pool == null) {
      throw ValkeyClientException(
          'No connection pool found for node ${_getNodeId(node)}. Topology may be stale.');
    }

    // 3. Acquire, execute, and release
    ValkeyClient? client;
    try {
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
  Future<String?> get(String key) => _executeOnKey(key, (client) => client.get(key));

  @override
  Future<String> set(String key, String value) => _executeOnKey(key, (client) => client.set(key, value));

  @override
  Future<int> del(String key) => _executeOnKey(key, (client) => client.del(key));

  @override
  Future<int> exists(String key) => _executeOnKey(key, (client) => client.exists(key));

  @override
  Future<String?> hget(String key, String field) => _executeOnKey(key, (client) => client.hget(key, field));

  @override
  Future<int> hset(String key, String field, String value) => _executeOnKey(key, (client) => client.hset(key, field, value));

  // (Note: We must implement ALL methods from ValkeyCommandsBase here)
  // ... (hgetall, lpush, lpop, sadd, zadd, etc. follow the same pattern)
  // (Implementation of all other commands is omitted for brevity)

  // --- Example: A command that doesn't exist on the base ---
  @override
  Future<Map<String, String>> pingAll([String? message]) async {
    final Map<String, String> results = {};
    for (final entry in _nodePools.entries) {
      final nodeId = entry.key;
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
  Future<Map<String, String>> hgetall(String key) => _executeOnKey(key, (client) => client.hgetall(key));
  @override
  Future<int> lpush(String key, String value) => _executeOnKey(key, (client) => client.lpush(key, value));
  @override
  Future<List<String?>> lrange(String key, int start, int stop) => _executeOnKey(key, (client) => client.lrange(key, start, stop));
  @override
  Future<String?> lpop(String key) => _executeOnKey(key, (client) => client.lpop(key));
  @override
  Future<int> rpush(String key, String value) => _executeOnKey(key, (client) => client.rpush(key, value));
  @override
  Future<String?> rpop(String key) => _executeOnKey(key, (client) => client.rpop(key));
  @override
  Future<int> sadd(String key, String member) => _executeOnKey(key, (client) => client.sadd(key, member));
  @override
  Future<List<String?>> smembers(String key) => _executeOnKey(key, (client) => client.smembers(key));
  @override
  Future<int> srem(String key, String member) => _executeOnKey(key, (client) => client.srem(key, member));
  @override
  Future<int> zadd(String key, double score, String member) => _executeOnKey(key, (client) => client.zadd(key, score, member));
  @override
  Future<List<String?>> zrange(String key, int start, int stop) => _executeOnKey(key, (client) => client.zrange(key, start, stop));
  @override
  Future<int> zrem(String key, String member) => _executeOnKey(key, (client) => client.zrem(key, member));
  @override
  Future<int> expire(String key, int seconds) => _executeOnKey(key, (client) => client.expire(key, seconds));
  @override
  Future<int> ttl(String key) => _executeOnKey(key, (client) => client.ttl(key));

  @override
  Future<List<String?>> mget(List<String> keys) {
    // MGET is complex as keys can span multiple nodes.
    // This requires a "scatter-gather" operation.
    // Stubbed for v1.3.0, requires separate implementation.
    throw UnimplementedError('MGET (multi-node scatter-gather) is not yet implemented in v1.3.0 and is planned for v1.4.0.');
  }
}