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

extension HGetAllCommand on HashCommands {
  /// HGETALL key
  ///
  /// Returns all fields and values of the hash stored at [key].
  /// In the returned value, every field name is followed by its value, so
  /// the length of the reply is twice the size of the hash.
  ///
  /// Returns a [Map] of fields and their values. Returns an empty map if
  /// [key] does not exist.
  Future<Map<String, String>> hGetAll(String key) async {
    final cmd = <String>['HGETALL', key];
    final result = await execute(cmd);

    if (result is List) {
      final map = <String, String>{};
      for (var i = 0; i < result.length; i += 2) {
        final field = result[i] as String;
        final value = result[i + 1] as String;
        map[field] = value;
      }
      return map;
    }
    return {};
  }
}
