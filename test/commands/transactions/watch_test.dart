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

// @Tags(['transaction'])
// library;

import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

void main() {
  group('WATCH / UNWATCH Commands', () {
    late ValkeyClient client1;
    late ValkeyClient client2;

    setUp(() async {
      // Initialize two clients to simulate concurrency
      client1 = ValkeyClient(host: 'localhost', port: 6379);
      client2 = ValkeyClient(host: 'localhost', port: 6379);
      await client1.connect();
      await client2.connect();

      // TODO: v3.2.0 - flushDb(), flushAll()
      // await client1.flushAll(); // Clean start
      await client1.execute(['FLUSHALL']);
    });

    tearDown(() async {
      await client1.close(); // disconnect();
      await client2.close(); // disconnect();
    });

    test('WATCH functionality - Transaction aborts on modified key', () async {
      const key = 'test:watch_key';
      await client1.set(key, 'initial');

      // 1. Client 1 watches the key
      final watchResult = await client1.watch([key]);
      expect(watchResult, equals('OK'));

      // 2. Client 2 modifies the key (simulating another user)
      await client2.set(key, 'modified_by_client2');

      // 3. Client 1 tries to execute a transaction
      await client1.multi();
      await client1.set(key, 'client1_update');
      final result = await client1.exec();

      // 4. Expect transaction to fail (return null) because the key was
      // modified
      expect(result, isNull);

      // Verify the value is what Client 2 set
      final finalValue = await client1.get(key);
      expect(finalValue, equals('modified_by_client2'));
    });

    test('WATCH functionality - Transaction succeeds if key is not modified',
        () async {
      const key = 'test:watch_success';
      await client1.set(key, 'initial');

      // 1. Client 1 watches the key
      await client1.watch([key]);

      // 2. Client 2 does NOTHING (or modifies a different key)
      await client2.set('other_key', 'value');

      // 3. Client 1 executes transaction
      await client1.multi();
      await client1.set(key, 'updated');
      final result = await client1.exec();

      // 4. Expect success
      expect(result, isNotNull);
      expect(result![0], equals('OK'));

      final finalValue = await client1.get(key);
      expect(finalValue, equals('updated'));
    });

    test('UNWATCH functionality - Flushes watched keys', () async {
      const key = 'test:unwatch_key';
      await client1.set(key, 'initial');

      // 1. Client 1 watches the key
      await client1.watch([key]);

      // 2. Client 1 decides to unwatch
      final unwatchResult = await client1.unwatch();
      expect(unwatchResult, equals('OK'));

      // 3. Client 2 modifies the key
      await client2.set(key, 'modified_by_client2');

      // 4. Client 1 executes transaction
      // Since we called UNWATCH, this transaction should NOT abort even though
      // Client 2 touched the key.
      await client1.multi();
      await client1.set(key, 'client1_overwrite');
      final result = await client1.exec();

      // 5. Expect success
      expect(result, isNotNull);
      expect(result![0], equals('OK'));

      final finalValue = await client1.get(key);
      expect(finalValue, equals('client1_overwrite'));
    });
  });
}
