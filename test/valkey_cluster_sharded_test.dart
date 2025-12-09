import 'dart:async';
import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

void main() async {
  const host = '127.0.0.1';
  const port = 7001; // e.g., 7001 ~ 7006

  // Helper to check server status
  Future<bool> isServerUp() async {
    try {
      final client = ValkeyClient(host: host, port: port);
      await client.connect();
      await client.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  final serverUp = await isServerUp();

  group('ValkeyClusterClient Sharded Pub/Sub', () {
    late ValkeyClusterClient client;

    setUp(() {
      client = ValkeyClusterClient(
          [ValkeyConnectionSettings(host: host, port: port)]);
    });

    tearDown(() async {
      await client.close();
    });

    test('ssubscribe receives messages from multiple shards (Scatter-Gather)',
        () async {
      await client.connect();

      // 1. Define channels likely to map to different nodes (slots)
      // (High probability of distribution if the cluster has 3+ masters)
      final channel1 = 'shard:channel:{a}';
      final channel2 = 'shard:channel:{b}';
      final channel3 = 'shard:channel:{c}';
      final channels = [channel1, channel2, channel3];

      // 2. Unified Subscription (SSUBSCRIBE)
      // Internally sends subscription requests to multiple nodes and merges them.
      print('Cluster: Subscribing to $channels...');
      final sub = client.ssubscribe(channels);
      await sub.ready;
      print('Cluster: Subscription READY.');

      // 3. Setup message reception listener
      final receivedMessages = <String, String>{};
      final completer = Completer<void>();

      sub.messages.listen((msg) {
        print('Cluster Received: [${msg.channel}] ${msg.message}');
        if (msg.channel != null) {
          receivedMessages[msg.channel!] = msg.message;
        }
        // Complete when messages are received from all 3 channels
        if (receivedMessages.length == channels.length) {
          completer.complete();
        }
      });

      // 4. Publish messages to each channel (SPUBLISH)
      // spublish supports routing, so it goes directly to the correct node.
      print('Cluster: Publishing messages...');
      await client.spublish(channel1, 'msg-a');
      await client.spublish(channel2, 'msg-b');
      await client.spublish(channel3, 'msg-c');

      // 5. Verify
      try {
        await completer.future.timeout(Duration(seconds: 5));
      } catch (e) {
        fail(
            'Timeout waiting for messages. Received: ${receivedMessages.keys}');
      }

      expect(receivedMessages[channel1], 'msg-a');
      expect(receivedMessages[channel2], 'msg-b');
      expect(receivedMessages[channel3], 'msg-c');

      print('✅ All messages received from multiple shards!');

      // 6. Unsubscribe
      await sub.unsubscribe();
    });
  }, skip: !serverUp ? 'Cluster not running on $host:$port' : false);

  // Expected output:
  // 00:00 +0: ValkeyClusterClient Sharded Pub/Sub ssubscribe receives messages from multiple shards (Scatter-Gather)
  // Cluster: Subscribing to [shard:channel:{a}, shard:channel:{b}, shard:channel:{c}]...
  // Cluster: Subscription READY.
  // Cluster: Publishing messages...
  // Cluster Received: [shard:channel:{a}] msg-a
  // Cluster Received: [shard:channel:{b}] msg-b
  // Cluster Received: [shard:channel:{c}] msg-c
  // ✅ All messages received from multiple shards!
  // 00:00 +1: All tests passed!
}
