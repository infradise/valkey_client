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

  test('jsonSet & jsonGet - Smart String Handling', () async {
    // Case 1: Passing Raw JSON String (Array)
    // The library should auto-detect this is an array, not a string.
    await client.jsonSet(key: 'json:simple', path: r'$', data: '["a","b","c"]');

    final result = await client.jsonGet(key: 'json:simple');

    // Now it returns a List, NOT a String!
    expect(result, isA<List>());
    expect(result, equals(['a', 'b', 'c']));

    // verify we can access index
    final firstItem = await client.jsonGet(key: 'json:simple', path: r'$[0]');
    expect(firstItem,
        equals(['a'])); // Note: jsonGet path returns list of results usually
  });

  test('jsonSet & jsonGet - Smart Nested Object', () async {
    // Case 2: Passing Raw JSON String (Object)
    await client.jsonSet(
        key: 'json:nested',
        path: r'$',
        data: '{"foo":1,"bar":{"baz":[1,2,3],"qux":"val"}}');

    final result =
        await client.jsonGet(key: 'json:nested') as Map<String, dynamic>;

    // Now it returns a Map!
    expect(result, isA<Map>());
    expect(result['foo'], equals(1));
    expect((result['bar'] as Map)['qux'], equals('val'));
  });

  test('jsonSet & jsonGet - Simple Array Comparison', () async {
    final data1 = [
      'a',
      'b',
      'c',
    ];
    final data2 = [
      '1',
      '2',
      '3',
    ];
    await client.jsonSet(key: 'json:simple', path: r'$', data: data1);
    final result = await client.jsonGet(key: 'json:simple', path: '.');
    expect(result, equals(data1));
    expect(result, isNot(equals(data2)));
  });
}
