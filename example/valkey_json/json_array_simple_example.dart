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

ValkeyLogger logger = ValkeyLogger('JSON Array Simple Example');

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

    await testArrayCommands(client);
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

Future<void> testArrayCommands(ValkeyClient client) async {
  // 1. Setup: Create an initial array
  await client.jsonSet(key: 'my_list', path: r'$', data: ['a', 'b', 'c']);

  // 2. Append (Add 'd' and 'e')
  // Equivalent to: JSON.ARRAPPEND my_list $ "d" "e"
  final newLen = await client.jsonArrAppend(key: 'my_list', values: ['d', 'e']);
  logger.info('New Length: $newLen'); // 5

  // 3. Insert (Insert 'X' at index 1)
  // Array becomes: ['a', 'X', 'b', 'c', 'd', 'e']
  await client
      .jsonArrInsert(key: 'my_list', path: r'$', index: 1, values: ['X']);

  // 4. Index (Find index of 'X')
  final index =
      await client.jsonArrIndex(key: 'my_list', path: r'$', value: 'X');
  logger.info('Index of X: $index'); // 1

  // 5. Trim (Keep only index 0 to 2)
  // Array becomes: ['a', 'X', 'b']
  await client.jsonArrTrim(key: 'my_list', path: r'$', start: 0, stop: 2);

  // 6. Pop (Remove last element 'b')
  final popped = await client.jsonArrPop(key: 'my_list');
  logger.info('Popped Value: $popped'); // 'b'

  // Final Check
  final finalArr = await client.jsonGet(key: 'my_list');
  logger.info('Final Array: $finalArr'); // ['a', 'X']
}
