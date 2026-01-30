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

extension HMGetCommand on HashCommands {
  /// HMGET key field [field ...]
  ///
  /// Returns the values associated with the specified [fields] in the hash
  /// stored at [key].
  /// For every field that does not exist in the hash, a null value is returned.
  /// Because non-existing keys are treated as empty hashes, running HMGET
  /// against a non-existing key will return a list of null values.
  ///
  /// Returns a list of values associated with the given fields, in the same
  /// order as they are requested.
  Future<List<String?>> hMGet(String key, List<String> fields) async {
    if (fields.isEmpty) return [];

    final cmd = <String>['HMGET', key, ...fields];
    final result = await execute(cmd);

    if (result is List) {
      return result.map((e) => e as String?).toList();
    }
    return [];
  }
}
