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

ValkeyLogger logger = ValkeyLogger('JSON Debug Type Simple Example');

void main() async {
  logger.setEnableValkeyLog(true); // Enable all log levels (default: false)

  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6379,
  );

  final client = ValkeyClient.fromSettings(settings);

  try {
    await client.connect();

    // Check environment before running logic
    if (!await client.isJsonModuleLoaded()) {
      logger.info('❌ Error: JSON module is NOT loaded on this server.');
      // logger.info('   Please install valkey-json or redis-stack.');
      return;
    } else {
      logger.info('✅ JSON module detected. Ready to go!');
    }

    await runDebugTypeExamples(client);
  } on ValkeyConnectionException catch (e) {
    logger.error('❌ Connection Failed: $e');
    logger.error('Ensure a Redis or Valkey CLUSTER node is running.');
  } on ValkeyServerException catch (e) {
    logger.error('❌ Server Error: $e');
  } on ValkeyClientException catch (e) {
    logger.error('❌ Client Error: $e');
  } on FeatureNotImplementedException catch (e) {
    logger.error('❌ Feature Not Implemented: $e');
  } catch (e) {
    logger.error('❌ Unknown Error: $e');
  } finally {
    // Close all cluster connections
    logger.info('Closing all cluster connections...');
    await client.close();
  }
}

Future<void> runDebugTypeExamples(ValkeyClient client) async {
  logger.info('--- 🚀 JSON Debug/Type/Toggle Examples ---');

  // 1. Setup Data
  // { "isActive": true, "name": "Valkey", "count": 10 }
  await client.jsonSet(
      key: 'config:app',
      path: r'$',
      data: {'isActive': true, 'name': 'Valkey', 'count': 10});

  // 2. JSON.TYPE
  final type = await client.jsonType(key: 'config:app', path: r'$');
  logger.info('Type (root): $type'); // Expected: object

  final nameType = await client.jsonType(key: 'config:app', path: r'$.name');
  logger.info('Type (name): $nameType'); // Expected: string

  // 3. JSON.TOGGLE
  // Toggle 'isActive' (true -> false)
  final newVal =
      await client.jsonToggle(key: 'config:app', path: r'$.isActive');
  logger.info('Toggled isActive: $newVal'); // Expected: 0 (false)

  // 4. JSON.DEBUG MEMORY
  final memoryBytes = await client.jsonDebug(key: 'config:app');
  logger
      .info('Memory Usage: $memoryBytes bytes'); // Expected: Integer (e.g. 120)

  // 5. JSON.RESP
  // Returns the raw structure (e.g., ['{', 'isActive', 'false', ...])
  // depending on implementation
  final resp = await client.jsonResp(key: 'config:app');
  logger.info('RESP Dump: $resp');
}
