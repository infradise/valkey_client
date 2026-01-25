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

ValkeyLogger logger = ValkeyLogger('Object and String Example');

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

    await runObjectAndStringExamples(client);
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

Future<void> runObjectAndStringExamples(ValkeyClient client) async {
  logger.info('--- 🚀 JSON Object & String Commands Example ---');

  // ===========================================================================
  // Part 1: JSON Object Commands (Keys & Len)
  // ===========================================================================
  logger.info('[Part 1] JSON Object Commands');

  // 1. Setup: Create a nested JSON object
  // Data: { "user": "Alice", "meta": { "login_count": 5, "active": true } }
  await client.jsonSet(
    key: 'user:profile',
    path: r'$',
    data: {
      'user': 'Alice',
      'meta': {
        'login_count': 5,
        'active': true,
      }
    },
  );
  logger.info('1. Initialized object: {"user": "Alice", "meta": {...}}');

  // 2. JSON.OBJLEN
  // Count keys in the root object ('user', 'meta' -> 2 keys)
  final rootLen = (await client.jsonObjLen(
    key: 'user:profile',
    path: r'$',
  )) as int; // Casting dynamic to int

  logger.info('2. Root Object Length: $rootLen (Expected: 2)');

  // 3. JSON.OBJKEYS
  // Get keys from the 'meta' object
  final metaKeys = (await client.jsonObjKeys(
    key: 'user:profile',
    path: r'$.meta',
  )) as List<dynamic>; // Casting to List

  logger
      .info('3. Meta Object Keys: $metaKeys (Expected: [login_count, active])');

  // logger.info('-' * 50);

  // ===========================================================================
  // Part 2: JSON String Commands (Append & Len)
  // ===========================================================================
  logger.info('[Part 2] JSON String Commands');

  // 4. Setup: Create a JSON string
  await client.jsonSet(
    key: 'msg:greeting',
    path: r'$',
    data: 'Hello',
  );
  logger.info('4. Initialized string: "Hello"');

  // 5. JSON.STRLEN
  // Check length of "Hello" -> 5
  final initialLen = (await client.jsonStrLen(
    key: 'msg:greeting',
  )) as int;

  logger.info('5. Initial String Length: $initialLen (Expected: 5)');

  // 6. JSON.STRAPPEND
  // Append " World" to "Hello"
  final newLen = (await client.jsonStrAppend(
    key: 'msg:greeting',
    path: r'$',
    value: ' World',
  )) as int;

  logger.info('6. Length after Append: $newLen (Expected: 11)');

  // 7. Verify Content
  final fullString = (await client.jsonGet(
    key: 'msg:greeting',
  ))
      .toString();

  logger.info('7. Final String Content: "$fullString"');
}
