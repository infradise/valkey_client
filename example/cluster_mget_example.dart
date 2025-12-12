import 'package:valkey_client/valkey_client.dart';

void main() async {
  // ValkeyClient.setLogLevel(ValkeyLogLevel.off); // default

  // 1. Configure cluster connection
  // We use 127.0.0.1:7001 as the entry point (based on your Docker setup)
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

    // 2. Setup Data
    // We use keys that are known to hash to different slots/nodes.
    // key:A (Slot 9366) -> Usually Node 2
    // key:B (Slot 5365) -> Usually Node 1
    // key:C (Slot 7365) -> Usually Node 2
    print('\nSetting up test data on multiple nodes...');
    await client.set('key:A', 'Value-A');
    await client.set('key:B', 'Value-B');
    await client.set('key:C', 'Value-C'); // Assuming typical distribution

    // 3. Run MGET (v1.4.0 Feature)
    // The client will scatter these requests to different nodes in parallel
    // and gather them back in the exact requested order.
    print('Executing MGET for [key:A, key:B, key:C, missing_key]...');

    final results =
        await client.mget(['key:A', 'key:B', 'key:C', 'missing_key']);

    print('Results: $results');

    // 4. Verify Order
    if (results[0] == 'Value-A' &&
        results[1] == 'Value-B' &&
        results[2] == 'Value-C' &&
        results[3] == null) {
      print(
          '✅ MGET Success: Retrieved values from multiple nodes in correct order!');
    } else {
      print('❌ MGET Failed: Order mismatch or missing data.');
    }

    // Cleanup
    await client.del('key:A');
    await client.del('key:B');
    await client.del('key:C');
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

Setting up test data on multiple nodes...
Executing MGET for [key:A, key:B, key:C, missing_key]...
Results: [Value-A, Value-B, Value-C, null]
✅ MGET Success: Retrieved values from multiple nodes in correct order!
*/
