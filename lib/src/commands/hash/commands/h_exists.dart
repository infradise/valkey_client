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

extension HExistsCommand on HashCommands {
  /// HEXISTS key field
  ///
  /// Returns if [field] is an existing field in the hash stored at [key].
  ///
  /// Returns `true` if the hash contains [field], `false` if the hash
  /// does not contain [field], or [key] does not exist.
  Future<bool> hExists(String key, String field) async {
    final cmd = <String>['HEXISTS', key, field];
    final result = await executeInt(cmd);
    return result == 1;
  }
}
