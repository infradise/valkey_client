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

import '../commands.dart' show HashCommands;

extension HGetDelCommand on HashCommands {
  /// HGETDEL key FIELDS numfields field [field ...]
  ///
  /// Available since: Redis 8.0.0
  /// Time complexity: O(N) where N is the number of specified fields
  ///
  /// Get and delete the value of one or more fields of a given hash key.
  /// When the last field is deleted, the key will also be deleted.
  ///
  /// Note: This command is available in Redis 8.0.0+.
  /// Older Redis versions or current Valkey versions may return an unknown
  /// command error.
  ///
  /// Returns a list of deleted fields' values or null for fields that do not
  /// exist.
  Future<List<String?>> hGetDel(String key, List<String> fields) async {
    if (fields.isEmpty) return [];

    final cmd = <String>[
      'HGETDEL',
      key,
      'FIELDS',
      fields.length.toString(),
      ...fields
    ];

    final result = await execute(cmd);

    if (result is List) {
      return result.map((e) => e as String?).toList();
    }
    return [];
  }
}
