/// Represents a single node (Master or Replica) in the Valkey cluster.
class ClusterNodeInfo {
  final String host;
  final int port;
  final String? id;

  ClusterNodeInfo({required this.host, required this.port, this.id});

  @override
  String toString() => 'ClusterNodeInfo(host: $host, port: $port, id: $id)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClusterNodeInfo &&
          runtimeType == other.runtimeType &&
          host == other.host &&
          port == other.port &&
          id == other.id;

  @override
  int get hashCode => host.hashCode ^ port.hashCode ^ id.hashCode;
}

/// Represents a range of hash slots and the nodes responsible for them.
class ClusterSlotRange {
  /// The start of the slot range (inclusive).
  final int startSlot;

  /// The end of the slot range (inclusive).
  final int endSlot;

  /// The master node responsible for this slot range.
  final ClusterNodeInfo master;

  /// A list of replica nodes for this slot range.
  final List<ClusterNodeInfo> replicas;

  ClusterSlotRange({
    required this.startSlot,
    required this.endSlot,
    required this.master,
    this.replicas = const [],
  });

  @override
  String toString() =>
      'ClusterSlotRange(slots: $startSlot-$endSlot, master: $master, replicas: ${replicas.length})';
}