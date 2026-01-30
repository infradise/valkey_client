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

extension HSetExCommand on HashCommands {
  /// HSETEX key seconds field value
  ///
  /// Sets the [value] of a [field] in the hash stored at [key] and sets
  /// its expiration to [seconds].
  ///
  /// Note: This is a composite command. It executes `HSET` followed by
  /// `HEXPIRE`.
  /// It sets the expiration on the specific field (Valkey feature), not
  /// the key.
  ///
  /// Returns `true` if the operation was successful.
  Future<bool> hSetEx(
    String key,
    int seconds,
    String field,
    String value,
  ) async {
    // 1. Set the field value
    await execute(<String>['HSET', key, field, value]);

    // 2. Set the expiration on the field
    // HEXPIRE key seconds FIELDS 1 field
    final expireResult = await execute(
        <String>['HEXPIRE', key, seconds.toString(), 'FIELDS', '1', field]);

    // HEXPIRE returns an array of integers (1 for success per field)
    if (expireResult is List && expireResult.isNotEmpty) {
      return expireResult.first == 1;
    }

    return false;
  }
}
