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

extension HDelCommand on HashCommands {
  /// HDEL key field [field ...]
  ///
  /// Removes the specified fields from the hash stored at [key].
  /// Specified fields that do not exist within this hash are ignored.
  /// If [key] does not exist, it is treated as an empty hash and
  /// this command returns 0.
  ///
  /// Returns the number of fields that were removed from the hash,
  /// not including specified but non existing fields.
  Future<int> hDel(String key, List<String> fields) async {
    if (fields.isEmpty) return 0;
    final cmd = <String>['HDEL', key, ...fields];
    return executeInt(cmd);
  }
}
