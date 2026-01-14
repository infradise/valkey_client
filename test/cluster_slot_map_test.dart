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

import 'package:test/test.dart';
import 'package:valkey_client/src/cluster_slot_map.dart';
import 'package:valkey_client/valkey_client.dart';

void main() {
  // Enable detailed logging
  ValkeyClient.setLogLevel(ValkeyLogLevel.info);

  group('ClusterSlotMap', () {
    test('updateSlot should correctly modify the node for a specific slot', () {
      // 1. Initial Topology
      final node1 = ClusterNodeInfo(host: '127.0.0.1', port: 7004);
      final node2 = ClusterNodeInfo(host: '127.0.0.1', port: 7003);
      var slotNode = node2;

      final ranges = [
        // ClusterSlotRange(startSlot: 0, endSlot: 100, master: node1),
        // ClusterSlotRange(startSlot: 101, endSlot: 200, master: node2),
        // ClusterSlotRange(startSlot: 0, endSlot: 5460, master: node1),
        // ClusterSlotRange(startSlot: 5461, endSlot: 10922, master: node2),

        ClusterSlotRange(startSlot: 10923, endSlot: 16383, master: node1),
        ClusterSlotRange(startSlot: 10923, endSlot: 16383, master: node2),
      ];

      final slotMap = ClusterSlotMap.fromRanges(ranges);

      // Example 1. robustness_check (slot number: 16173) -- changed node2 to node1
      //
      // Verify initial state
      expect(slotMap.getNodeForKey('robustness_check'),
          slotNode); // Slot 16173 -> Node 2

      // -MOVED redirection
      slotMap.updateSlot(16173, slotNode = node1);

      expect(slotMap.getNodeForKey('robustness_check'),
          slotNode); // Slot 16173 -> Node 1

      // Example 2. foo (slot number: 12182) -- changed node1 to node2
      //
      // "foo" hashes to slot 12182 and it initially points to node1.
      const slotForFoo = 12182;
      final rangeFoo =
          ClusterSlotRange(startSlot: 0, endSlot: 16383, master: node1);
      final mapFoo = ClusterSlotMap.fromRanges([rangeFoo]);

      // Initial check: "foo" should route to node1
      expect(mapFoo.getNodeForKey('foo'), node1);

      // Update slot for 'foo' to node 2
      mapFoo.updateSlot(slotForFoo, node2);

      // Verify
      // "foo" should now route to node2
      expect(mapFoo.getNodeForKey('foo'), node2);
    });
  });
}

/*
EXPECTED OUTPUT
===============

00:00 +0: ClusterSlotMap updateSlot should correctly modify the node for a specific slot
[2025-12-16T00:06:57.570657] ClusterSlotMap - INFO: key = robustness_check
[2025-12-16T00:06:57.573907] ClusterSlotMap - INFO: slot = 16173
[2025-12-16T00:06:57.575253] ClusterSlotMap - INFO: key = robustness_check
[2025-12-16T00:06:57.575288] ClusterSlotMap - INFO: slot = 16173
[2025-12-16T00:06:57.576458] ClusterSlotMap - INFO: key = foo
[2025-12-16T00:06:57.576499] ClusterSlotMap - INFO: slot = 12182
[2025-12-16T00:06:57.576531] ClusterSlotMap - INFO: key = foo
[2025-12-16T00:06:57.576553] ClusterSlotMap - INFO: slot = 12182
00:00 +1: All tests passed!
*/
