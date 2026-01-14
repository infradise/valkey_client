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
  // Standalone Pub/Sub Best Practice:
  // Use separate connections for Subscribing and Publishing.

  // 1. Setup Subscriber Client (Listens for messages)
  final subscriber = ValkeyClient(
    host: '127.0.0.1',
    port: 6379,
    commandTimeout: Duration(seconds: 5),
  );

  // 2. Setup Publisher Client (Sends messages)
  final publisher = ValkeyClient(
    host: '127.0.0.1',
    port: 6379,
    commandTimeout: Duration(seconds: 5),
  );

  try {
    print('Connecting to standalone server...');
    await subscriber.connect();
    await publisher.connect();
    print('✅ Connected (Subscriber & Publisher).');

    final channels = ['shard:updates:{user1}', 'shard:updates:{user2}'];

    print('\n--- Starting Sharded Pub/Sub (Standalone) ---');

    // 3. SSUBSCRIBE (using Subscriber connection)
    print('Subscribing to $channels...');
    final sub = subscriber.ssubscribe(channels);

    // Wait for confirmation
    await sub.ready;
    print('✅ Subscription active.');

    // 4. Listen for messages
    final messagesReceived = Completer<void>();
    int count = 0;

    sub.messages.listen((msg) {
      print('📩 Received: [${msg.channel}] ${msg.message}');
      count++;
      if (count >= 2) {
        if (!messagesReceived.isCompleted) messagesReceived.complete();
      }
    });

    // 5. SPUBLISH (using Publisher connection)
    // IMPORTANT: We use the 'publisher' client here because 'subscriber' is in Pub/Sub mode.
    print('Publishing messages via SPUBLISH...');

    await publisher.spublish('shard:updates:{user1}', 'User 1 logged in');
    await publisher.spublish('shard:updates:{user2}', 'User 2 updated profile');

    // Wait for messages
    await messagesReceived.future.timeout(Duration(seconds: 5));
    print('✅ All messages received.');

    // 6. Unsubscribe
    await sub.unsubscribe();
    print('Unsubscribed.');
  } on ValkeyException catch (e) {
    print('❌ Error: $e');
    print(
        '👉 Note: Ensure your server version supports Sharded Pub/Sub (Redis 7.0+ / Valkey 9.0+)');
  } finally {
    // Close both clients
    await subscriber.close();
    await publisher.close();
  }
}

/*
EXPECTED OUTPUT
===============

Connecting to standalone server...
✅ Connected (Subscriber & Publisher).

--- Starting Sharded Pub/Sub (Standalone) ---
Subscribing to [shard:updates:{user1}, shard:updates:{user2}]...
✅ Subscription active.
Publishing messages via SPUBLISH...
📩 Received: [shard:updates:{user1}] User 1 logged in
📩 Received: [shard:updates:{user2}] User 2 updated profile
✅ All messages received.
Unsubscribed.
*/
