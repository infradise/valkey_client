/*
 * Copyright 2025-2026 Infradise Inc.
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
import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';
// import 'package:valkey_client/src/exceptions.dart';

const noAuthHost = 'localhost'; // or 127.0.0.1
const noAuthPort = 6379;
const closedPort = 6380;
// -----------------------------------------------------------------------

/// Helper function to check server status *before* tests are defined.
Future<bool> checkServerStatus(String host, int port) async {
  final client = ValkeyClient(host: host, port: port);
  try {
    await client.connect();
    await client.close();
    return true; // Server is running
  } catch (e) {
    return false; // Server is not running
  }
}

Future<void> main() async {
  final isServerRunning = await checkServerStatus(noAuthHost, noAuthPort);

  group('ValkeyPool', () {
    late ValkeyPool pool;
    final settings = ValkeyConnectionSettings(
      host: noAuthHost,
      port: noAuthPort,
    );

    tearDown(() async {
      // Ensure pool is closed after each test
      await pool.close();
    });

    test('can acquire and release a connection', () async {
      pool = ValkeyPool(connectionSettings: settings, maxConnections: 5);

      ValkeyClient? client;
      try {
        client = await pool.acquire();
        expect(client, isA<ValkeyClient>());

        // Check if connection is alive
        final response = await client.ping();
        expect(response, 'PONG');
      } finally {
        if (client != null) {
          pool.release(client);
        }
      }
      // Pool internals (like _connectionsInUse) are private, so we just test public behavior
    });

    test('pool respects maxConnections limit', () async {
      const max = 3;
      pool = ValkeyPool(connectionSettings: settings, maxConnections: max);

      final clients = <ValkeyClient>[];

      // 1. Acquire all connections
      for (var i = 0; i < max; i++) {
        clients.add(await pool.acquire());
      }

      // 2. Try to acquire one more (should time out)
      final acquireFuture = pool.acquire();

      await expectLater(
        acquireFuture.timeout(Duration(milliseconds: 200)),
        throwsA(isA<TimeoutException>()),
      );

      // 3. Release one connection
      pool.release(clients.removeLast());

      // 4. Acquiring should now succeed
      ValkeyClient? newClient;
      try {
        newClient = await acquireFuture; // The pending future should complete
        expect(newClient, isA<ValkeyClient>());
      } finally {
        if (newClient != null) pool.release(newClient);
        // Release remaining
        clients.forEach(pool.release);
      }
    });

    test('release() handles unhealthy client (bad ping)', () async {
      // This test is tricky because we can't easily make a client "unhealthy"
      // without mocking. We'll simulate a closed client.

      pool = ValkeyPool(connectionSettings: settings, maxConnections: 2);

      final client1 = await pool.acquire();
      final client2 = await pool.acquire(); // Pool is now full

      // Manually close client1 to make it unhealthy
      await client1.close();

      // Release the unhealthy client
      pool.release(client1);

      // Pool should discard client1 and create a new one for client2's release
      // Let's release client2, which should go into the pool
      pool.release(client2);

      // Acquire should now get client2 (or a new healthy one)
      ValkeyClient? client3;
      try {
        client3 = await pool.acquire().timeout(Duration(seconds: 1));
        final response = await client3.ping();
        expect(response, 'PONG'); // Should be healthy
      } finally {
        if (client3 != null) pool.release(client3);
      }
    });

    test('close() rejects new acquires', () async {
      pool = ValkeyPool(connectionSettings: settings, maxConnections: 2);
      await pool.close();

      await expectLater(
          pool.acquire(),
          throwsA(isA<ValkeyClientException>().having(
              (e) => e.message, 'message', contains('Pool is closing'))));
    });

    test('release() automatically discards stateful clients (Smart Release)',
        () async {
      pool = ValkeyPool(connectionSettings: settings, maxConnections: 2);

      // 1. Acquire and make stateful
      final client = await pool.acquire();
      await client.multi(); // Enter transaction mode (Stateful)
      expect(client.isStateful, isTrue);

      // 2. Release
      pool.release(client);

      // 3. Verify
      // The client should be gone from the pool (discarded)
      // and replaced by a new one for the next acquire.
      // (Internal implementation detail: _allClients count depends on replacement logic)

      // Let's verify by acquiring again. We should get a CLEAN client.
      final client2 = await pool.acquire();
      expect(client2, isNot(client)); // Should be a new instance
      expect(client2.isStateful, isFalse); // Should be clean

      pool.release(client2);
    });

    test(
        'release() and discard() are safe to call multiple times (Idempotency)',
        () async {
      pool = ValkeyPool(connectionSettings: settings, maxConnections: 5);
      final client = await pool.acquire();

      // 1. Call release multiple times
      pool.release(client);
      pool.release(client); // Should do nothing
      pool.release(client); // Should do nothing

      // 2. Call discard after release
      // Client is now idle in the pool. Discarding it should work.
      await pool.discard(client);

      // 3. Call discard multiple times
      await pool.discard(client); // Should do nothing
      await pool.discard(client); // Should do nothing

      // Pool should be healthy and allow new acquires
      final client2 = await pool.acquire();
      expect(client2, isA<ValkeyClient>());
      pool.release(client2);
    });
  },
      skip: !isServerRunning
          ? 'Valkey server not running on $noAuthHost:$noAuthPort'
          : false);
}

/*
EXPECTED OUTPUT
===============

00:00 +6: All tests passed!
*/
