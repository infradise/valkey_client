import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

void main() async {
  // (Standalone: 6379 / Cluster: 7001)
  final client = ValkeyClient(host: '127.0.0.1', port: 6379);

  setUpAll(() async {
    await client.connect();
  });

  tearDownAll(() async {
    await client.close();
  });

  test('Atomic Counters should work correctly', () async {
    final key = 'counter:test';
    await client.del(key); // Init

    // 1. INCR
    expect(await client.incr(key), 1); // 0 + 1 = 1
    expect(await client.incr(key), 2); // 1 + 1 = 2

    // // 2. INCRBY
    expect(await client.incrBy(key, 10), 12); // 2 + 10 = 12

    // // 3. DECR
    expect(await client.decr(key), 11); // 12 - 1 = 11

    // // 4. DECRBY
    expect(await client.decrBy(key, 5), 6); // 11 - 5 = 6

    // Cleanup
    await client.del(key);
  });
}

/*
EXPECTED OUTPUT
===============

00:00 +1: All tests passed!
*/
