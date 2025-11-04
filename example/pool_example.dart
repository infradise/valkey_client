import 'dart:async';

import 'package:valkey_client/valkey_client.dart';

/// Helper function to simulate a web request using the pool.
Future<void> handleRequest(ValkeyPool pool, String userId) async {
  ValkeyClient? client;
  try {
    // 1. Acquire connection
    print('[$userId] Acquiring connection...');
    client = await pool.acquire().timeout(Duration(seconds: 2));
    print('[$userId] Acquired! Pinging...');

    // 2. Use connection
    final response = await client.ping('Hello from $userId');
    print('[$userId] Received: $response');

    // Simulate some work
    await Future.delayed(Duration(milliseconds: 500));
  } on ValkeyException catch (e) {
    print('[$userId] Valkey Error: $e');
  } on TimeoutException {
    print('[$userId] Timed out waiting for a connection!');
  } catch (e) {
    print('[$userId] Unknown Error: $e');
  } finally {
    // 3. Release connection back to pool
    if (client != null) {
      print('[$userId] Releasing connection...');
      pool.release(client);
    }
  }
}

Future<void> main() async {
  // ---
  // Ensure a Valkey server is running on localhost (127.0.0.1:6379).
  // ---

  // 1. Define connection settings
  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6379,
    // password: 'my-password',
  );

  // 2. Create a pool with a max of 3 connections
  final pool = ValkeyPool(
    connectionSettings: settings,
    maxConnections: 3,
  );

  print('Simulating 5 concurrent requests with a pool size of 3...');

  // 3. Simulate 5 concurrent requests
  final futures = <Future>[
    handleRequest(pool, 'UserA'),
    handleRequest(pool, 'UserB'),
    handleRequest(pool, 'UserC'), // These 3 will get connections immediately
    handleRequest(pool, 'UserD'), // This one will wait
    handleRequest(pool, 'UserE'), // This one will wait
  ];

  await Future.wait(futures);

  print('\nAll requests handled.');

  // 4. Close the pool
  await pool.close();
  print('Pool closed.');
}
