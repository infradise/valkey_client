import 'package:valkey_client/valkey_client.dart';

void main() async {
  print('☁️ [Prod] Connecting to Cloud Cluster SSL...');

  final initialNodes = [
    ValkeyConnectionSettings(
      host: 'clustercfg.my-cluster.cache.amazonaws.com',
      port: 6379,
      useSsl: true,
      // Standard CA is trusted automatically
      password: 'your_auth_token',
    ),
  ];

  final cluster = ValkeyClusterClient(initialNodes);

  try {
    await cluster.connect();
    print('  ✅ Cloud Cluster Connected!');
  } catch (e) {
    print('  ❌ Error: $e');
  } finally {
    await cluster.close();
  }
}