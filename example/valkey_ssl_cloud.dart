import 'package:valkey_client/valkey_client.dart';

void main() async {
  print('☁️ [Prod] Connecting to Cloud SSL (Trusted CA)...');

  final settings = ValkeyConnectionSettings(
    // Example endpoint for AWS ElastiCache or Azure Redis
    host: 'master.my-cluster.cache.amazonaws.com',
    port: 6379, // Standard SSL port often remains 6379 or 6380
    useSsl: true,
    // No onBadCertificate needed because Cloud CAs are trusted by OS/Dart
    password: 'your_auth_token',
  );

  final client = ValkeyClient.fromSettings(settings);

  try {
    await client.connect();
    print('  ✅ Connected securely to Cloud!');
  } catch (e) {
    print('  ❌ Connection failed: $e');
  } finally {
    await client.close();
  }
}