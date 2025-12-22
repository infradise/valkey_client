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
    final host = '127.0.0.1';
    final sslPort = 6380;

    test('connects using SSL with self-signed cert', () async {
      final client = ValkeyClient(
        host: host,
        port: sslPort,
        useSsl: true,
        onBadCertificate: (cert) => true,
        commandTimeout: Duration(seconds: 2),
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
    final seedHost = '127.0.0.1';
    final seedPort = 7001;

    test('connects to cluster using SSL with self-signed cert', () async {
      final node = ValkeyConnectionSettings(
        host: seedHost,
        port: seedPort,
        useSsl: true,
        onBadCertificate: (cert) => true,
        commandTimeout: Duration(seconds: 2),
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