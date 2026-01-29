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
  group('SSL/TLS Connection Tests', () {
    // Configuration for the local Docker environment
    const host = '127.0.0.1';
    const tlsPort = 6380; // Mapped to container's TLS port
    const mTlsPort = 6381; // Mapped to container's mTLS port

    // Certificate paths (relative to the package root)
    // Ensure you have run the OpenSSL generation commands in 'tests/tls/'
    const caCertPath = 'tests/tls/valkey.crt';
    const clientCertPath =
        'tests/tls/valkey.crt'; // Using the same cert for testing
    const clientKeyPath = 'tests/tls/valkey.key';

    test('Standalone: Should connect using Basic SSL (accepting self-signed)',
        () async {
      final client = ValkeyClient(
        host: host,
        port: tlsPort,
        useSsl: true,
        // For development/testing with self-signed certs, we must explicitly allow them.
        onBadCertificate: (cert) => true,
        commandTimeout: const Duration(seconds: 2),
      );

      try {
        await client.connect();
        expect(client.isConnected, isTrue);

        // Verify command execution
        await client.set('test:ssl:basic', 'success');
        final value = await client.get('test:ssl:basic');
        expect(value, equals('success'));
      } catch (e) {
        // Gracefully fail if the SSL container is not running
        if (e is SocketException || e is ValkeyConnectionException) {
          print('⚠️ SKIPPING TEST: SSL Server not reachable at $host:$tlsPort');
          return;
        }
        rethrow;
      } finally {
        await client.close();
      }
    });

    test('Standalone: Should connect using mTLS (Client Certificate)',
        () async {
      // 1. Check if certificate files exist before running the test
      if (!File(caCertPath).existsSync() || !File(clientKeyPath).existsSync()) {
        print(
            '⚠️ SKIPPING mTLS TEST: Certificate files not found in tests/tls/');
        return;
      }

      // 2. Configure SecurityContext with Client Certificate & Key
      final context = SecurityContext(withTrustedRoots: true);
      context.setTrustedCertificates(caCertPath);
      context.useCertificateChain(clientCertPath);
      context.usePrivateKey(clientKeyPath);

      final client = ValkeyClient(
        host: host,
        port: mTlsPort,
        useSsl: true,
        // Inject the context containing the client cert
        sslContext: context,
        // Still needed if the server uses a self-signed cert
        onBadCertificate: (cert) => true,
        commandTimeout: const Duration(seconds: 2),
      );

      try {
        await client.connect();
        expect(client.isConnected, isTrue);

        // Verify mTLS connection works
        await client.set('test:ssl:mtls', 'verified');
        final value = await client.get('test:ssl:mtls');
        expect(value, equals('verified'));
      } catch (e) {
        if (e is SocketException || e is ValkeyConnectionException) {
          print(
              '⚠️ SKIPPING mTLS TEST: Server not reachable at $host:$mTlsPort');
          return;
        }
        rethrow;
      } finally {
        await client.close();
      }
    });
  });
}
