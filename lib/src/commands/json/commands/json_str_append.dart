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

import 'dart:convert' show jsonEncode;

import '../json_commands.dart';
import '../utils/helpers.dart' show JsonHelpers;

extension JsonStrAppend on JsonCommands {
  /// JSON.STRAPPEND key [path] value
  ///
  /// Appends the string [value] to the JSON string at [path].
  ///
  /// [key] The key to modify.
  /// [path] The JSON path. Defaults to root (`$`).
  /// [value] The string to append.
  ///
  /// Returns the integer length of the new string.
  /// Throws an error (or returns null depending on server) if the target is
  /// not a string.
  Future<dynamic> jsonStrAppend({
    required String key,
    String path = r'$',
    required String value,
  }) async {
    // The value must be a JSON string, so we encode the raw string.
    // e.g. input "foo" -> sends "\"foo\""
    final encodedValue = jsonEncode(value);

    final result =
        await execute(<String>['JSON.STRAPPEND', key, path, encodedValue]);
    return JsonHelpers.unwrapOne(result);
  }
}
