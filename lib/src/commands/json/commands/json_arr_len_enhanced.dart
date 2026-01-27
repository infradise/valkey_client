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

extension JsonArrLenEnhanced on JsonCommands {
  /// JSON.ARRLEN (Enhanced)
  ///
  /// Returns lengths of arrays at the specified [paths].
  ///
  /// Returns a list of lengths, or `null` if the [key] does not exist.
  /// The list contains `null` for paths that are not arrays.
  ///
  /// * About null return
  /// If true, return `null` when there is no useful data (e.g., key
  /// does not exist or all requested paths are missing / not arrays).
  /// If false (default), return a `List<int?>` with one entry per
  /// requested path; entries for missing or non-array paths are `null`
  /// (for example, '[ null ]', i.e., a list containing a single null element)
  /// When `paths` is empty the method returns an empty list `[]`.
  Future<List<int?>?> jsonArrLenEnhanced({
    required String key,
    required List<String> paths,
  }) async {
    if (paths.isEmpty) return [];

    final futures = <Future<dynamic>>[];

    for (final path in paths) {
      futures.add(execute(<String>['JSON.ARRLEN', key, path]));
    }

    try {
      final results = await Future.wait(futures);

      return results.map<int?>((result) {
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
