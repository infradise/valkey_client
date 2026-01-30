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

import '../commands.dart';
import '../utils/helpers.dart' show JsonHelpers;

extension JsonObjKeysEnhanced on JsonCommands {
  /// JSON.OBJKEYS (Enhanced)
  ///
  /// Returns keys of objects at the specified [paths].
  ///
  /// Returns a list of key lists (`List<List<dynamic>>`).
  Future<List<List<dynamic>?>?> jsonObjKeysEnhanced({
    required String key,
    required List<String> paths,
  }) async {
    if (paths.isEmpty) return [];

    final futures = <Future<dynamic>>[];

    for (final path in paths) {
      futures.add(execute(<String>['JSON.OBJKEYS', key, path]));
    }

    try {
      final results = await Future.wait(futures);

      return results.map<List<dynamic>?>((result) {
        final unwrapped = JsonHelpers.unwrapOne(result);
        if (unwrapped is List) return unwrapped;
        return null;
      }).toList();
    } catch (e) {
      if (e.toString().contains('NONEXISTENT')) return null;
      rethrow;
    }
  }
}
