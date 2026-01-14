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

import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

void main() {
  const host = '127.0.0.1';
  const port = 6379;

  group('Database Selection & Metadata', () {
    test('Should connect to specific DB and verify data isolation', () async {
      // 1. Connect to DB 0 and clear key
      final clientDb0 = ValkeyClient(
        host: host,
        port: port,
        database: 0,
      );
      await clientDb0.connect();
      await clientDb0.del('test_isolation_key');

      // 2. Connect to DB 2 and set key
      final clientDb2 = ValkeyClient(
        host: host,
        port: port,
        database: 2,
      );
      await clientDb2.connect();

      // Verify Metadata is populated
      expect(clientDb2.metadata, isNotNull);
      expect(
          clientDb2.metadata!.maxDatabases, greaterThan(2)); // Standard is 16

      await clientDb2.set('test_isolation_key', 'value_in_db2');
      final valInDb2 = await clientDb2.get('test_isolation_key');
      expect(valInDb2, equals('value_in_db2'));

      // 3. Check DB 0 again (Should be null)
      final valInDb0 = await clientDb0.get('test_isolation_key');
      expect(valInDb0, isNull, reason: 'Data in DB 2 should not leak to DB 0');

      await clientDb0.close();
      await clientDb2.close();
    });

    test('Should throw exception when requesting invalid DB index', () async {
      // Requesting DB 9999 (assuming default config has 16 DBs)
      final client = ValkeyClient(
        host: host,
        port: port,
        database: 9999,
      );

      try {
        await client.connect();
        fail('Should have thrown ValkeyClientException');
      } catch (e) {
        expect(e, isA<ValkeyClientException>());
        expect(e.toString(), contains('out of range'));
      } finally {
        await client.close();
      }
    });

    test('Should correctly identify server metadata', () async {
      final client = ValkeyClient(host: host, port: port);
      await client.connect();

      final meta = client.metadata!;
      print('Test Metadata Output: $meta');

      expect(meta.serverName, anyOf(equals('redis'), equals('valkey')));
      expect(meta.version, isNotEmpty);
      expect(meta.mode, isNot(RunningMode.unknown));
      expect(meta.maxDatabases, greaterThan(0));

      await client.close();
    });
  });
}
