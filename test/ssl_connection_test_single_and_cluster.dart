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

import 'dart:io';
import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

void main() {
  // -------------------------------------------------------------------------
  // NOTE: These tests require a real Valkey/Redis instance running with TLS.
  //
  // 1. Standalone SSL Port: 6380 (Mapped to container 6379 TLS)
  // 2. Cluster SSL Ports: 7001-7006 (Requires complex Docker setup)
  // -------------------------------------------------------------------------

  group('ValkeyClient (Standalone) SSL', () {
    const host = '127.0.0.1';
    const sslPort = 6380;

    test('connects using SSL with self-signed cert', () async {
      final client = ValkeyClient(
        host: host,
        port: sslPort,
        useSsl: true,
        onBadCertificate: (cert) => true,
        commandTimeout: const Duration(seconds: 2),
      );

      try {
        await client.connect();
        expect(client.isConnected, isTrue);

        await client.set('test:ssl:standalone', 'ok');
        expect(await client.get('test:ssl:standalone'), equals('ok'));
      } catch (e) {
        if (e is ValkeyConnectionException) {
          print('⚠️ Skipped Standalone SSL test: Server unreachable');
          return;
        }
        rethrow;
      } finally {
        await client.close();
      }
    });
  });

  group('ValkeyClusterClient SSL', () {
    // Assuming a local cluster with TLS is running on 7001
    const seedHost = '127.0.0.1';
    const seedPort = 7101;

    test('connects to cluster using SSL with self-signed cert', () async {
      final node = ValkeyConnectionSettings(
        host: seedHost,
        port: seedPort,
        useSsl: true,
        onBadCertificate: (cert) => true,
        commandTimeout: const Duration(seconds: 2),
      );

      final cluster = ValkeyClusterClient([node]);

      try {
        await cluster.connect();
        // connect() succeeds only if topology refresh via SSL works

        await cluster.set('test:ssl:cluster', 'sharded-secure');
        final res = await cluster.get('test:ssl:cluster');
        expect(res, equals('sharded-secure'));
      } catch (e) {
        if (e is ValkeyConnectionException || e is SocketException) {
          print('⚠️ Skipped Cluster SSL test: Server unreachable on $seedPort');
          return;
        }
        rethrow;
      } finally {
        await cluster.close();
      }
    });
  });
}
