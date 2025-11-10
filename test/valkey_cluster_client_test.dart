import 'dart:async';
import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

// Helper function (can be shared or duplicated from valkey_client_test.dart)
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
  const clusterHost = '127.0.0.1';
  const clusterPort = 7001; // Default port for cluster discovery

  // --- RUN THE CHECK *BEFORE* DEFINING TESTS ---
  final isClusterRunning = await checkServerStatus(clusterHost, clusterPort);

  if (!isClusterRunning) {
    print('=' * 70);
    print('⚠️  WARNING: Valkey CLUSTER not running on $clusterHost:$clusterPort.');
    print('Skipping ValkeyClusterClient tests.');
    print('Please start a cluster (e.g., ports 7000-7005) to run all tests.');
    print('=' * 70);
  }

  group('ValkeyClusterClient', () {
    late ValkeyClusterClient client;

    setUp(() {
      final initialNodes = [
        ValkeyConnectionSettings(
          host: clusterHost,
          port: clusterPort,
        ),
      ];
      client = ValkeyClusterClient(initialNodes);
    });

    tearDown(() async {
      await client.close();
    });

    test('connect() should fetch topology and set up internal pools', () async {
      await client.connect();
      // Simple verification: pingAll should return multiple successful pongs
      // (assuming a cluster of at least 3 masters)
      final pings = await client.pingAll();
      expect(pings.length, greaterThanOrEqualTo(1)); // At least 1 master
      expect(pings.values.first, 'PONG');
    });

    test('set() and get() should route to correct nodes', () async {
      await client.connect();

      // These keys are known (from cluster_hash_test) to be on
      // different slots. The client must route them correctly.
      final keyA = 'key:A'; // Slot 9028
      final keyB = 'key:B'; // Slot 13134

      // Act
      final setARes = await client.set(keyA, 'Value A');
      final setBRes = await client.set(keyB, 'Value B');

      // Assert Set
      expect(setARes, 'OK');
      expect(setBRes, 'OK');

      // Act
      final getARes = await client.get(keyA);
      final getBRes = await client.get(keyB);

      // Assert Get
      expect(getARes, 'Value A');
      expect(getBRes, 'Value B');

      // Clean up
      await client.del(keyA);
      await client.del(keyB);
    });

    test('mget() should throw UnimplementedError (v1.3.0 limitation)',
        () async {
      await client.connect();

      final mgetFuture = client.mget(['key:A', 'key:B']);

      // Expect the specific error noted in the changelog
      await expectLater(
        mgetFuture,
        throwsA(isA<UnimplementedError>().having(
          (e) => e.message,
          'message',
          contains('MGET (multi-node scatter-gather)'),
        )),
      );
    });

  },
      // Skip this entire group if the cluster is not running
      skip: !isClusterRunning
          ? 'Valkey cluster not running on $clusterHost:$clusterPort'
          : false);
}