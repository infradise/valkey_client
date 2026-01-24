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

ValkeyLogger logger = ValkeyLogger('JSON Array Basic Example');

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

    await runArrayExamples(client);
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

Future<void> runArrayExamples(ValkeyClient client) async {
  logger.info('--- 🚀 JSON Array Commands Example ---');

  // 0. Setup: Create an initial array
  // Data: ['apple', 'banana']
  await client.jsonSet(
    key: 'fruits',
    path: r'$',
    data: ['apple', 'banana'],
  );
  logger.info('0. Initialized: ["apple", "banana"]');

  // ---------------------------------------------------------
  // 1. JSON.ARRAPPEND
  // Appends 'cherry' and 'date' to the end.
  // ---------------------------------------------------------
  final lenAfterAppend = (await client.jsonArrAppend(
    key: 'fruits',
    path: r'$',
    values: ['cherry', 'date'],
  )) as int; // Return type is dynamic, so we cast it to int.
  logger.info('1. ARRAPPEND result: $lenAfterAppend');
  // Expected: 4
  // Array: ['apple', 'banana', 'cherry', 'date']

  // ---------------------------------------------------------
  // 2. JSON.ARRINSERT
  // Inserts 'mango' at index 1.
  // ---------------------------------------------------------
  final lenAfterInsert = await client.jsonArrInsert(
    key: 'fruits',
    path: r'$',
    index: 1,
    values: ['mango'],
  ) as int; // Return type is dynamic, so we cast it to int.
  logger.info('2. ARRINSERT result: $lenAfterInsert');
  // Expected: 5
  // Array: ['apple', 'mango', 'banana', 'cherry', 'date']

  // ---------------------------------------------------------
  // 3. JSON.ARRINDEX
  // Finds the index of 'banana'.
  // ---------------------------------------------------------
  final index = await client.jsonArrIndex(
    key: 'fruits',
    path: r'$',
    value: 'banana',
  ) as int; // Return type is dynamic, so we cast it to int.
  logger.info('3. ARRINDEX ("banana"): $index');
  // Expected: 2

  // ---------------------------------------------------------
  // 4. JSON.ARRLEN
  // Gets current array length.
  // ---------------------------------------------------------
  final length = await client.jsonArrLen(
    key: 'fruits',
    path: r'$',
  ) as int; // Return type is dynamic, so we cast it to int.
  logger.info('4. ARRLEN result: $length');
  // Expected: 5

  // ---------------------------------------------------------
  // 5. JSON.ARRPOP
  // Removes and returns the last element ('date').
  // ---------------------------------------------------------
  final dynamic poppedValue = await client.jsonArrPop(
    key: 'fruits',
    path: r'$',
    // index: -1 (default is last)
  );
  logger.info('5. ARRPOP result: $poppedValue');
  // Expected: "date" (String)
  // Array: ['apple', 'mango', 'banana', 'cherry']

  // ---------------------------------------------------------
  // 6. JSON.ARRTRIM
  // Trims array to keep only indices 0 to 1.
  // ---------------------------------------------------------
  final lenAfterTrim = await client.jsonArrTrim(
    key: 'fruits',
    path: r'$',
    start: 0,
    stop: 1,
  ) as int; // Return type is dynamic, so we cast it to int.
  logger.info('6. ARRTRIM result: $lenAfterTrim');
  // Expected: 2
  // Final Array: ['apple', 'mango']

  // --- Final Check ---
  final finalData = await client.jsonGet(key: 'fruits');
  logger.info('✅ Final Data: $finalData');
}
