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

@TestOn('vm')
library;

// import 'dart:io';
import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

void main() {
  // Assumes Docker Compose setup is running:
  // Master: 6379, Replica1: 6380, Replica2: 6381
  const masterHost = '127.0.0.1';
  const masterPort = 6379;

  group('v2.2.0 Replica Read & Load Balancing', () {
    test('Should discover replicas and read data from them', () async {
      // Setup: Prefer Replicas with Round-Robin
      final settings = ValkeyConnectionSettings(
        host: masterHost,
        port: masterPort,
        readPreference: ReadPreference.preferReplica,
        loadBalancingStrategy: LoadBalancingStrategy.roundRobin,
      );
      final client = ValkeyClient.fromSettings(settings);

      try {
        await client.connect();

        // Step 1: Write to Master
        await client.set('test:replica:key', 'hello_replica');

        // Wait for replication
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Step 2: Read multiple times (Load Balancing)
        // Since we have multiple replicas, this verifies that
        // switching connections doesn't break data retrieval.
        for (var i = 0; i < 10; i++) {
          final val = await client.get('test:replica:key');
          expect(val, equals('hello_replica'));
        }
      } finally {
        await client.close();
      }
    });

    test(
        'Should fall back to Master if ReadPreference is preferReplica but no '
        'replicas exist', () async {
      // Setup: Point to a standalone node (or Master) but pretend it has no
      // replicas
      // (Testing logic depends on environment, here we verify functionality
      // holds).
      // If the environment HAS replicas, this tests that 'preferReplica' works
      // generally.

      final settings = ValkeyConnectionSettings(
        host: masterHost,
        port: masterPort,
        readPreference: ReadPreference.preferReplica,
      );
      final client = ValkeyClient.fromSettings(settings);

      await client.connect();
      await client.set('test:fallback', 'fallback_val');

      final val = await client.get('test:fallback');
      expect(val, equals('fallback_val'));

      await client.close();
    });

    test(
        'Should throw exception if ReadPreference is replicaOnly but '
        'no replicas available', () async {
      // To test this, we need a Master with NO replicas.
      // This test should be failed if replicas exist.
      // Ideally: Point to a port where a standalone Redis/Valkey sits without slaves.
      // For demonstration, we assume port 6399 is a standalone empty Redis/Valkey.

      // print('⚠️ Skipping replicaOnly test (requires standalone instance
      // without replicas)');
      final settings = ValkeyConnectionSettings(
        host: masterHost,
        port: 6399, // Hypothetical standalone port
        readPreference: ReadPreference.replicaOnly,
      );
      final client = ValkeyClient.fromSettings(settings);

      try {
        await client.connect();
        fail('Should have thrown exception');
      } catch (e) {
        expect(e, isA<ValkeyConnectionException>());
      }
    });
  });
}
