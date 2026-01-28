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

import 'dart:io' show File, SecurityContext, X509Certificate;

import 'package:valkey_client/valkey_client.dart';

void main() async {
  print('🔒 [Dev] Connecting to Cluster SSL (Self-Signed)...');

  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    sslContext: setupSecurityContext(),
    // [CRITICAL] Trust self-signed certificates for development
    onBadCertificate: (X509Certificate cert) {
      print('  ⚠️ Ignoring certificate error for: ${cert.subject}');
      // Apply callback to trust the bad cert
      return true; // Return true to allow the connection
    },
    // password: 'cluster_password',
  );

  // Define initial seed nodes with SSL settings
  final initialNodesWithoutSSL = [
    settings.copyWith(port: 7001, useSsl: false), // Plain Port
    // settings.copyWith(port: 7002),
    // settings.copyWith(port: 7003),
  ];

  final initialNodesWithSSL = [
    settings.copyWith(port: 7101, useSsl: true), // SSL Cluster Port
    // settings.copyWith(port: 7102),
    // settings.copyWith(port: 7103)
  ];

  print('--- Without SSL ---');
  await connectServer(initialNodesWithoutSSL);

  print('--- With SSL ---');
  await connectServer(initialNodesWithSSL);
}

Future<void> connectServer(List<ValkeyConnectionSettings> initialNodes) async {
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

SecurityContext? setupSecurityContext() {
  // Certificate paths (relative to the package root)
  // Ensure you have run the OpenSSL generation commands in 'tests/tls/'
  const caCertPath = 'tests/tls/valkey.crt';
  const clientCertPath =
      'tests/tls/valkey.crt'; // Using the same cert for testing
  const clientKeyPath = 'tests/tls/valkey.key';

  // 1. Check if certificate files exist before running the test
  if (!File(caCertPath).existsSync() || !File(clientKeyPath).existsSync()) {
    print('⚠️ SKIPPING mTLS TEST: Certificate files not found in tests/tls/');
    return null;
  }

  // 2. Configure SecurityContext with Client Certificate & Key
  final context = SecurityContext(withTrustedRoots: true);
  context.setTrustedCertificates(caCertPath);
  context.useCertificateChain(clientCertPath);
  context.usePrivateKey(clientKeyPath);

  return context;
}
