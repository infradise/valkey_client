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
  group('SSL/TLS Connection Tests', () {
    // Note: To run this test, you need a Valkey/Redis instance running with TLS.
    const host = '127.0.0.1';
    const sslPort = 6380;

    test('Should connect using SSL with onBadCertificate callback', () async {
      final client = ValkeyClient(
        host: host,
        port: sslPort,
        useSsl: true,
        // Accept self-signed certificates for testing
        onBadCertificate: (cert) => true,
        commandTimeout: const Duration(seconds: 2),
      );

      try {
        await client.connect();
        expect(client.isConnected, isTrue);

        // Verify functionality over SSL
        await client.set('test:ssl', 'secure-value');
        final value = await client.get('test:ssl');
        expect(value, equals('secure-value'));

        final pong = await client.ping();
        expect(pong, equals('PONG'));
      } catch (e) {
        // Fail gracefully if no SSL server is running (to avoid breaking CI)
        if (e is ValkeyConnectionException) {
          print('⚠️ SKIPPING SSL TEST: Server not reachable at $host:$sslPort');
          return;
        }
        rethrow;
      } finally {
        await client.close();
      }
    });

    test('Should fail if useSsl is true but server is not SSL', () async {
      // Connecting to a non-SSL port (e.g., standard 6379) with SSL enabled
      // should fail
      final client = ValkeyClient(
        host: host,
        port: 6379, // Standard non-SSL port
        useSsl: true,
        commandTimeout: const Duration(seconds: 1),
      );

      // Handshake should fail
      expect(client.connect(), throwsA(isA<Exception>()));

      await client.close();
    });
  });
}
