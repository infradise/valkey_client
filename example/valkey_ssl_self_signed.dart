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

import 'dart:io';
import 'package:valkey_client/valkey_client.dart';

// ---------------------------------------------------------
// Scenario 1: Connecting to a Self-Signed Local Server (Dev)
// ---------------------------------------------------------

void main() async {
  print('🔒 [Dev] Connecting to Standalone SSL (Self-Signed)...');

  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6380, // SSL Port
    useSsl: true,
    // [CRITICAL] Trust self-signed certificates for development
    onBadCertificate: (X509Certificate cert) {
      print('  ⚠️ Ignoring certificate error for: ${cert.subject}');
      return true; // Return true to allow the connection
    },
    // Optional: Password if configured
    // password: 'your_password',
  );

  final client = ValkeyClient.fromSettings(settings);

  try {
    await client.connect();
    print('  ✅ Connected securely!');

    await client.set('ssl:dev', 'works');
    print('  Value: ${await client.get('ssl:dev')}');

    final response = await client.ping();
    print('  📤 PING -> 📥 $response');

    await client.set('ssl_key', 'Hello Secure World');
    final val = await client.get('ssl_key');
    print('  📤 GET ssl_key -> 📥 $val');
  } catch (e) {
    print('  ❌ Error: $e'); // Connection failed
  } finally {
    await client.close();
  }
}
