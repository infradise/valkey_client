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

import '../json_commands.dart' show JsonCommands;
import '../utils/json_helpers.dart';

extension JsonArrAppendEnhanced on JsonCommands {
  /// JSON.ARRAPPEND (Enhanced)
  ///
  /// Appends [value] to arrays at the specified [paths].
  ///
  /// [key] The key to modify.
  /// [paths] A list of JSON paths to apply the operation to.
  /// [value] The value to append.
  ///
  /// Returns a list of new array lengths, or `null` if the [key] does not
  /// exist.
  /// The list contains `null` for paths that are not arrays.
  /// Returns `null` for a specific path if it does not exist or
  /// is not an array.
  Future<List<int?>?> jsonArrAppendEnhanced({
    required String key,
    required List<String> paths,
    required dynamic value,
  }) async {
    // Return null immediately if no paths provided, similar to original logic
    if (paths.isEmpty) return [];

    final encodedValue = jsonEncode(value);
    final futures = <Future<dynamic>>[];

    for (final path in paths) {
      futures.add(execute(<String>['JSON.ARRAPPEND', key, path, encodedValue]));
    }

    try {
      final results = await Future.wait(futures);

      return results.map<int?>((result) {
        // JSON.ARRAPPEND usually returns an integer (single match) or list of
        // integers (multi match).
        // We unwrap single-element lists to keep the return type simple.
        final unwrapped = JsonHelpers.unwrapOne(result);
        if (unwrapped is int) return unwrapped;
        return null;
      }).toList();
    } catch (e) {
      if (e.toString().contains('NONEXISTENT')) return null;
      rethrow;
    }
  }
}
