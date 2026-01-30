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

extension HScanCommand on HashCommands {
  /// HSCAN key cursor [MATCH pattern] [COUNT count]
  ///
  /// Iterates over fields and values of the hash stored at [key].
  ///
  /// [cursor]: The cursor to start the scan from. Use '0' to start a new scan.
  /// [match]: Globally glob-style pattern to filter fields.
  /// [count]: Hint for the amount of work to be done per command.
  ///
  /// Returns a list containing two elements:
  /// 1. The next cursor (String).
  /// 2. A list of fields and values (`List<String>`).
  Future<List<dynamic>> hScan(
    String key,
    String cursor, {
    String? match,
    int? count,
  }) async {
    final cmd = <String>['HSCAN', key, cursor];

    if (match != null) {
      cmd.add('MATCH');
      cmd.add(match);
    }

    if (count != null) {
      cmd.add('COUNT');
      cmd.add(count.toString());
    }

    final result = await execute(cmd);

    if (result is List && result.length == 2) {
      return result;
    }
    throw Exception('Unexpected return format for HSCAN');
  }
}
