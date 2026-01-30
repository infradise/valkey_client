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

import 'dart:convert' show jsonDecode, jsonEncode;

import '../commands.dart';

extension JsonSet on JsonCommands {
  /// JSON.SET key path value [NX | XX]
  ///
  /// Sets the JSON value at [path] in [key].
  ///
  /// This method is smart enough to handle both Dart Objects (Map, List)
  /// and Raw JSON Strings.
  ///
  /// If [data] is a String that looks like JSON (e.g., '{"a":1}'),
  /// it will be automatically parsed and stored as a JSON Object,
  /// preventing double-encoding issues.
  ///
  /// [key] The key to modify.
  /// [path] The JSON path (e.g., `r'$'`, `r'$.score'`). Must be a String.
  /// [data] The data to store. Can be a Map, List, num, bool, String, etc.
  /// [nx] If true, set the value only if it does not exist.
  /// [xx] If true, set the value only if it already exists.
  Future<void> jsonSet({
    required String key,
    required String path,
    required dynamic data,
    bool nx = false, // Only set if path does not exist
    bool xx = false, // Only set if path already exists
  }) async {
    dynamic payload = data;

    // [Smart Parsing Logic]
    // If the user provided a String, try to decode it first.
    // This allows users to pass raw JSON strings like '{"a": 1}'
    // without double-encoding.
    if (data is String) {
      try {
        final trimmed = data.trim();
        // Check if it looks like a JSON Object or Array
        if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
            (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
          payload = jsonDecode(data);
        }
      } catch (e) {
        // If decoding fails, treat it as a regular string value.
        // e.g., data = "Hello World" -> stored as "Hello World"
      }
    }

    // Convert the final payload to a JSON string for the command
    final jsonData = jsonEncode(payload);

    // Construct the command list as List<String> to maintain backward
    // compatibility
    final cmd = <String>['JSON.SET', key, path, jsonData];

    if (nx) cmd.add('NX');
    if (xx) cmd.add('XX');

    await execute(cmd);
  }

  /// JSON.SET key path value [NX | XX]
  ///
  /// Sets the JSON value at [path] in [key].
  ///
  /// [key] The key to modify.
  /// [path] The JSON path (e.g., `r'$'`, `r'$.score'`). Must be a String.
  /// [data] The data to store. It will be automatically serialized using
  /// [jsonEncode].
  /// [nx] If true, set the value only if it does not exist.
  /// [xx] If true, set the value only if it already exists.
  @Deprecated('Use [JsonSet] instead. This method will be removed in v3.0.0.')
  Future<void> deprecatedJsonSet({
    required String key,
    required String path,
    required dynamic data,
    bool nx = false, // Only set if path does not exist
    bool xx = false, // Only set if path already exists
  }) async {
    // Convert data to JSON string
    final jsonData = jsonEncode(data);

    // Construct the command list as List<String> to maintain backward
    // compatibility
    final cmd = <String>['JSON.SET', key, path, jsonData];

    if (nx) cmd.add('NX');
    if (xx) cmd.add('XX');

    await execute(cmd);
  }
}
