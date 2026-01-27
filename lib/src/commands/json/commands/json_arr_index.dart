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
import '../utils/json_helpers.dart' show JsonHelpers;

extension JsonArrIndex on JsonCommands {
  /// JSON.ARRINDEX key path value [start [stop]]
  ///
  /// Searches for the first occurrence of [value] in the array.
  ///
  /// [key] The key to search.
  /// [path] The JSON path.
  /// [value] The value to search for. It will be encoded to JSON before
  ///         searching.
  /// [start] The start index (inclusive, optional).
  /// [stop] The stop index (exclusive, optional).
  ///
  /// Returns the integer index of the value, or -1 if not found.
  ///
  /// **Note on Error Handling:**
  /// Considering Valkey's schema-less flexibility, this method returns `null`
  /// instead of throwing an exception if the target path is not an array or
  /// does not exist. This allows for a more natural flow where the caller
  /// can handle "missing target" or "invalid type" scenarios gracefully,
  /// rather than crashing the program.
  /// ```dart
  /// [Strict Check]
  /// // DO NOT USE THIS KIND OF CODE HERE. (SEE THE NOTE ABOVE)
  /// if (result == null) {
  ///   throw ValkeyException('WRONGTYPE JSON element is not an array or'
  ///       'key does not exist');
  /// }
  /// ```
  Future<dynamic> jsonArrIndex({
    required String key,
    required String path,
    required dynamic value,
    int? start,
    int? stop,
  }) async {
    final encodedValue = jsonEncode(value);
    final cmd = <String>['JSON.ARRINDEX', key, path, encodedValue];

    if (start != null) {
      cmd.add(start.toString());
      if (stop != null) {
        cmd.add(stop.toString());
      }
    }

    final result = await execute(cmd);

    // Returns null if the key doesn't exist or path is not an array.
    return JsonHelpers.unwrapOne(result); // Unwrap [int] -> int
  }
}
