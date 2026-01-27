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

extension JsonArrInsertEnhanced on JsonCommands {
  /// JSON.ARRINSERT (Enhanced)
  ///
  /// Inserts [values] into arrays at the specified [paths] at [index].
  ///
  /// Returns a list of new array lengths, or `null` if the [key] does not
  /// exist.
  /// The list contains `null` for paths that are not arrays.
  Future<List<int?>?> jsonArrInsertEnhanced({
    required String key,
    required List<String> paths,
    required int index,
    required List<dynamic> values,
  }) async {
    if (paths.isEmpty) return [];

    final encodedValues = values.map(jsonEncode).toList();
    final futures = <Future<dynamic>>[];

    for (final path in paths) {
      final cmd = <String>[
        'JSON.ARRINSERT',
        key,
        path,
        index.toString(),
        ...encodedValues
      ];
      futures.add(execute(cmd));
    }

    try {
      // Execute all commands in parallel
      final results = await Future.wait(futures);

      return results.map<int?>((result) {
        final unwrapped = JsonHelpers.unwrapOne(result);
        if (unwrapped is int) return unwrapped;
        return null;
      }).toList();
    } catch (e) {
      // [Graceful Handling]
      // If the key does not exist (NONEXISTENT), return null instead of
      // throwing an exception.
      // This allows the caller to handle the "missing key" scenario gracefully.
      if (e.toString().contains('NONEXISTENT')) {
        return null;
      }
      // Rethrow other errors (e.g., syntax errors, connection issues)
      rethrow;
    }
  }
}
