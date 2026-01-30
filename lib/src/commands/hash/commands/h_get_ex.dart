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

extension HGetExCommand on HashCommands {
  /// HGETEX key field [EX seconds | PX milliseconds | EXAT timestamp |
  /// PXAT milliseconds-timestamp | PERSIST]
  ///
  /// Get the value of [field] in the hash at [key] and optionally set
  /// its expiration.
  ///
  /// Options (only one can be used):
  /// - [ex]: Set expiration in seconds.
  /// - [px]: Set expiration in milliseconds.
  /// - [exAt]: Set expiration to Unix timestamp (seconds).
  /// - [pxAt]: Set expiration to Unix timestamp (milliseconds).
  /// - [persist]: Remove the expiration from the field.
  ///
  /// Returns the value of the field, or `null` if the field does not exist.
  Future<String?> hGetEx(
    String key,
    String field, {
    int? ex,
    int? px,
    int? exAt,
    int? pxAt,
    bool persist = false,
  }) async {
    final cmd = <String>['HGETEX', key, field];

    if (ex != null) {
      cmd.add('EX');
      cmd.add(ex.toString());
    } else if (px != null) {
      cmd.add('PX');
      cmd.add(px.toString());
    } else if (exAt != null) {
      cmd.add('EXAT');
      cmd.add(exAt.toString());
    } else if (pxAt != null) {
      cmd.add('PXAT');
      cmd.add(pxAt.toString());
    } else if (persist) {
      cmd.add('PERSIST');
    }

    final result = await execute(cmd);
    return result as String?;
  }
}
