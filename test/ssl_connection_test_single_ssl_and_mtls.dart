@TestOn('vm')
library;

import 'dart:io';
import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

void main() {
  group('SSL/TLS Connection Tests', () {
    // Configuration for the local Docker environment
    const host = '127.0.0.1';
    const sslPort = 6380; // Mapped to container's 6379 (TLS)

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
        port: sslPort,
        useSsl: true,
        // For development/testing with self-signed certs, we must explicitly allow them.
        onBadCertificate: (cert) => true,
        commandTimeout: Duration(seconds: 2),
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
          print('⚠️ SKIPPING TEST: SSL Server not reachable at $host:$sslPort');
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
        port: sslPort,
        useSsl: true,
        // Inject the context containing the client cert
        sslContext: context,
        // Still needed if the server uses a self-signed cert
        onBadCertificate: (cert) => true,
        commandTimeout: Duration(seconds: 2),
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
              '⚠️ SKIPPING mTLS TEST: Server not reachable at $host:$sslPort');
          return;
        }
        rethrow;
      } finally {
        await client.close();
      }
    });
  });
}
