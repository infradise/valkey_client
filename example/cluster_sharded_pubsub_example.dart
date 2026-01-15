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
import 'package:valkey_client/valkey_client.dart';

void main() async {
  // 1. Configure cluster connection
  // We use 127.0.0.1:7001 as the entry point
  final initialNodes = [
    ValkeyConnectionSettings(
      host: '127.0.0.1',
      port: 7001,
      commandTimeout: Duration(seconds: 5),
    ),
  ];
  final client = ValkeyClusterClient(initialNodes);

  try {
    print('Connecting to cluster...');
    await client.connect();
    print('✅ Connected to cluster.');

    // 2. Define Sharded Channels
    // Unlike standard Pub/Sub, these channels are hashed to specific slots.
    // 'shard:news:{sports}' -> Maps to a specific node based on '{sports}'
    // 'shard:news:{tech}'   -> Maps to a potentially different node
    final channels = ['shard:news:{sports}', 'shard:news:{tech}'];

    print('\n--- Starting Sharded Pub/Sub (SSUBSCRIBE) ---');

    // 3. Subscribe (Scatter-Gather)
    // The client automatically routes subscription requests to the correct nodes.
    final sub = client.ssubscribe(channels);

    // Wait for the subscription to be fully established on all relevant nodes
    await sub.ready;
    print('✅ Subscribed to channels: $channels');

    // 4. Listen for messages
    // Use a completer to keep the example running until we get messages
    final messagesReceived = Completer<void>();
    int count = 0;

    sub.messages.listen((msg) {
      print('📩 Received: [${msg.channel}] ${msg.message}');
      count++;
      if (count >= 2) {
        if (!messagesReceived.isCompleted) messagesReceived.complete();
      }
    });

    // 5. Publish (SPUBLISH)
    // Send messages directly to the node responsible for the channel key.
    print('broadcasting messages via SPUBLISH...');
    await client.spublish('shard:news:{sports}', 'Lakers won the game!');
    await client.spublish('shard:news:{tech}', 'Valkey 1.6.0 released!');

    // Wait for messages
    await messagesReceived.future.timeout(Duration(seconds: 5));
    print('✅ All messages received.');

    // 6. Unsubscribe
    // This cleans up connections to the shards.
    await sub.unsubscribe();
    print('Unsubscribed.');
  } on ValkeyException catch (e) {
    print('❌ Error: $e');
  } finally {
    await client.close();
  }
}
