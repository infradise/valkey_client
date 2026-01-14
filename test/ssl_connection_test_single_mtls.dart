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

@TestOn('vm')
library;

import 'dart:io';
import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

void main() {
  group('SSL/TLS Connection Tests', () {
    // Note: To run this test, you need a Valkey/Redis instance running with TLS.
    const host = '127.0.0.1';
    const sslPort = 6380;

    test('Should connect using mTLS (Client Certificate)', () async {
      // 1. Create SecurityContext for mTLS
      final context = SecurityContext(withTrustedRoots: true);

      // Register CA certificate (test-purpose Self-signed CA)
      context.setTrustedCertificates('tests/tls/valkey.crt');

      // [Key] Register client certificate and key (this enables mTLS)
      context.useCertificateChain('tests/tls/valkey.crt');
      context.usePrivateKey('tests/tls/valkey.key');

      final client = ValkeyClient(
        host: host,
        port: sslPort,
        useSsl: true,
        sslContext: context, // <--- Enclose and send them here.
        // In an mTLS environment, the server certificate is also verified,
        // so if it is Self-signed, onBadCertificate may be required.
        onBadCertificate: (cert) => true,
      );

      try {
        await client.connect();
        expect(client.isConnected, isTrue);

        await client.set('mtls_key', 'verified_user');
        expect(await client.get('mtls_key'), equals('verified_user'));
      } finally {
        await client.close();
      }
    });
  });
}
