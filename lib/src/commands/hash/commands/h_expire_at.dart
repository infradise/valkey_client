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

extension HExpireAtCommand on HashCommands {
  /// HEXPIREAT key timestamp [NX | XX | GT | LT] FIELDS numfields field
  /// [field ...]
  ///
  /// Set an expiration for one or more [fields] in the hash stored at [key] to
  /// a specific Unix [timestamp] (seconds).
  ///
  /// Options:
  /// - [nx]: Set expiry only when the field has no expiry.
  /// - [xx]: Set expiry only when the field has an existing expiry.
  /// - [gt]: Set expiry only when the new expiry is greater than current one.
  /// - [lt]: Set expiry only when the new expiry is less than current one.
  ///
  /// Returns a list of integers:
  /// - -2 if the field does not exist.
  /// - 0 if the expiration was not set.
  /// - 1 if the expiration was set/updated.
  Future<List<int>> hExpireAt(
    String key,
    int timestamp, {
    required List<String> fields,
    bool nx = false,
    bool xx = false,
    bool gt = false,
    bool lt = false,
  }) async {
    if (fields.isEmpty) return [];

    final cmd = <String>['HEXPIREAT', key, timestamp.toString()];

    if (nx) {
      cmd.add('NX');
    } else if (xx) {
      cmd.add('XX');
    } else if (gt) {
      cmd.add('GT');
    } else if (lt) {
      cmd.add('LT');
    }

    cmd.add('FIELDS');
    cmd.add(fields.length.toString());
    cmd.addAll(fields);

    final result = await execute(cmd);

    if (result is List) {
      return result.map((e) => e as int).toList();
    }
    return [];
  }
}
