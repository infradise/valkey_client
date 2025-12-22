import 'package:valkey_client/valkey_client.dart';

// ---------------------------------------------------------
// Scenario 2: Connecting to a Cloud Provider (Prod)
// (e.g., AWS ElastiCache, Azure Redis, GCP MemoryStore)
// ---------------------------------------------------------

void main() async {
  print('☁️ [Prod] Connecting to Cloud Provider SSL (Trusted CA)...');

  final settings = ValkeyConnectionSettings(
    // Example endpoint for AWS ElastiCache or Azure Redis
    host: 'master.my-cluster.cache.amazonaws.com',
    // host: 'my-redis.region.cache.amazonaws.com',
    port: 6379, // Standard SSL port often remains 6379 or 6380
    useSsl: true,
    // Just enable SSL, standard CA is trusted by Dart/OS automatically
    // No onBadCertificate needed because Cloud CAs are trusted by OS/Dart
    password: 'your_auth_token', // or auth-token-here
  );

  final client = ValkeyClient.fromSettings(settings);

  try {
    await client.connect();
    print('  ✅ Connected securely to Cloud!');

    await client.set('ssl:dev', 'works');
    print('  Value: ${await client.get('ssl:dev')}');

    final response = await client.ping();
    print('  📤 PING -> 📥 $response');

    await client.set('ssl_key', 'Hello Secure World');
    final val = await client.get('ssl_key');
    print('  📤 GET ssl_key -> 📥 $val');

  } catch (e) {
    print('  ❌ Connection failed: $e');
  } finally {
    await client.close();
  }
}