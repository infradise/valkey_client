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

import 'package:test/test.dart';
import 'package:valkey_client/src/utils/module_printer.dart'
    show printPrettyModuleList;
import 'package:valkey_client/valkey_client.dart';

void main() async {
  // (Standalone: 6379 / Cluster: 7001)
  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6379,
  );

  // final client = ValkeyClient(host: '127.0.0.1', port: 6379);
  final client = ValkeyClient.fromSettings(settings);

  setUpAll(() async {
    await client.connect();
  });

  tearDownAll(() async {
    await client.close();
  });

  // Check environment before running logic
  test('Redis/Valkey Module Detector', () async {
    final isModuleLoaded = await client.isJsonModuleLoaded();
    print(isModuleLoaded);
    expect(isModuleLoaded, true);
  });

  test('Redis/Valkey Module List', () async {
    final modules = await client.getModuleList();
    expect(modules, isNotNull);
    printPrettyModuleList(modules);
  });

  group('JSON Array Commands', () {
    // 1. JSON.ARRAPPEND
    test('jsonArrAppend - append multiple values', () async {
      // Setup: Initial array [1]
      await client.jsonSet(key: 'arr:append', path: r'$', data: [1]);

      // Action: Append 2 and 3
      final newLen = await client
          .jsonArrAppend(key: 'arr:append', path: r'$', values: [2, 3]);

      // Verify: Length should be 3
      expect(newLen, equals(3));

      // Verify: Content should be [1, 2, 3]
      final result = await client.jsonGet(key: 'arr:append');
      expect(result, equals([1, 2, 3]));
    });

    // 2. JSON.ARRINDEX
    test('jsonArrIndex - find index of element', () async {
      // Setup: Array ['apple', 'banana', 'cherry', 'banana']
      await client.jsonSet(
          key: 'arr:index',
          path: r'$',
          data: ['apple', 'banana', 'cherry', 'banana']);

      // Action: Find index of 'banana'
      final index1 = await client.jsonArrIndex(
          key: 'arr:index', path: r'$', value: 'banana');

      // Verify: First occurrence is at index 1
      expect(index1, equals(1));

      // Action: Find 'banana' starting from index 2
      final index2 = await client.jsonArrIndex(
          key: 'arr:index', path: r'$', value: 'banana', start: 2);

      // Verify: Next occurrence is at index 3
      expect(index2, equals(3));

      // Action: Find non-existent value
      final index3 = await client.jsonArrIndex(
          key: 'arr:index', path: r'$', value: 'durian');

      // Verify: Returns -1
      expect(index3, equals(-1));
    });

    // 3. JSON.ARRINSERT
    test('jsonArrInsert - insert values at specific index', () async {
      // Setup: Array [1, 4]
      await client.jsonSet(key: 'arr:insert', path: r'$', data: [1, 4]);

      // Action: Insert 2 and 3 at index 1
      // Resulting array should be [1, 2, 3, 4]
      final newLen = await client.jsonArrInsert(
          key: 'arr:insert', path: r'$', index: 1, values: [2, 3]);

      // Verify: Length should be 4
      expect(newLen, equals(4));

      // Verify: Content check
      final result = await client.jsonGet(key: 'arr:insert');
      expect(result, equals([1, 2, 3, 4]));
    });

    // 4. JSON.ARRLEN
    test('jsonArrLen - get array length', () async {
      // Setup: Array with 5 elements
      await client
          .jsonSet(key: 'arr:len', path: r'$', data: [10, 20, 30, 40, 50]);

      // Action: Get length
      final length = await client.jsonArrLen(key: 'arr:len');

      // Verify: Length is 5
      expect(length, equals(5));
    });

    // 5. JSON.ARRPOP
    test('jsonArrPop - pop elements', () async {
      // Setup: Array [10, 20, 30]
      await client.jsonSet(key: 'arr:pop', path: r'$', data: [10, 20, 30]);

      // Case A: Pop last element (default)
      final poppedLast = await client.jsonArrPop(key: 'arr:pop');
      expect(poppedLast, equals(30)); // 30 is returned as int/num

      // Verify: Array is now [10, 20]
      var currentArr = await client.jsonGet(key: 'arr:pop');
      expect(currentArr, equals([10, 20]));

      // Case B: Pop element at index 0
      final poppedFirst = await client.jsonArrPop(key: 'arr:pop', index: 0);
      expect(poppedFirst, equals(10));

      // Verify: Array is now [20]
      currentArr = await client.jsonGet(key: 'arr:pop');
      expect(currentArr, equals([20]));
    });

    // 6. JSON.ARRTRIM
    test('jsonArrTrim - trim array range', () async {
      // Setup: Array [0, 1, 2, 3, 4, 5]
      await client
          .jsonSet(key: 'arr:trim', path: r'$', data: [0, 1, 2, 3, 4, 5]);

      // Action: Trim to keep indices 2 to 4 (values 2, 3, 4)
      final newLen = await client.jsonArrTrim(
          key: 'arr:trim', path: r'$', start: 2, stop: 4);

      // Verify: New length is 3
      expect(newLen, equals(3));

      // Verify: Content matches [2, 3, 4]
      final result = await client.jsonGet(key: 'arr:trim');
      expect(result, equals([2, 3, 4]));
    });
  });
}
