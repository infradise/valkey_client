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

import '../commands.dart' show JsonCommands;

extension JsonMerge on JsonCommands {
  /// JSON.MERGE key path value
  ///
  /// Merges a given JSON value into the existing JSON value at path.
  ///
  /// [key] The key to modify.
  /// [path] The JSON path.
  /// [data] The data to merge.
  ///
  /// Note1: This command is available ONLY in Redis (due to RSAL license).
  /// Attempting to use this on a Valkey server will throw an error
  /// unless [allowRedisOnlyJsonMerge] is explicitly set to true
  /// (though Valkey server will still reject it).
  ///
  /// Note2: JSON.MERGE is implemented for Redis compatibility only.
  /// It should not be called when connected to a Valkey server.
  Future<void> jsonMerge({
    required String key,
    required String path,
    required dynamic data,
  }) async {
    /// Check if the server is Redis
    ///
    /// Alternatively, isValkeyServer() can be used for DX improvements.
    /// ```dart
    /// final isValkey = await isValkeyServer();
    /// ```
    final isRedis = await isRedisServer();

    // If it's not Redis (i.e., Valkey) and the override flag is off,
    // block the request.
    if (!isRedis) {
      if (!allowRedisOnlyJsonMerge) {
        throw UnsupportedError('jsonMerge is not supported on Valkey.'
            //  'JSON.MERGE is not supported in Valkey '
            //  'due to licensing issues (RSAL). '
            //  'It is strictly a Redis-only command until Valkey supports it.'
            );
      }
      // logger.warning('jsonMerge is Redis-only; skipped on Valkey.');
    }

    setAllowRedisOnlyJsonMerge = false; // Here. Always (should be) false.

    final jsonData = jsonEncode(data);
    await execute(<String>['JSON.MERGE', key, path, jsonData]);
  }
}
