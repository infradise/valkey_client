import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

void main() {
  // Configure the port according to the test environment
  final client = ValkeyClient(host: '127.0.0.1', port: 6379);

  setUpAll(() async {
    await client.connect();
  });

  tearDownAll(() async {
    await client.close();
  });

  test('SPUBLISH should execute without error', () async {
    final channel = 'shard-chan:{123}'; // Hashtag used to fix slot if needed

    // Since there are no subscribers, it should return 0 (success as long as no error occurs)
    final receiverCount = await client.spublish(channel, 'Hello Sharding!');

    expect(receiverCount, greaterThanOrEqualTo(0));
    print('SPUBLISH sent successfully. Receivers: $receiverCount');
  });

  // Expected output:
  // 00:00 +0: SPUBLISH should execute without error
  // SPUBLISH sent successfully. Receivers: 0
  // 00:00 +1: All tests passed!
}
