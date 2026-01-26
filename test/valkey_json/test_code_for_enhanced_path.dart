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

  // Test for commands with enhancedPaths

  test('jsonArrAppendEnhanced - append to multiple arrays', () async {
    await client.jsonSet(
        key: 'doc:arrAppendEnh',
        path: '.',
        data: '{"a":[1], "b":{"c":[2]}, "d":"not_array"}');
    final result = await client.jsonArrAppendEnhanced(
      key: 'doc:arrAppendEnh',
      paths: [r'$.a', r'$.b.c', r'$.d', r'$.nonexistent'],
      // (X) value: '3', // JSON encoded value
      value: 3, // Expected Usage
    );
    expect(result, equals([2, 2, null, null]));
    final finalDoc =
        await client.jsonGet(key: 'doc:arrAppendEnh', path: '.') as Map;

    // (X) expect(finalDoc, contains('"a":[1,3]'));
    expect(finalDoc, containsPair('a', [1, 3])); // Expected Usage

    // (X) expect(finalDoc, contains('"c":[2,3]'));
    //
    final b = finalDoc['b'] as Map<String, dynamic>;
    expect(b['c'], equals([2, 3])); // Expected Usage
    expect(finalDoc,
        containsPair('b', containsPair('c', [2, 3]))); // Expected Usage
    // Expected Usage
    expect(finalDoc.containsKey('b'), isTrue);
    expect(b, isA<Map>());
    expect((b as Map).containsKey('c'), isTrue);
    expect((b as Map)['c'], equals([2, 3]));
  });

  test('jsonArrIndexEnhanced - find in multiple arrays', () async {
    await client.jsonSet(
      key: 'doc:arrIndexEnh',
      path: '.',
      data: '{"a":[1,2,3], "b":{"c":[3,4,5]}, "d":"not_array"}',
    );
    final result = await client.jsonArrIndexEnhanced(
      key: 'doc:arrIndexEnh',
      paths: [r'$.a', r'$.b.c', r'$.d', r'$.nonexistent'],
      // (X) value: '3', // JSON encoded value
      value: 3, // Expected Usage
      start: null,
      stop: null,
    );
    expect(result, equals([2, 0, null, null]));
  });

  test('jsonArrInsertEnhanced - insert into multiple arrays', () async {
    await client.jsonSet(
        key: 'doc:arrInsertEnh',
        path: '.',
        data: '{"a":[1,3], "b":{"c":[4,6]}, "d":"not_array"}');
    final result = await client.jsonArrInsertEnhanced(
      key: 'doc:arrInsertEnh',
      paths: [r'$.a', r'$.b.c', r'$.d', r'$.nonexistent'],
      index: 1,
      // (X) values: ['2', '5'], // JSON encoded values
      values: [2, 5], // Expected Usage
    );
    // Note: JSON.ARRINSERT inserts all values at the specified index for
    // each matched path.
    // The command takes multiple values to insert, but the enhanced path
    // applies to each path individually.
    // So, for '$.a', it inserts '2' and '5' at index 1. For '$.b.c', it
    // inserts '2' and '5' at index 1.
    // The return is the new length of *each* array.
    expect(result, equals([4, 4, null, null])); // [1,2,5,3] and [4,2,5,6]
    final finalDoc = await client.jsonGet(key: 'doc:arrInsertEnh', path: '.');

    // (X) expect(finalDoc, contains('"a":[1,2,5,3]'));
    expect(finalDoc, containsPair('a', [1, 2, 5, 3])); // Expected Usage

    // (X) expect(finalDoc, contains('"c":[4,2,5,6]'));
    expect(finalDoc,
        containsPair('b', containsPair('c', [4, 2, 5, 6]))); // Expected Usage
  });

  test('jsonArrLenEnhanced - get lengths of multiple arrays', () async {
    await client.jsonSet(
        key: 'doc:arrLenEnh',
        path: '.',
        data: '{"a":[1,2,3], "b":{"c":[4,5]}, "d":"not_array"}');
    final result = await client.jsonArrLenEnhanced(
      key: 'doc:arrLenEnh',
      paths: [r'$.a', r'$.b.c', r'$.d', r'$.nonexistent'],
    );
    expect(result, equals([3, 2, null, null]));
  });

  test('jsonArrPopEnhanced - pop from multiple arrays', () async {
    await client.jsonSet(
      key: 'doc:arrPopEnh',
      path: '.',
      data: '{"a":[1,2,3], "b":{"c":[4,5,6]}, "d":"not_array", "e":[]}',
    );
    final result = await client.jsonArrPopEnhanced(
      key: 'doc:arrPopEnh',
      paths: [r'$.a', r'$.b.c', r'$.d', r'$.e', r'$.nonexistent'],
      index: 1,
    );
    // (X) expect(result, equals(['2', '5', null, null, null]));
    expect(result, equals([2, 5, null, null, <List>[]])); // Expected Usage

    final finalDoc = await client.jsonGet(key: 'doc:arrPopEnh', path: '.');

    // (X) expect(finalDoc, contains('"a":[1,3]'));
    expect(finalDoc, containsPair('a', [1, 3])); // Expected Usage

    // (X) expect(finalDoc, contains('"c":[4,6]'));
    expect(finalDoc,
        containsPair('b', containsPair('c', [4, 6]))); // Expected Usage
  });

  test('jsonArrTrimEnhanced - trim multiple arrays', () async {
    await client.jsonSet(
      key: 'doc:arrTrimEnh',
      path: '.',
      data: '{"a":[1,2,3,4], "b":{"c":[5,6,7,8]}, "d":"not_array"}',
    );
    final result = await client.jsonArrTrimEnhanced(
      key: 'doc:arrTrimEnh',
      paths: [r'$.a', r'$.b.c', r'$.d', r'$.nonexistent'],
      start: 1,
      stop: 2,
    );
    expect(result, equals([2, 2, null, null]));
    final finalDoc = await client.jsonGet(key: 'doc:arrTrimEnh', path: '.');

    // (X) expect(finalDoc, contains('"a":[2,3]'));
    expect(finalDoc, containsPair('a', [2, 3])); // Expected Usage

    // (X) expect(finalDoc, contains('"c":[6,7]'));
    expect(finalDoc,
        containsPair('b', containsPair('c', [6, 7]))); // Expected Usage
  });

  test('jsonObjKeysEnhanced - get keys from multiple objects', () async {
    await client.jsonSet(
      key: 'doc:objKeysEnh',
      path: '.',
      data: '{"obj1":{"a":1,"b":2}, "arr":[1,2], "obj2":{"c":3,"d":4}}',
    );
    final result = await client.jsonObjKeysEnhanced(
      key: 'doc:objKeysEnh',
      paths: [r'$.obj1', r'$.obj2', r'$.arr', r'$.nonexistent'],
    );
    expect(result, isNotNull);
    expect(result!.length, 4);
    expect(result[0], containsAll(['a', 'b']));
    expect(result[1], containsAll(['c', 'd']));

    // (X) expect(result[2], isNull); // $.arr is not an object
    expect(result[2], isEmpty); // Expected Usage

    // (X) expect(result[3], isNull); // $.nonexistent
    expect(result[3], isEmpty); // Expected Usage
  });

  test('jsonStrAppendEnhanced - append to multiple strings', () async {
    await client.jsonSet(
        key: 'doc:strAppendEnh',
        path: '.',
        data: '{"s1":"hello", "s2":"world", "arr":[1,2]}');
    final result = await client.jsonStrAppendEnhanced(
      key: 'doc:strAppendEnh',
      paths: [r'$.s1', r'$.s2', r'$.arr', r'$.nonexistent'],
      // (X) value: '"_suffix"', // JSON encoded string
      value: '_suffix', // Expected Usage (length: 7)
    );
    expect(
        result,
        equals([
          // (X) 13,
          12, // Expected Usage (5 + 7 = 12)
          // (X) 13,
          12, // Expected Usage (5 + 7 = 12)
          null,
          null
        ])); // "hello_suffix", "world_suffix" (length of "value" is 8)
    final finalDoc = await client.jsonGet(key: 'doc:strAppendEnh', path: '.');

    // (X) expect(finalDoc, contains('"s1":"hello_suffix"'));
    expect(finalDoc, containsPair('s1', 'hello_suffix'));

    // (X) expect(finalDoc, contains('"s2":"world_suffix"'));
    expect(finalDoc, containsPair('s2', 'world_suffix'));
  });

  // test('jsonStrLenEnhanced - get lengths of multiple strings', () async {
  //   await client.jsonSet(
  //       key: 'doc:strLenEnh',
  //       path: '.',
  //       data: '{"s1":"hello", "s2":"world123", "arr":[1,2]}');
  //   final result = await client.jsonStrLenEnhanced(
  //     key: 'doc:strLenEnh',
  //     paths: [r'$.s1', r'$.s2', r'$.arr', r'$.nonexistent'],
  //   );
  //   expect(result, equals([5, 8, null, null]));
  // });

  // test('jsonArrAppendEnhanced - key does not exist', () async {
  //   final result = await client.jsonArrAppendEnhanced(
  //     key: 'nonexistent:arrAppendEnh',
  //     paths: [r'$.a'],
  //     value: '1',
  //   );
  //   expect(result, isNull);
  // });

  // test('jsonArrIndexEnhanced - key does not exist', () async {
  //   final result = await client.jsonArrIndexEnhanced(
  //     key: 'nonexistent:arrIndexEnh',
  //     paths: [r'$.a'],
  //     value: '1',
  //     start: null,
  //     stop: null,
  //   );
  //   expect(result, isNull);
  // });

  // test('jsonArrInsertEnhanced - key does not exist', () async {
  //   final result = await client.jsonArrInsertEnhanced(
  //     key: 'nonexistent:arrInsertEnh',
  //     paths: [r'$.a'],
  //     index: 0,
  //     values: ['1'],
  //   );
  //   expect(result, isNull);
  // });

  // test('jsonArrLenEnhanced - key does not exist', () async {
  //   final result = await client
  //       .jsonArrLenEnhanced(key: 'nonexistent:arrLenEnh', paths: [r'$.a']);
  //   expect(result, isNull);
  // });

  // test('jsonArrPopEnhanced - key does not exist', () async {
  //   final result = await client.jsonArrPopEnhanced(
  //       key: 'nonexistent:arrPopEnh', paths: [r'$.a'], index: 0);
  //   expect(result, isNull);
  // });

  // test('jsonArrTrimEnhanced - key does not exist', () async {
  //   final result = await client.jsonArrTrimEnhanced(
  //     key: 'nonexistent:arrTrimEnh',
  //     paths: [r'$.a'],
  //     start: 0,
  //     stop: 0,
  //   );
  //   expect(result, isNull);
  // });

  // test('jsonObjKeysEnhanced - key does not exist', () async {
  //   final result = await client
  //       .jsonObjKeysEnhanced(key: 'nonexistent:objKeysEnh', paths: [r'$.a']);
  //   expect(result, isNull);
  // });

  // test('jsonStrappendEnhanced - key does not exist', () async {
  //   final result = await client.jsonStrAppendEnhanced(
  //     key: 'nonexistent:strAppendEnh',
  //     paths: [r'$.a'],
  //     value: '"suffix"',
  //   );
  //   expect(result, isNull);
  // });

  // test('jsonStrLenEnhanced - key does not exist', () async {
  //   final result = await client
  //       .jsonStrLenEnhanced(key: 'nonexistent:strLenEnh', paths: [r'$.a']);
  //   expect(result, isNull);
  // });
}
