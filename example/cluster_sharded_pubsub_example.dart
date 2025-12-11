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

/*
EXPECTED OUTPUT
===============

Connecting to cluster...
✅ Connected to cluster.

--- Starting Sharded Pub/Sub (SSUBSCRIBE) ---
✅ Subscribed to channels: [shard:news:{sports}, shard:news:{tech}]
broadcasting messages via SPUBLISH...
📩 Received: [shard:news:{sports}] Lakers won the game!
📩 Received: [shard:news:{tech}] Valkey 1.6.0 released!
✅ All messages received.
Unsubscribed.
*/