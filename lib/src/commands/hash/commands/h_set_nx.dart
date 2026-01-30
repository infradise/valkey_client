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

extension HSetNxCommand on HashCommands {
  /// HSETNX key field value
  ///
  /// Sets [field] in the hash stored at [key] to [value], only if [field] does
  /// not yet exist.
  /// If [key] does not exist, a new key holding a hash is created.
  /// If [field] already exists, this operation has no effect.
  ///
  /// Returns `true` if the field was set, `false` if the field already existed.
  Future<bool> hSetNx(String key, String field, String value) async {
    final cmd = <String>['HSETNX', key, field, value];
    final result = await executeInt(cmd);
    return result == 1;
  }
}
