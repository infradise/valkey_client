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

extension HPExpireTimeCommand on HashCommands {
  /// HPEXPIRETIME key FIELDS numfields field [field ...]
  ///
  /// Returns the absolute Unix timestamp (in milliseconds) at which the given
  /// [fields] will expire.
  ///
  /// Returns a list of integers for each field:
  /// - -1 if the field exists but has no associated expiration.
  /// - -2 if the field does not exist.
  /// - The Unix timestamp (ms) for the field's expiration.
  Future<List<int>> hPExpireTime(String key, List<String> fields) async {
    if (fields.isEmpty) return [];

    final cmd = <String>[
      'HPEXPIRETIME',
      key,
      'FIELDS',
      fields.length.toString(),
      ...fields
    ];

    final result = await execute(cmd);

    if (result is List) {
      return result.map((e) => e as int).toList();
    }
    return [];
  }
}
