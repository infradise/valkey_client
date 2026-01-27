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

import '../json_commands.dart';
import '../utils/helpers.dart' show JsonHelpers;

extension JsonArrInsert on JsonCommands {
  /// JSON.ARRINSERT key path index value [value ...]
  ///
  /// Inserts the [values] into the array at [index].
  ///
  /// [key] The key to modify.
  /// [path] The JSON path.
  /// [index] The index to insert at.
  /// [values] A list of values to insert.
  ///
  /// Returns the integer length of the new array.
  Future<dynamic> jsonArrInsert({
    required String key,
    required String path,
    required int index,
    required List<dynamic> values,
  }) async {
    final cmd = <String>['JSON.ARRINSERT', key, path, index.toString()];

    for (final val in values) {
      cmd.add(jsonEncode(val));
    }

    final result = await execute(cmd);
    return JsonHelpers.unwrapOne(result); // Unwrap [int] -> int
  }
}
