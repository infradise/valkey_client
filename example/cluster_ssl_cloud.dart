/*
 * Copyright 2026 Infradise Inc.
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
