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

import 'package:valkey_client/valkey_client_base.dart'; // For ClusterSlotRange
import 'package:valkey_client/src/exceptions.dart'; // For ValkeyParsingException
// import 'package:valkey_client/src/cluster_info.dart'
//     show ClusterNodeInfo, ClusterSlotRange;

/// Internal utility class to parse the complex nested array response from the 'CLUSTER SLOTS' command.
///
/// This logic is separated from [ValkeyClient] to improve testability,
/// as the response format is complex.
///
/// Throws a [ValkeyParsingException] if the response format is invalid.
List<ClusterSlotRange> parseClusterSlotsResponse(dynamic response) {
  if (response is! List) {
    throw ValkeyParsingException(
        'Invalid CLUSTER SLOTS response: expected List, got ${response.runtimeType}');
  }

  final List<ClusterSlotRange> slotRanges = [];

  try {
    for (final dynamic slotInfo in response) {
      if (slotInfo is! List || slotInfo.length < 3) {
        // [start, end, master] is the minimum requirement.
        // We skip invalid entries.
        continue;
      }

      // 1. Parse slot range
      final int startSlot = slotInfo[0] as int;
      final int endSlot = slotInfo[1] as int;

      // 2. Parse master node info
      final ClusterNodeInfo master = _parseNodeInfo(slotInfo[2]);

      // 3. Parse replica node info (optional)
      final List<ClusterNodeInfo> replicas = [];
      if (slotInfo.length > 3) {
        for (int i = 3; i < slotInfo.length; i++) {
          // Note: Some responses might include node IDs, others might not.
          // The CLUSTER SLOTS documentation shows replicas may also have IDs.
          replicas.add(_parseNodeInfo(slotInfo[i]));
        }
      }

      slotRanges.add(ClusterSlotRange(
        startSlot: startSlot,
        endSlot: endSlot,
        master: master,
        replicas: replicas,
      ));
    }
  } on ValkeyParsingException {
    rethrow; // Re-throw exceptions from _parseNodeInfo
  } catch (e) {
    // Catching generic errors during parsing (e.g., cast errors)
    throw ValkeyParsingException(
        'Failed to parse CLUSTER SLOTS response. Error: $e. Response: $response');
  }

  return slotRanges;
}

/// Parses an individual node info array from the 'CLUSTER SLOTS' response.
/// e.g., [host, port, id] or [host, port]
ClusterNodeInfo _parseNodeInfo(dynamic nodeData) {
  if (nodeData is! List || nodeData.length < 2) {
    // Host and Port are minimum
    throw ValkeyParsingException(
        'Invalid node info format: expected [host, port, ...], got $nodeData');
  }

  // Handle responses with or without the node ID
  // [host, port] (older Redis) or [host, port, id] (Valkey/Redis 7+)
  return ClusterNodeInfo(
    host: nodeData[0] as String,
    port: nodeData[1] as int,
    // Handle responses with or without the node ID
    id: nodeData.length > 2 ? nodeData[2] as String? : null,
  );
}
