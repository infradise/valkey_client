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

extension JsonArrTrim on JsonCommands {
  /// JSON.ARRTRIM key path start stop
  ///
  /// Trims the array so that it contains only the specified inclusive range of
  /// elements.
  ///
  /// [key] The key to modify.
  /// [path] The JSON path.
  /// [start] The start index (inclusive).
  /// [stop] The stop index (inclusive).
  ///
  /// Returns the integer length of the new array.
  Future<dynamic> jsonArrTrim({
    required String key,
    required String path,
    required int start,
    required int stop,
  }) async {
    final result = await execute(
        <String>['JSON.ARRTRIM', key, path, start.toString(), stop.toString()]);
    return JsonHelpers.unwrapOne(result); // Unwrap [int] -> int
  }
}
