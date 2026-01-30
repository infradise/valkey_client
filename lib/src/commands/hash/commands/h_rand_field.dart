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

import '../commands.dart' show HashCommands;

extension HRandFieldCommand on HashCommands {
  /// HRANDFIELD key [count [WITHVALUES]]
  ///
  /// Returns one or more random fields from the hash stored at [key].
  ///
  /// - If [count] is not provided, returns a single random field as `String?`.
  /// - If [count] is provided:
  ///   - If [withValues] is `false` (default), returns `List<String>` of
  /// fields.
  ///   - If [withValues] is `true`, returns `Map<String, String>` of fields
  /// and their values.
  ///
  /// Note: The return type depends on the arguments provided.
  ///
  /// Returns:
  /// - `String?` (Single field name, or null if key is empty/missing)
  /// - `List<String>` (List of field names)
  /// - `Map<String, String>` (Map of field-value pairs)
  Future<dynamic> hRandField(String key,
      {int? count, bool withValues = false}) async {
    final cmd = <String>['HRANDFIELD', key];

    if (count != null) {
      cmd.add(count.toString());
      if (withValues) {
        cmd.add('WITHVALUES');
      }
    }

    final result = await execute(cmd);

    if (result == null) return null;

    // Case 1: Single field requested (no count)
    if (count == null) {
      return result as String?;
    }

    // Case 2: Count provided
    if (result is List) {
      // Case 2a: WITHVALUES => Returns [field, value, field, value, ...]
      if (withValues) {
        final map = <String, String>{};
        for (var i = 0; i < result.length; i += 2) {
          final field = result[i] as String;
          final value = result[i + 1] as String;
          map[field] = value;
        }
        return map;
      }
      // Case 2b: Fields only => Returns [field, field, ...]
      return result.map((e) => e.toString()).toList();
    }

    return result;
  }
}
