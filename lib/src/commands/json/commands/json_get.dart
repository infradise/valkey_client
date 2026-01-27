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

import '../json_commands.dart';

extension JsonGet on JsonCommands {
  /// JSON.GET key [path ...]
  ///
  /// Return the value at [path] in JSON format.
  /// The returned JSON string is automatically decoded into a Dart Object.
  ///
  /// [key] The key to retrieve.
  /// [path] The JSON path. Defaults to root (`$`).
  ///
  /// Note on Path Behavior:
  /// - If [path] is `$` (default), the command is sent as `JSON.GET key`.
  ///   This returns the single raw value (e.g., Map or List).
  /// - If [path] is specific (e.g., `$.name`), the command is sent as
  ///     `JSON.GET key $.name`.
  ///   Standard JSONPath queries usually return a List of matches
  ///     (e.g., `[value]`).
  Future<dynamic> jsonGet({
    required String key,
    String path = r'$',
  }) async {
    final List<String> cmd;

    // [Optimization]
    // If the path is the root ('$'), we omit it in the command.
    // 'JSON.GET key' returns the object directly (e.g., {...}).
    // 'JSON.GET key $' returns a list containing the object (e.g., [{...}]).
    // To be user-friendly, we prefer the direct object for the root query.
    if (path == r'$') {
      cmd = <String>['JSON.GET', key];
    } else {
      cmd = <String>['JSON.GET', key, path];
    }

    // Send command
    final result = await execute(cmd);

    if (result == null) return null;

    // Decode the response string back to a Dart Object (Map, List, etc.)
    return jsonDecode(result.toString());
  }

  /// JSON.GET key [path ...]
  ///
  /// Return the value at [path] in JSON format.
  /// The returned JSON string is automatically decoded into a Dart Object.
  ///
  /// [key] The key to retrieve.
  /// [path] The JSON path. Defaults to root (`$`).
  @Deprecated('Use [JsonGet] instead. This method will be removed in v3.0.0.')
  Future<dynamic> deprecatedJsonGet({
    required String key,
    String path = r'$',
  }) async {
    // Send command
    final result = await execute(<String>['JSON.GET', key, path]);

    if (result == null) return null;

    // Decode the response string back to a Dart Object (Map, List, etc.)
    return jsonDecode(result.toString());
  }
}
