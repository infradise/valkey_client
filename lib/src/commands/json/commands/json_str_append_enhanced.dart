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

extension JsonStrAppendEnhanced on JsonCommands {
  /// JSON.STRAPPEND (Enhanced)
  ///
  /// Appends [value] to string values at the specified [paths].
  ///
  /// Returns a list of new string lengths, or `null` if the [key] does not
  /// exist.
  /// The list contains `null` for paths that are not strings.
  Future<List<int?>?> jsonStrAppendEnhanced({
    required String key,
    required List<String> paths,
    required String value,
  }) async {
    if (paths.isEmpty) return [];

    final encodedValue = jsonEncode(value);
    final futures = <Future<dynamic>>[];

    for (final path in paths) {
      futures.add(execute(<String>['JSON.STRAPPEND', key, path, encodedValue]));
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
