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

ValkeyLogger logger = ValkeyLogger('Get Enhanced Paths Example');

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

    await runEnhancedExamples(client);
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

Future<void> runEnhancedExamples(ValkeyClient client) async {
  logger.info('--- JSON Enhanced Path Commands Example ---');

  // ===========================================================================
  // Part 1: Array Operations (Append, Insert, Index, Len, Pop, Trim)
  // ===========================================================================
  logger.info('🚀 [Part 1] Array Enhanced Operations');

  // 1. Setup: Create a JSON document with multiple arrays
  // Structure:
  // - a: [1]
  // - b.c: [2]
  // - d: "not_array" (to test null result)
  await client.jsonSet(
    key: 'doc:arrays',
    path: r'$',
    data: {
      'a': [1],
      'b': {
        'c': [2]
      },
      'd': 'not_array'
    },
  );
  logger.info('1. Initialized: {"a": [1], "b": {"c": [2]}, "d": "not_array"}');

  // 2. JSON.ARRAPPEND (Enhanced)
  // Append 3 to '$.a' and '$.b.c', and try on '$.d' and '$.missing'
  final appendResult = await client.jsonArrAppendEnhanced(
    key: 'doc:arrays',
    paths: [r'$.a', r'$.b.c', r'$.d', r'$.missing'],
    value: 3,
  );
  logger.info('2. ArrAppend Result: $appendResult');
  // Expected: [2, 2, null, null] (New lengths)

  // 3. JSON.ARRINSERT (Enhanced)
  // Insert 99 at index 0 for '$.a' and '$.b.c'
  final insertResult = await client.jsonArrInsertEnhanced(
    key: 'doc:arrays',
    paths: [r'$.a', r'$.b.c'],
    index: 0,
    values: [99],
  );
  logger.info('3. ArrInsert Result: $insertResult');
  // Expected: [3, 3] (New lengths: [99, 1, 3], [99, 2, 3])

  // 4. JSON.ARRINDEX (Enhanced)
  // Find index of 99
  final indexResult = await client.jsonArrIndexEnhanced(
    key: 'doc:arrays',
    paths: [r'$.a', r'$.b.c'],
    value: 99,
  );
  logger.info('4. ArrIndex Result : $indexResult');
  // Expected: [0, 0]

  // 5. JSON.ARRLEN (Enhanced)
  // Get lengths
  final lenResult = await client.jsonArrLenEnhanced(
    key: 'doc:arrays',
    paths: [r'$.a', r'$.b.c'],
  );
  logger.info('5. ArrLen Result   : $lenResult');
  // Expected: [3, 3]

  // 6. JSON.ARRPOP (Enhanced)
  // Pop the last element from arrays
  final popResult = await client.jsonArrPopEnhanced(
    key: 'doc:arrays',
    paths: [r'$.a', r'$.b.c'],
    index: -1, // Last element
  );
  logger.info('6. ArrPop Result   : $popResult');
  // Expected: [3, 3] (The popped values)

  // 7. JSON.ARRTRIM (Enhanced)
  // Trim arrays to keep only index 0 (keep just the first element '99')
  final trimResult = await client.jsonArrTrimEnhanced(
    key: 'doc:arrays',
    paths: [r'$.a', r'$.b.c'],
    start: 0,
    stop: 0,
  );
  logger.info('7. ArrTrim Result  : $trimResult');
  // Expected: [1, 1] (New length)

  // ===========================================================================
  // Part 2: Object Operations (Keys)
  // ===========================================================================
  logger.info('🚀 [Part 2] Object Enhanced Operations');

  // 8. Setup
  await client.jsonSet(
    key: 'doc:objects',
    path: r'$',
    data: {
      'user': {'name': 'Alice', 'role': 'admin'},
      'meta': {'created': '2024', 'active': true},
      'list': [1, 2] // Not an object
    },
  );

  // 9. JSON.OBJKEYS (Enhanced)
  // Get keys from '$.user' and '$.meta'
  final keysResult = await client.jsonObjKeysEnhanced(
    key: 'doc:objects',
    paths: [r'$.user', r'$.meta', r'$.list'],
  );
  logger.info('9. ObjKeys Result  : $keysResult');
  // Expected: [[name, role], [created, active], null]

  // ===========================================================================
  // Part 3: String Operations (Append, Len)
  // ===========================================================================
  logger.info('🚀 [Part 3] String Enhanced Operations');

  // 10. Setup
  await client.jsonSet(
    key: 'doc:strings',
    path: r'$',
    data: {
      's1': 'Hello',
      's2': 'Good',
      'n': 123 // Not a string
    },
  );

  // 11. JSON.STRAPPEND (Enhanced)
  // Append " World" to '$.s1' and '$.s2'
  final strAppendResult = await client.jsonStrAppendEnhanced(
    key: 'doc:strings',
    paths: [r'$.s1', r'$.s2', r'$.n'],
    value: ' World',
  );
  logger.info('11. StrAppend Result: $strAppendResult');
  // Expected: [11, 10, null] (Lengths of "Hello World", "Good World", null)

  // 12. JSON.STRLEN (Enhanced)
  final strLenResult = await client.jsonStrLenEnhanced(
    key: 'doc:strings',
    paths: [r'$.s1', r'$.s2'],
  );
  logger.info('12. StrLen Result   : $strLenResult');
  // Expected: [11, 10]
}
