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
import 'package:valkey_client/valkey_client.dart';

/// Cluster & Sharded Pub/Sub Example: Internal stability check
///
/// This example shows that when ValkeyClusterClient internally uses a Pool,
/// the enhanced logic in v1.7.0 keeps cluster connections stable
/// even after large-scale sharded Pub/Sub operations.

void main() async {
  // 1. Configure Cluster
  final initialNodes = [
    ValkeyConnectionSettings(host: '127.0.0.1', port: 7001),
  ];

  // Internally, this uses multiple ValkeyPools (one per master node)
  final cluster = ValkeyClusterClient(initialNodes);

  try {
    await cluster.connect();
    print('✅ Connected to Cluster.');

    // [Scenario] Heavy Sharded Pub/Sub Usage
    // This creates "Stateful" connections across multiple pools internally.
    print('\n--- Testing Cluster Robustness with Sharded Pub/Sub ---');

    final channels = ['shard:{a}', 'shard:{b}', 'shard:{c}'];

    // 1. Subscribe (Allocates connections and puts them in Pub/Sub mode)
    final sub = cluster.ssubscribe(channels);
    await sub.ready;
    print('1. Subscribed to 3 sharded channels.');

    // 2. Publish and Receive
    final completer = Completer<void>();
    int msgCount = 0;
    sub.messages.listen((msg) {
      msgCount++;
      if (msgCount >= 3 && !completer.isCompleted) completer.complete();
    });

    await cluster.spublish('shard:{a}', 'msg-a');
    await cluster.spublish('shard:{b}', 'msg-b');
    await cluster.spublish('shard:{c}', 'msg-c');

    await completer.future.timeout(Duration(seconds: 5));
    print('2. Received all messages.');

    // 3. Unsubscribe & Cleanup
    // v1.7.0 MAGIC:
    // When unsubscribe() finishes, the internal connections are released.
    // The pools automatically detect they were used for Pub/Sub and
    // safely recycle them without polluting the pool with "listening" clients.
    await sub.unsubscribe();
    print('3. Unsubscribed (Internal connections cleaned up).');

    // 4. Verification
    // Immediately try a normal command. If pools were polluted, this would fail.
    print('\n--- Verifying Cluster Health ---');
    await cluster.set('robustness_check', 'passed');
    final result = await cluster.get('robustness_check');
    print('Cluster GET result: $result'); // Should be 'passed'

    if (result == 'passed') {
      print('✅ Cluster is healthy! v1.7.0 Pool Hardening works.');
    } else {
      print('❌ Cluster check failed.');
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await cluster.close();
  }
}

/*
EXPECTED OUTPUT
===============

✅ Connected to Cluster.

--- Testing Cluster Robustness with Sharded Pub/Sub ---
1. Subscribed to 3 sharded channels.
2. Received all messages.
3. Unsubscribed (Internal connections cleaned up).

--- Verifying Cluster Health ---
Cluster GET result: passed
✅ Cluster is healthy! v1.7.0 Pool Hardening works.
*/
