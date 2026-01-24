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

  test('jsonArrIndex - not an array (and array test))', () async {
    await client.jsonSet(key: 'json:notarray2', path: '.', data: '{"a":1}');
    expect(() async {
      await client.jsonArrIndex(key: 'json:notarray2', path: '.', value: 'a');
    }, throwsA(isA<ValkeyException>()));

    await client.jsonSet(key: 'json:arr', path: '.', data: '["a","b","c"]');
    final idx1 =
        await client.jsonArrIndex(key: 'json:arr', path: '.', value: 'b');
    expect(idx1, equals(1));

    final idx2 =
        await client.jsonArrIndex(key: 'json:arr', path: '.', value: 'x');
    expect(idx2, equals(-1));
  });

  test('jsonArrIndex - not an array (returns null)', () async {
    await client.jsonSet(key: 'json:notarray2', path: '.', data: '{"a":1}');
    try {
      final result = await client.jsonArrIndex(
          key: 'json:notarray2', path: '.', value: 'a');
      expect(result, isNull);
    } catch (e) {
      expect(e, isA<ValkeyException>());
      expect((e as ValkeyException).message,
          equals('WRONGTYPE JSON element is not an array'));
    }
  });
}
