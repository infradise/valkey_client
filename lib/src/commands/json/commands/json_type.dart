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

extension JsonType on JsonCommands {
  /// JSON.TYPE key [path]
  ///
  /// Reports the type of JSON value at [path].
  ///
  /// [key] The key to check.
  /// [path] The JSON path. Defaults to root (`$`).
  ///
  /// Returns the type name as a String (e.g., 'string', 'integer',
  /// 'boolean', 'array', 'object', 'null').
  /// Returns `null` if the key or path does not exist.
  Future<dynamic> jsonType({
    required String key,
    String path = r'$',
  }) async {
    final result = await execute(<String>['JSON.TYPE', key, path]);
    return JsonHelpers.unwrapOne(result);
  }
}
