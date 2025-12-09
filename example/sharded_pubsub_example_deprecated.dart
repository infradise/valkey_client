import 'dart:async';
import 'package:valkey_client/valkey_client.dart';

void main() async {
  // 1. Connect to a Standalone server
  // Note: Sharded Pub/Sub commands (SSUBSCRIBE, SPUBLISH) are supported
  // on Valkey 9.0+ and Redis 7.0+, even in standalone mode.
  final client = ValkeyClient(
    host: '127.0.0.1',
    port: 6379, // Default standalone port
    commandTimeout: Duration(seconds: 5),
  );

  try {
    print('Connecting to standalone server...');
    await client.connect();
    print('✅ Connected.');

    // 2. Define Channels
    // In standalone mode, sharding logic is trivial (everything is on one node),
    // but using SSUBSCRIBE ensures your code is ready for Cluster migration.
    final channels = ['shard:updates:{user1}', 'shard:updates:{user2}'];

    print('\n--- Starting Sharded Pub/Sub (Standalone) ---');

    // 3. SSUBSCRIBE
    print('Subscribing to $channels...');
    final sub = client.ssubscribe(channels);

    // Wait for confirmation
    await sub.ready;
    print('✅ Subscription active.');

    // 4. Listen for messages
    // Use a completer to wait for messages in this example script
    final messagesReceived = Completer<void>();
    int count = 0;

    sub.messages.listen((msg) {
      print('📩 Received: [${msg.channel}] ${msg.message}');
      count++;
      if (count >= 2) {
        if (!messagesReceived.isCompleted) messagesReceived.complete();
      }
    });

    // 5. SPUBLISH
    // Publish messages using the Sharded API
    print('Publishing messages via SPUBLISH...');
    await client.spublish('shard:updates:{user1}', 'User 1 logged in');
    await client.spublish('shard:updates:{user2}', 'User 2 updated profile');

    // Wait for messages
    await messagesReceived.future.timeout(Duration(seconds: 5));
    print('✅ All messages received.');

    // 6. Unsubscribe
    await sub.unsubscribe();
    print('Unsubscribed.');

  } on ValkeyException catch (e) {
    print('❌ Error: $e');
    print('👉 Note: Ensure your server version supports Sharded Pub/Sub (Redis 7.0+ / Valkey 9.0+)');
  } finally {
    await client.close();
  }
}