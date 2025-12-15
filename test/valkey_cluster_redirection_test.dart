import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';
// import 'package:valkey_client/src/cluster_hash.dart'; // Need getHashSlot

Future<bool> checkServerStatus(String host, int port) async {
  final client = ValkeyClient(host: host, port: port);
  try {
    await client.connect();
    await client.close();
    return true;
  } catch (e) {
    return false;
  }
}

void main() async {
  const clusterHost = '127.0.0.1';
  const clusterPort = 7001;

  final isClusterRunning = await checkServerStatus(clusterHost, clusterPort);

  group('ValkeyClusterClient Redirection', () {
    late ValkeyClusterClient client;

    setUp(() async {
      final initialNodes = [
        ValkeyConnectionSettings(host: clusterHost, port: clusterPort),
      ];
      client = ValkeyClusterClient(initialNodes);
      await client.connect();
    });

    tearDown(() async {
      await client.close();
    });

    test('should transparently handle MOVED redirection', () async {
      // 1. Setup a key
      // key:A (Slot 9366) -> Usually Node 7002
      final key = 'key:A';
      await client.set(key, 'Value-A');

      // 2. Corrupt the client's map intentionally
      // Point key:A (Slot 9366) to Node 7001 (which does NOT own it).
      // This forces 7001 to reply with "-MOVED 9366 127.0.0.1:7002"
      // NOTE: You must uncomment the debugCorruptSlotMap method in your client class!
      client.debugCorruptSlotMap(key, 7001);

      // 3. Execute GET
      // Expected flow:
      // Client -> 7001 (Wrong) -> MOVED Error -> Client Update Map -> Client -> 7002 (Right) -> Success
      final result = await client.get(key);

      // 4. Verify
      expect(result, 'Value-A');

      // 5. Verify map is fixed
      // If we run it again, it should go straight to the right node (no extra latency/log)
      final result2 = await client.get(key);
      expect(result2, 'Value-A');
    });
  },
      skip: !isClusterRunning
          ? 'Valkey cluster not running on $clusterHost:$clusterPort'
          : false);
}

/*
EXPECTED OUTPUT
===============

00:00 +1: All tests passed!
*/