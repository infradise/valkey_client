// import 'dart:io';
import 'package:valkey_client/valkey_client.dart';

void main() async {
  print('🔒 [Dev] Connecting to Cluster SSL (Self-Signed)...');

  // Define initial seed nodes with SSL settings
  final initialNodes = [
    ValkeyConnectionSettings(
      host: '127.0.0.1',
      port: 7001, // SSL Cluster Port
      useSsl: true,
      // Apply callback to trust the bad cert
      onBadCertificate: (cert) => true,
      // password: 'cluster_password',
    ),
  ];

  final cluster = ValkeyClusterClient(initialNodes);

  try {
    await cluster.connect();
    print('  ✅ Cluster Connected!');

    await cluster.set('cluster:ssl', 'secure-sharding');
    final val = await cluster.get('cluster:ssl');
    print('  Value from shard: $val');

  } catch (e) {
    print('  ❌ Cluster Error: $e');
  } finally {
    await cluster.close();
  }
}