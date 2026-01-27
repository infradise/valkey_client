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

import '../json_commands.dart';
import '../utils/helpers.dart' show JsonHelpers;

extension JsonToggle on JsonCommands {
  /// JSON.TOGGLE key [path]
  ///
  /// Toggles a boolean value stored at [path].
  /// Converts `true` to `false` and `false` to `true`.
  /// Numeric 0 is treated as false, and 1 as true.
  ///
  /// [key] The key to modify.
  /// [path] The JSON path. Defaults to root (`$`).
  ///
  /// Returns the new value (0 or 1) for each path.
  /// Returns `null` if the value is not a boolean or number.
  Future<dynamic> jsonToggle({
    required String key,
    String path = r'$',
  }) async {
    final result = await execute(<String>['JSON.TOGGLE', key, path]);

    // Returns 0 (false) or 1 (true), or a list of them.
    return JsonHelpers.unwrapOne(result);
  }
}
