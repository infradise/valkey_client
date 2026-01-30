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

import '../commands.dart';
import '../utils/helpers.dart' show JsonHelpers;

extension JsonArrPop on JsonCommands {
  /// JSON.ARRPOP key [path [index]]
  ///
  /// Removes and returns the element at [index] in the array.
  ///
  /// [key] The key to modify.
  /// [path] The JSON path. Defaults to root (`$`).
  /// [index] The index to pop. Defaults to -1 (last element).
  ///
  /// Returns the popped element (automatically decoded to Dart Object).
  Future<dynamic> jsonArrPop({
    required String key,
    String path = r'$',
    int? index,
  }) async {
    final cmd = <String>['JSON.ARRPOP', key, path];

    if (index != null) {
      cmd.add(index.toString());
    }

    // 1. Execute command
    // Result is usually List<String> like ['"value"'] or ['123']
    var result = await execute(cmd);

    // Use smart decoding (similar to jsonGet)
    if (result == null) return null;

    // 2. Unwrap if it's a single-element list
    result = JsonHelpers.unwrapOne(result);

    // Redis returns the popped value as a JSON string.
    // If it returns a List (path matched multiple arrays), we might need to
    // handle it,
    // but usually ARRPOP targets a specific path.
    // 3. Decode JSON string to Dart Object
    if (result is String) {
      try {
        return jsonDecode(result);
      } catch (e) {
        return result; // Fallback
      }
    }
    // If multiple paths matched, result might still be a List of strings.
    // In that case, we might want to map decode, but usually POP is specific.
    return result;
  }
}
