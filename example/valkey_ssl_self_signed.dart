import 'dart:io';
import 'package:valkey_client/valkey_client.dart';

void main() async {
  print('🔒 [Dev] Connecting to Standalone SSL (Self-Signed)...');

  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6380, // SSL Port
    useSsl: true,
    // [CRITICAL] Trust self-signed certificates for development
    onBadCertificate: (X509Certificate cert) {
      print('  ⚠️ Ignoring certificate error for: ${cert.subject}');
      return true;
    },
    // password: 'your_password',
  );

  final client = ValkeyClient.fromSettings(settings);

  try {
    await client.connect();
    print('  ✅ Connected!');
    await client.set('ssl:dev', 'works');
    print('  Value: ${await client.get('ssl:dev')}');
  } catch (e) {
    print('  ❌ Error: $e');
  } finally {
    await client.close();
  }
}