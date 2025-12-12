import 'dart:async';
import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

/// Standalone Sharded Pub/Sub Test: Protocol compliance check
///
/// This test aims to verify that the Standalone client correctly follows
/// the Sharded Pub/Sub protocol. Therefore, you should either use the
/// Standalone port (6379) or specify the Cluster node (7002) that is
/// guaranteed to own the given key.

void main() {
  // Test environment configuration
  const host = '127.0.0.1';

  // Use Standalone port (6379) for deterministic protocol testing.
  const port = 6379; // Standalone node port

  // Or use 7002 if you strictly want to test against a specific cluster node that owns the slot.
  // const port = 7002; // Cluster master node port

  group('ValkeyClient Sharded Pub/Sub', () {
    late ValkeyClient subscriber;
    late ValkeyClient publisher;

    setUp(() async {
      subscriber = ValkeyClient(host: host, port: port);
      publisher = ValkeyClient(host: host, port: port);
      await subscriber.connect();
      await publisher.connect();
    });

    tearDown(() async {
      await subscriber.close();
      await publisher.close();
    });

    test('ssubscribe receives messages published via spublish', () async {
      final channel = 'shard-channel:{1}'; // Hashtag used to be explicit
      final messageContent = 'Hello Sharding';

      // 1. Subscribe
      print('Subscribing to $channel...');
      final sub = subscriber.ssubscribe([channel]);
      await sub.ready; // Wait for confirmation

      // 2. Setup listener
      final completer = Completer<ValkeyMessage>();
      sub.messages.listen((msg) {
        print('Received message on ${msg.channel}: ${msg.message}');
        if (!completer.isCompleted) completer.complete(msg);
      });

      // 3. Publish
      print('Publishing to $channel...');
      final receivers = await publisher.spublish(channel, messageContent);
      expect(receivers,
          greaterThanOrEqualTo(1)); // Should have at least 1 subscriber

      // 4. Verify
      final receivedMsg = await completer.future.timeout(Duration(seconds: 2));
      expect(receivedMsg.channel, channel);
      expect(receivedMsg.message, messageContent);

      // 5. Unsubscribe
      await sub.unsubscribe();
    });
  });
}

/*
EXPECTED OUTPUT
===============
for both modes (Standalone and Cluster)

00:00 +0: ValkeyClient Sharded Pub/Sub ssubscribe receives messages published via spublish
Subscribing to shard-channel:{1}...
Publishing to shard-channel:{1}...
Received message on shard-channel:{1}: Hello Sharding
00:00 +1: All tests passed!

*/
