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

import '../commands.dart' show JsonCommands;
import '../utils/helpers.dart' show JsonHelpers;

extension JsonObjKeysCommand on JsonCommands {
  /// JSON.OBJKEYS key [path]
  ///
  /// Returns the keys in the object at [path].
  ///
  /// [key] The key to check.
  /// [path] The JSON path. Defaults to root (`$`).
  ///
  /// Returns a `List<dynamic>` containing the keys.
  /// If [path] matches multiple objects, returns a List of Lists.
  /// Returns `null` if the key or path does not exist, or the value is not
  /// an object.
  Future<dynamic> jsonObjKeys({
    required String key,
    String path = r'$',
  }) async {
    final result = await execute(<String>['JSON.OBJKEYS', key, path]);
    return JsonHelpers.unwrapOne(result);
  }
}
