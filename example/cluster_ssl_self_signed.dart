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
