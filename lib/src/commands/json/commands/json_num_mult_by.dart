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

import 'dart:convert' show jsonDecode;

import '../commands.dart';
import '../utils/helpers.dart' show JsonHelpers;

extension JsonNumMultBy on JsonCommands {
  /// JSON.NUMMULTBY key path value
  ///
  /// Multiplies the numeric value at [path] by [value].
  ///
  /// [key] The key to modify.
  /// [path] The JSON path.
  /// [value] The number to multiply by (can be int or double).
  ///
  /// Returns the new value.
  Future<dynamic> jsonNumMultBy({
    required String key,
    required String path,
    required num value,
  }) async {
    final result = await execute(<String>[
      'JSON.NUMMULTBY',
      key,
      path,
      value.toString(),
    ]);

    final unwrapped = JsonHelpers.unwrapOne(result);

    if (unwrapped is String) {
      return jsonDecode(unwrapped);
    }
    return unwrapped;
  }
}
