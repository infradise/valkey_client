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

import 'dart:convert' show jsonEncode;

import '../json_commands.dart' show JsonCommands;
import '../utils/json_helpers.dart';

extension JsonArrAppend on JsonCommands {
  /// JSON.ARRAPPEND key [path] value [value ...]
  ///
  /// Appends the [values] to the JSON array at [path].
  ///
  /// [key] The key to modify.
  /// [path] The JSON path. Defaults to root (`$`).
  /// [values] A list of values to append. Each item in the list will be
  /// encoded individually.
  ///
  /// Returns the integer length of the new array, or a list of lengths if
  /// path matches multiple arrays.
  Future<dynamic> jsonArrAppend({
    required String key,
    String path = r'$',
    required List<dynamic> values,
  }) async {
    final cmd = <String>['JSON.ARRAPPEND', key, path];

    // Encode each value in the list to a JSON string
    for (final val in values) {
      cmd.add(jsonEncode(val));
    }

    final result = await execute(cmd);
    return JsonHelpers.unwrapOne(result); // Unwrap [int] -> int
  }
}
