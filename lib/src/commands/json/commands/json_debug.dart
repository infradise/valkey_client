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
import '../utils/json_helpers.dart' show JsonHelpers;

extension JsonDebug on JsonCommands {
  /// JSON.DEBUG MEMORY key [path]
  ///
  /// Reports the memory usage in bytes of a value.
  /// Currently, this method primarily supports the 'MEMORY' subcommand.
  ///
  /// [key] The key to check.
  /// [path] The JSON path. Defaults to root (`$`).
  ///
  /// Returns the memory usage in bytes (integer).
  /// Returns a List of integers if path matches multiple values.
  Future<dynamic> jsonDebug({
    required String key,
    String path = r'$',
  }) async {
    // We default to the 'MEMORY' subcommand as it is the standard use case.
    final result = await execute(<String>['JSON.DEBUG', 'MEMORY', key, path]);
    return JsonHelpers.unwrapOne(result);
  }
}
