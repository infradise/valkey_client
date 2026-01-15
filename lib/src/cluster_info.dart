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
  String toString() => 'ClusterSlotRange(slots: $startSlot-$endSlot, '
      'master: $master, replicas: ${replicas.length})';
}
