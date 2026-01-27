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

import 'dart:convert' show jsonDecode;

import '../json_commands.dart';

extension JsonMGet on JsonCommands {
  /// JSON.MGET key [key ...] path
  ///
  /// Returns the values at [path] from multiple [keys].
  ///
  /// [keys] A list of keys to retrieve.
  /// [path] The JSON path.
  ///
  /// Returns a List of dynamic values. Each item is decoded from JSON.
  /// If a key does not exist, the corresponding item will be null.
  Future<List<dynamic>> jsonMGet({
    required List<String> keys,
    required String path,
  }) async {
    if (keys.isEmpty) {
      throw ArgumentError('The list of keys cannot be empty.');
    }

    // Command format: JSON.MGET key1 key2 ... path
    final cmd = <String>['JSON.MGET', ...keys, path];

    final result = await execute(cmd);

    if (result is List) {
      // The result is a list of JSON strings (or nulls).
      // We need to decode each string.
      return result.map((item) {
        if (item == null) return null;
        try {
          return jsonDecode(item.toString());
        } catch (e) {
          // Fallback if parsing fails
          return item;
        }
      }).toList();
    }

    return [];
  }
}
