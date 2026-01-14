/*
 * Copyright 2026 Infradise Inc.
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
    port: 6379, // or 7001
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

/*
EXPECTED OUTPUT
===============

Simulating 5 concurrent requests with a pool size of 3...
[UserA] Acquiring connection...
[UserB] Acquiring connection...
[UserC] Acquiring connection...
[UserD] Acquiring connection...
[UserE] Acquiring connection...
[UserA] Acquired! Pinging...
[UserB] Acquired! Pinging...
[UserC] Acquired! Pinging...
[UserD] Acquired! Pinging...
[UserE] Acquired! Pinging...
[UserA] Received: Hello from UserA
[UserC] Received: Hello from UserC
[UserB] Received: Hello from UserB
[UserD] Received: Hello from UserD
[UserE] Received: Hello from UserE
[UserA] Releasing connection...
[UserC] Releasing connection...
[UserB] Releasing connection...
[UserD] Releasing connection...
[UserE] Releasing connection...

All requests handled.
Pool closed.
*/
