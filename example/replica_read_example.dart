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

import 'package:valkey_client/valkey_client.dart';

void main() async {
  // Enable detailed logging
  // ValkeyClient.setLogLevel(ValkeyLogLevel.info);

  print('🚀 Starting Replica Read & Load Balancing Example...');

  const portMaster = 6379; // Master Port (e.g., 1 Master and 2 Replicas)
  // final portReplica1 = 6380;
  // final portReplica2 = 6381;

  // Base settings for Master
  final masterSettings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: portMaster,

    // addressMapper: (host, port) {
    //   print('Current host:port = $host:$port');
    //   if (host.startsWith('127')) {
    //     host = '128.0.0.1';
    //     print('Changed host:port = $host:$port');
    //     return (host: host, port: port);
    //   }
    //   return (host: host, port: port);
    // },

    // [v2.2.0] Prefer reading from replicas
    readPreference:
        ReadPreference.preferReplica, // master, preferReplica, replicaOnly
    // [v2.2.0] Use Round-Robin to distribute load among replicas
    loadBalancingStrategy: LoadBalancingStrategy.roundRobin,
    commandTimeout: const Duration(seconds: 2),
    // If you had password/SSL, you'd set it here once.
  );

  // 1. Configure Connection Settings
  // We connect to the Master (6379), but request to read from Replicas.

  // Define full settings for this connection, including explicit replicas
  // final settings = masterSettings.copyWith(
  //   explicitReplicas: [
  //     // Inherit master settings (Auth, SSL, etc.) and just change Port
  //     masterSettings.copyWith(port: portReplica1),
  //     masterSettings.copyWith(port: portReplica2),
  //   ],
  // );
  // final client = ValkeyClient.fromSettings(settings);

  final client = ValkeyClient.fromSettings(masterSettings);

  try {
    // 2. Connect
    // Internally, this will connect to Master AND discover/connect to Replicas (6380, 6381).
    await client.connect();
    print('✅ Connected to Master and Discovered Replicas.');

    // --- Data Setup ---
    // 3. Write Operation (Always goes to Master)
    // SET is not a read-only command.
    print('\n✍️  Writing data (Routed to Master)...');
    for (var i = 0; i < 5; i++) {
      await client.set('user:$i', 'value_$i');
    }

    // Wait briefly for replication to happen (usually near-instant)
    await Future<void>.delayed(
        const Duration(milliseconds: 100)); // 100 or 200: Replication wait

    // --- Read & Verify Load Balancing ---
    // 4. Read Operations (Routed to Replicas)
    // GET is a read-only command.
    // Because we use Round-Robin, requests should alternate between Replica 1
    // and Replica 2.
    print('\n📖 Reading data (Routed to Replicas via Round-Robin)...');

    for (var i = 0; i < 5; i++) {
      final key = 'user:$i';
      final value = await client.get(key);

      final usedConfig = client.lastUsedConnectionConfig;

      var sourceName = 'Unknown';
      if (usedConfig != null) {
        if (usedConfig.port == portMaster) {
          sourceName = 'Master';
        } else {
          sourceName = 'Replica (${usedConfig.port})';
        }
      }

      print('   [GET $key] -> Result: $value -- from $sourceName');
      // Conceptually:
      // Req 1 -> Replica 1 (6380)
      // Req 2 -> Replica 2 (6381)
      // Req 3 -> Replica 1 (6380) ...
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await client.close();
    print('\n👋 Connection closed.');
  }
}
