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

  // Test for commands without enhancedPaths

  test('jsonSet & jsonGet - simple array', () async {
    await client.jsonSet(key: 'json:simple', path: '.', data: '["a","b","c"]');
    final result = await client.jsonGet(key: 'json:simple', path: '.');

    // (X) expect(result, equals('["a","b","c"]')); // This is String
    expect(result, equals(['a', 'b', 'c'])); // Expected Usage
  });

  test('jsonSet & jsonGet - nested object', () async {
    await client.jsonSet(
        key: 'json:nested',
        path: '.',
        data: '{"foo":1,"bar":{"baz":[1,2,3],"qux":"val"}}');

    // (!) final result = await client.jsonGet(key: 'json:nested', path: '.');
    final result = await client.jsonGet(key: 'json:nested', path: '.')
        as Map<String, dynamic>; // Expected Usage

    // (X) expect(result, contains('"foo":1')); // This is String
    expect(result, containsPair('foo', 1)); // Expected Usage
    expect(result['foo'], equals(1)); // Expected Usage

    // (X) expect(result, contains('"baz":[1,2,3]')); // This is String
    expect(result['bar'], containsPair('baz', [1, 2, 3])); // Expected Usage
    final bar = result['bar'] as Map;
    expect(bar['baz'], equals([1, 2, 3])); // Expected Usage

    expect(bar['qux'], equals('val')); // Expected Usage
  });

  test('jsonSet & jsonGet - empty object', () async {
    await client.jsonSet(key: 'json:emptyobj', path: '.', data: '{}');
    final result = await client.jsonGet(key: 'json:emptyobj', path: '.');

    // (X) expect(result, equals('{}')); // This is String
    expect(result, equals({})); // Expected Usage
  });

  test('jsonSet & jsonGet - empty array', () async {
    await client.jsonSet(key: 'json:emptyarr', path: '.', data: '[]');
    final result = await client.jsonGet(key: 'json:emptyarr', path: '.');

    // (X) expect(result, equals('[]')); // This is String
    expect(result, equals([])); // Expected Usage
  });

  test('jsonArrAppend - normal array', () async {
    await client.jsonSet(key: 'json:arrappend', path: '.', data: '["x"]');
    final len = await client.jsonArrAppend(
        key: 'json:arrappend',
        path: '.',
        // (X) values: '"y"');
        values: ['y']);
    expect(len, equals(2));
    final result = await client.jsonGet(key: 'json:arrappend', path: '.');
    // (X) expect(result, equals('["x","y"]'));
    expect(result, equals(['x', 'y']));
  });

  test('jsonArrAppend - not an array', () async {
    await client.jsonSet(key: 'json:notarray', path: '.', data: '{"a":1}');
    try {
      await client.jsonArrAppend(
          key: 'json:notarray',
          path: '.',
          // (X) values: '"b"');
          values: ['b']);
      fail('Should throw an error');
    } catch (e) {
      expect(e, isA<ValkeyException>());
      expect((e as ValkeyException).message,
          equals('WRONGTYPE JSON element is not an array'));
    }
  });

  test('jsonArrAppend - empty array', () async {
    await client.jsonSet(key: 'json:emptyarr2', path: '.', data: '[]');
    final len = await client.jsonArrAppend(
        key: 'json:emptyarr2',
        path: '.',
        // (X) values: '"foo"');
        values: ['foo']);
    expect(len, equals(1));
  });

  test('jsonArrIndex - value exists', () async {
    await client.jsonSet(key: 'json:arridx', path: '.', data: '["a","b","c"]');
    final idx = await client.jsonArrIndex(
        // (X) value: '"b"' // This is String
        // (O) value: 'b' // Expected Usage
        key: 'json:arridx',
        path: '.',
        value: 'b',
        start: null,
        stop: null);
    expect(idx, equals(1));
  });

  test('jsonArrIndex - value not exists', () async {
    await client.jsonSet(key: 'json:arridx2', path: '.', data: '["a","b"]');
    final idx = await client.jsonArrIndex(
        key: 'json:arridx2',
        path: '.',
        // (X) value: '"z"' // This is String
        // (O) value: 'z' // Expected Usage
        value: 'z',
        start: null,
        stop: null);
    expect(idx, equals(-1));
  });

  test('jsonArrIndex - not an array', () async {
    await client.jsonSet(key: 'json:notarray2', path: '.', data: '{"a":1}');
    try {
      await client.jsonArrIndex(
          key: 'json:notarray2',
          path: '.',
          // (X) value: '"a"' // This is String
          // (O) value: 'a' // Expected Usage
          value: 'a',
          start: null,
          stop: null);
      fail('Should throw an error');
    } catch (e) {
      expect(e, isA<ValkeyException>());
      expect((e as ValkeyException).message,
          equals('WRONGTYPE JSON element is not an array'));
    }
  });

  test('jsonArrPop - normal', () async {
    await client.jsonSet(key: 'json:arrpop', path: '.', data: '["a","b","c"]');
    final popped =
        await client.jsonArrPop(key: 'json:arrpop', path: '.', index: 1);

    // (X) equals('"b"') // This is String
    // (O) equals('b') // Expected Usage
    expect(popped, equals('b'));

    final result = await client.jsonGet(key: 'json:arrpop', path: '.');
    // (X) equals('["a","c"]') // This is String
    // (O) equals(['a','c']) // Expected Usage
    expect(result, equals(['a', 'c']));
  });

  test('jsonArrPop - out of bounds but returns last element', () async {
    await client.jsonSet(key: 'json:arrpop2', path: '.', data: '["a"]');
    final popped =
        await client.jsonArrPop(key: 'json:arrpop2', path: '.', index: 5);
    // (X) equals('"a"') // This is String
    // (O) equals('a') // Expected Usage
    expect(popped, 'a');
  });

  test('jsonArrPop - empty array but returns null', () async {
    await client.jsonSet(key: 'json:emptyarr3', path: '.', data: '[]');
    final popped =
        await client.jsonArrPop(key: 'json:emptyarr3', path: '.', index: 0);
    expect(popped, isNull);
    final result = await client.jsonGet(key: 'json:emptyarr3', path: '.');
    // (X) equals('[]') // This is String
    // (O) equals([]) // Expected Usage
    expect(result, equals([]));
  });

  test('jsonArrPop - not an array', () async {
    await client.jsonSet(key: 'json:notarray3', path: '.', data: '{"a":1}');
    try {
      await client.jsonArrPop(key: 'json:notarray3', path: '.', index: 0);
      fail('Should throw an error');
    } catch (e) {
      expect(e, isA<ValkeyException>());
      expect((e as ValkeyException).message,
          equals('WRONGTYPE JSON element is not an array'));
    }
  });

  test('jsonArrLen - normal', () async {
    await client.jsonSet(key: 'json:arrlen', path: '.', data: '["a","b"]');
    final len = await client.jsonArrLen(key: 'json:arrlen', path: '.');
    expect(len, equals(2));
  });

  test('jsonArrLen - not an array', () async {
    await client.jsonSet(key: 'json:notarray4', path: '.', data: '{"a":1}');
    try {
      await client.jsonArrLen(key: 'json:notarray4', path: '.');
      fail('Should throw an error');
    } catch (e) {
      expect(e, isA<ValkeyException>());
      expect((e as ValkeyException).message,
          equals('WRONGTYPE JSON element is not an array'));
    }
  });

  test('jsonArrLen - empty array', () async {
    await client.jsonSet(key: 'json:emptyarr3', path: '.', data: '[]');
    final len = await client.jsonArrLen(key: 'json:emptyarr3', path: '.');
    expect(len, equals(0));
  });

  test('jsonArrTrim - normal', () async {
    await client.jsonSet(
        key: 'json:arrtrim', path: '.', data: '["a","b","c","d"]');
    final newLen = await client.jsonArrTrim(
        key: 'json:arrtrim', path: '.', start: 1, stop: 2);
    expect(newLen, equals(2));
    final result = await client.jsonGet(key: 'json:arrtrim', path: '.');

    // (X) equals('["b","c"]') // This is String
    // (O) equals(['b','c']) // Expected Usage
    expect(result, equals(['b', 'c']));
  });

  test('jsonArrTrim - not an array', () async {
    await client.jsonSet(key: 'json:notarray5', path: '.', data: '{"a":1}');
    try {
      await client.jsonArrTrim(
          key: 'json:notarray5', path: '.', start: 0, stop: 1);
      fail('Should throw an error');
    } catch (e) {
      expect(e, isA<ValkeyException>());
      expect((e as ValkeyException).message,
          equals('WRONGTYPE JSON element is not an array'));
    }
  });

  test('jsonClear - object', () async {
    await client.jsonSet(
        key: 'json:clearobj', path: '.', data: '{"a":1,"b":2}');
    final cleared = await client.jsonClear(key: 'json:clearobj', path: '.');
    expect(cleared, greaterThanOrEqualTo(1));
    final result = await client.jsonGet(key: 'json:clearobj', path: '.');
    // (X) expect(result, equals('{}'));
    expect(result, equals({}));
  });

  test('jsonClear - array', () async {
    await client.jsonSet(key: 'json:cleararr', path: '.', data: '["a","b"]');
    final cleared = await client.jsonClear(key: 'json:cleararr', path: '.');
    expect(cleared, greaterThanOrEqualTo(1));
    final result = await client.jsonGet(key: 'json:cleararr', path: '.');
    // (X) expect(result, equals('[]'));
    expect(result, equals([]));
  });

  test(
      'jsonClear - json string (not container) and '
      'returns json empty string (It is a bug)', () async {
    await client.jsonSet(
        key: 'json:clearnotcontainer', path: '.', data: '"foo"');
    final cleared =
        await client.jsonClear(key: 'json:clearnotcontainer', path: '.');
    final result =
        await client.jsonGet(key: 'json:clearnotcontainer', path: '.');
    expect(cleared, equals(1));
    // (X) expect(result, equals('""'));
    expect(result, equals(''));
  });

  test(
      'jsonClear - json empty string (not container) and '
      'returns empty json string (It is a bug)', () async {
    await client.jsonSet(
        key: 'json:clearnotcontainer', path: '.', data: '"foo"');
    final cleared =
        await client.jsonClear(key: 'json:clearnotcontainer', path: '.');
    final result =
        await client.jsonGet(key: 'json:clearnotcontainer', path: '.');
    expect(cleared, equals(1));
    // expect(result, equals('""'));
    expect(result, equals(''));
  });

  test('jsonDel - normal', () async {
    await client.jsonSet(key: 'json:del', path: '.', data: '{"a":1,"b":2}');
    final deleted = await client.jsonDel(key: 'json:del', path: '.a');
    expect(deleted, equals(1));
    final result = await client.jsonGet(key: 'json:del', path: '.');

    // (X) expect(result, contains('"b":2')); // This is String
    expect(result, containsPair('b', 2)); // Expected Usage

    // (X) expect(result, isNot(contains('"a":1'))); // This is String
    expect(result, isNot(containsPair('a', 1))); // Expected Usage
  });

  test('jsonDel - non-existent path', () async {
    await client.jsonSet(key: 'json:del2', path: '.', data: '{"a":1}');
    final deletedCount = await client.jsonDel(key: 'json:del2', path: '.b');
    expect(deletedCount, equals(0));
  });

  test('jsonSet - NX/XX options', () async {
    await client.jsonSet(key: 'json:nx', path: '.', data: '{"a":1}');

    // Should not overwrite with NX
    await client.jsonSet(key: 'json:nx', path: '.', data: '{"a":2}', nx: true);
    final result = await client.jsonGet(key: 'json:nx', path: '.');
    // (X) expect(result, equals('{"a":1}')); // This is String
    expect(result, equals({'a': 1})); // Expected Usage
    expect(result, containsPair('a', 1)); // Expected Usage

    // Should overwrite with XX
    await client.jsonSet(key: 'json:nx', path: '.', data: '{"a":3}', xx: true);
    final result2 = await client.jsonGet(key: 'json:nx', path: '.');
    // (X) expect(result2, equals('{"a":3}')); // This is String
    expect(result2, equals({'a': 3})); // Expected Usage
    expect(result2, containsPair('a', 3)); // Expected Usage
  });

  test('jsonMGet - multiple keys', () async {
    await client.jsonSet(key: 'json:mget1', path: '.', data: '{"a":1}');
    await client.jsonSet(key: 'json:mget2', path: '.', data: '{"a":2}');
    final vals =
        await client.jsonMGet(keys: ['json:mget1', 'json:mget2'], path: '.a');
    expect(vals, isA<List>());
    expect(vals.length, equals(2));
    // (X) expect(vals[0], equals('1'));
    expect(vals[0], equals(1));
    // (X) expect(vals[1], equals('2'));
    expect(vals[1], equals(2));
  });

  test('jsonMGet - some keys missing', () async {
    await client.jsonSet(key: 'json:mget3', path: '.', data: '{"a":1}');
    final vals =
        await client.jsonMGet(keys: ['json:mget3', 'json:missing'], path: '.a');
    expect(vals.length, equals(2));
    // (X) expect(vals[0], equals('1'));
    expect(vals[0], equals(1));
    expect(vals[1], isNull);
  });

  test('jsonMSet - multiple paths', () async {
    // It is same with jsonSet when Mset just set one key-path-value
    await client.jsonMSet(
      entries: [
        // (X) (key: 'json:mset', path: '.', value: '{"a":999,"b":[999]}'),
        const JsonMSetEntry(key: 'json:mset', path: '.', value: {
          'a': 999,
          'b': [999]
        }),
      ],
    );

    final result1 = await client.jsonGet(key: 'json:mset', path: '.');
    await client.jsonMSet(
      entries: [
        // (X) (key: 'json:mset', path: '.a', value: '0'),
        const JsonMSetEntry(key: 'json:mset', path: '.a', value: 0),
        // (X) (key: 'json:mset', path: '.b', value: '0'),
        const JsonMSetEntry(key: 'json:mset', path: '.b', value: 0),
      ],
    );

    final result2 = await client.jsonGet(key: 'json:mset', path: '.');
    await client.jsonMSet(
      entries: [
        // (X) (key: 'json:mset', path: '.b', value: 'false'),
        const JsonMSetEntry(key: 'json:mset', path: '.b', value: false),
        // (X) (key: 'json:mset', path: '.c', value: 'true'),
        const JsonMSetEntry(key: 'json:mset', path: '.c', value: true),
        // (X) (key: 'json:mset', path: '.d', value: 'null'),
        const JsonMSetEntry(key: 'json:mset', path: '.d', value: null),
      ],
    );
    final result3 = await client.jsonGet(key: 'json:mset', path: '.');

    // It is same with jsonSet when Mset just set one key-path-value
    await client.jsonMSet(
      entries: [
        // (X) (key: 'json:mset', path: '.', value: '{"z":1,"y":2}'),
        const JsonMSetEntry(
            key: 'json:mset', path: '.', value: {'z': 1, 'y': 2}),
      ],
    );
    final result4 = await client.jsonGet(key: 'json:mset', path: '.');
    // (X) expect(result1, equals('{"a":999,"b":[999]}'));
    expect(
        result1,
        equals({
          'a': 999,
          'b': [999]
        }));
    // (X) expect(result2, equals('{"a":0,"b":0}'));
    expect(result2, equals({'a': 0, 'b': 0}));
    // (X) expect(result3, equals('{"a":0,"b":false,"c":true,"d":null}'));
    expect(result3, equals({'a': 0, 'b': false, 'c': true, 'd': null}));
    // (X) expect(result4, equals('{"z":1,"y":2}'));
    expect(result4, equals({'z': 1, 'y': 2}));
  });

  test('jsonNumIncrBy - normal', () async {
    await client.jsonSet(
        key: 'json:numincr',
        path: '.',
        // (X) data: '{"n":10}');
        data: {'n': 10}); // Expected usage
    final newVal =
        await client.jsonNumIncrBy(key: 'json:numincr', path: '.n', value: 5);
    // (X) expect(newVal, contains('15'));
    expect([newVal], contains(15)); // Expected usage
    expect(newVal, equals(15)); // Expected usage
  });

  test('jsonNumIncrBy - not a number', () async {
    await client.jsonSet(
        key: 'json:numincr2',
        path: '.',
        // (X) data: '{"n":"foo"}');
        data: {'n': 'foo'}); // Expected usage

    try {
      await client.jsonNumIncrBy(key: 'json:numincr2', path: '.n', value: 1);
      fail('Should throw');
    } catch (e) {
      expect(e, isA<Exception>());
      // rethrow; // Uncomment to see the exception
    }
  });

  test('jsonNumMultBy - normal', () async {
    await client.jsonSet(key: 'json:nummult', path: '.', data: '{"n":2}');
    final newVal =
        await client.jsonNumMultBy(key: 'json:nummult', path: '.n', value: 3);
    // (X) expect(newVal, contains('6'));
    expect([newVal], contains(6)); // Expected usage
    expect(newVal, equals(6)); // Expected usage
  });

  test('jsonObjKeys - object', () async {
    await client.jsonSet(
        key: 'json:objkeys',
        path: '.',
        // (X) data: '{"a":1,"b":2}');
        data: {'a': 1, 'b': 2}); // Expected usage
    final keys = await client.jsonObjKeys(key: 'json:objkeys', path: '.');
    expect(keys, containsAll(['a', 'b']));
  });

  test('jsonObjkeys - not an object', () async {
    await client.jsonSet(
        key: 'json:objkeys2',
        path: '.',
        // (X) data: '["a","b"]');
        data: ['a', 'b']); // Expected usage
    final keys = await client.jsonObjKeys(key: 'json:objkeys2', path: '.a');
    expect(keys, isNull);
  });

  test('jsonStrAppend & jsonStrlen', () async {
    await client.jsonSet(
        key: 'json:str',
        path: '.',
        // (X) data: '"foo"'); // 5
        data: 'foo'); // 3
    final newLen = await client.jsonStrAppend(
        key: 'json:str',
        path: '.',
        // (X) value: '"bar"'); // 5
        value: 'bar'); // 3

    expect(newLen, greaterThan(3));
    final strlen = await client.jsonStrLen(key: 'json:str', path: '.');
    expect(strlen, equals(newLen));

    // Expected usage (check the actual value of newLen)
    expect(strlen, equals(6));
  });

  test('jsonStrAppend - not a string', () async {
    await client.jsonSet(key: 'json:str2', path: '.', data: '[1,2,3]');
    try {
      await client.jsonStrAppend(key: 'json:str2', path: '.', value: '"baz"');
      fail('Should throw');
    } catch (e) {
      expect(e, isA<ValkeyException>());
      expect((e as ValkeyException).message,
          equals('WRONGTYPE JSON element is not a string'));
    }
  });
}
