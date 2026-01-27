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
import '../utils/helpers.dart' show JsonHelpers;

extension JsonArrPopEnhanced on JsonCommands {
  /// JSON.ARRPOP (Enhanced)
  ///
  /// Removes and returns elements from arrays at the specified [paths].
  ///
  /// Returns a list of popped JSON values (as strings/objects), or `null` if the [key] does not exist.
  /// The list contains `null` for paths that are not arrays.
  /// Returns `null` for non-array paths.
  Future<List<dynamic>?> jsonArrPopEnhanced({
    required String key,
    required List<String> paths,
    int? index,
  }) async {
    if (paths.isEmpty) return [];

    final futures = <Future<dynamic>>[];

    for (final path in paths) {
      final cmd = <String>['JSON.ARRPOP', key, path];
      if (index != null) {
        cmd.add(index.toString());
      }
      futures.add(execute(cmd));
    }

    try {
      final results = await Future.wait(futures);

      return results.map((result) {
        // Unwrap -> Decode if string
        final unwrapped = JsonHelpers.unwrapOne(result);
        // JSON.ARRPOP returns the popped value as a JSON string (Bulk String).
        // We try to decode it to a Dart object for convenience.
        if (unwrapped is String) {
          try {
            return jsonDecode(unwrapped);
          } catch (_) {
            return unwrapped;
          }
        }
        return unwrapped;
      }).toList();
    } catch (e) {
      if (e.toString().contains('NONEXISTENT')) return null;
      rethrow;
    }
  }
}
