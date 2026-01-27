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

extension JsonMSet on JsonCommands {
  /// JSON.MSET key path value [key path value ...]
  ///
  /// Sets multiple JSON values at once.
  ///
  /// [entries] A list of [JsonMSetEntry] objects containing key, path, and
  /// value.
  ///
  /// Example:
  /// ```dart
  /// await client.jsonMset(entries: [
  ///   JsonMsetEntry(key: 'user:1', path: '$.name', value: 'Alice'),
  ///   JsonMsetEntry(key: 'user:2', path: '$.name', value: 'Bob'),
  /// ]);
  /// ```
  Future<void> jsonMSet({
    required List<JsonMSetEntry> entries,
  }) async {
    if (entries.isEmpty) return;

    final cmd = <String>['JSON.MSET'];

    for (final entry in entries) {
      cmd.add(entry.key);
      cmd.add(entry.path);
      cmd.add(jsonEncode(entry.value));
    }

    await execute(cmd);
  }
}
