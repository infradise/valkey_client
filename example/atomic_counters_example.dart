import 'package:valkey_client/valkey_client.dart';

void main() async {
  // 1. Connect to the server (Standalone or Cluster)
  // Atomic commands work identically on both.
  final client = ValkeyClient(host: '127.0.0.1', port: 6379);

  try {
    await client.connect();
    print('✅ Connected to Valkey/Redis.');

    final key = 'page:view:count';

    // Reset key for this example
    await client.set(key, '0');
    print('Initial value: 0');

    // 2. INCR: Increment by 1
    final val1 = await client.incr(key);
    print('INCR result: $val1'); // Expected: 1

    // 3. INCRBY: Increment by specific amount
    final val2 = await client.incrBy(key, 10);
    print('INCRBY 10 result: $val2'); // Expected: 11

    // 4. DECR: Decrement by 1
    final val3 = await client.decr(key);
    print('DECR result: $val3'); // Expected: 10

    // 5. DECRBY: Decrement by specific amount
    final val4 = await client.decrBy(key, 5);
    print('DECRBY 5 result: $val4'); // Expected: 5

    // Cleanup
    await client.del(key);

  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await client.close();
  }

  // Expected output:
  // Connected to Valkey/Redis.
  // Initial value: 0
  // INCR result: 1
  // INCRBY 10 result: 11
  // DECR result: 10
  // DECRBY 5 result: 5
}