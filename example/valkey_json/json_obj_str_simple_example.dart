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

ValkeyLogger logger = ValkeyLogger('JSON Obj and Str Example');

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

    await testObjAndStrCommands(client);
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

Future<void> testObjAndStrCommands(ValkeyClient client) async {
  // 1. Setup Object
  await client
      .jsonSet(key: 'my_obj', path: r'$', data: {'name': 'Alice', 'age': 30});

  // jsonObjKeys
  final keys = await client.jsonObjKeys(key: 'my_obj');
  logger.info('Keys: $keys'); // ['name', 'age']

  // jsonObjLen
  final len = await client.jsonObjLen(key: 'my_obj');
  logger.info('Obj Len: $len'); // 2

  // 2. Setup String
  await client.jsonSet(key: 'my_str', path: r'$', data: 'Hello');

  // jsonStrAppend
  final newLen = await client.jsonStrAppend(key: 'my_str', value: ' World');
  logger.info('New Str Len: $newLen'); // 11

  // jsonStrLen
  final strLen = await client.jsonStrLen(key: 'my_str');
  logger.info('Str Len: $strLen'); // 11

  // Verify content
  final content = await client.jsonGet(key: 'my_str');
  logger.info('Content: $content'); // "Hello World"
}
