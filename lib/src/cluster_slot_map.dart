import 'cluster_info.dart' show ClusterNodeInfo, ClusterSlotRange;
import 'cluster_hash.dart' show getHashSlot;
import 'logging.dart';

/// Manages the mapping of hash slots to cluster nodes.
///
/// This class is immutable. A new instance must be created
/// if the cluster topology changes (e.g., after a -MOVED redirection).
class ClusterSlotMap {
  static final _log = ValkeyLogger('ClusterSlotMap');

  /// A fast lookup map from a slot number (0-16383) to its master node.
  final Map<int, ClusterNodeInfo> _slotToNode;

  /// A set of all unique master nodes in the cluster.
  final Set<ClusterNodeInfo> masterNodes;

  ClusterSlotMap._(this._slotToNode, this.masterNodes);

  /// Creates a new [ClusterSlotMap] from a 'CLUSTER SLOTS' response.
  factory ClusterSlotMap.fromRanges(List<ClusterSlotRange> ranges) {
    final Map<int, ClusterNodeInfo> slotMap = {};
    final Set<ClusterNodeInfo> nodes = {};

    for (final range in ranges) {
      nodes.add(range.master); // Add master to the set of nodes
      // Populate the map for every slot in the range
      for (int slot = range.startSlot; slot <= range.endSlot; slot++) {
        slotMap[slot] = range.master;
      }
    }
    return ClusterSlotMap._(slotMap, nodes);
  }

  /// Gets the master node responsible for the given [key].
  ///
  /// Returns null if the key's slot is not in the map.
  ClusterNodeInfo? getNodeForKey(String key) {
    _log.info('key = $key');
    final slot = getHashSlot(key);
    _log.info('slot = $slot');
    return _slotToNode[slot];
  }

  /// Updates the mapping for a specific [slot] to [newNode].
  /// Used when a MOVED redirection occurs.
  void updateSlot(int slot, ClusterNodeInfo newNode) {
    // v1.5.0 Feature
    _slotToNode[slot] = newNode;
    masterNodes.add(newNode); // Ensure the new node is in the set of masters
  }
}
