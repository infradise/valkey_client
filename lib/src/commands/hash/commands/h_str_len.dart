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

extension HStrLenCommand on HashCommands {
  /// HSTRLEN key field
  ///
  /// Returns the string length of the value associated with [field] in the hash
  /// stored at [key].
  /// If the [key] or the [field] do not exist, 0 is returned.
  ///
  /// Returns the string length of the value.
  Future<int> hStrLen(String key, String field) async {
    final cmd = <String>['HSTRLEN', key, field];
    return executeInt(cmd);
  }
}
