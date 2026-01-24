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

/// Result for SCAN command
class ScanResult {
  final String cursor;
  final List<String> keys;
  ScanResult(this.cursor, this.keys);
}

/// Mixin to support Redis-JSON and Valkey-JSON commands.
/// from @Keyscope
mixin GenericCommands {
  Future<dynamic> execute(List<String> command);

  Future<ScanResult> scan({
    required String cursor,
    String match = '*',
    int count = 100,
  }) async {
    try {
      /// Execute SCAN command: SCAN <cursor> MATCH <pattern> COUNT <count>
      final cmd = <String>[
        'SCAN',
        cursor,
        'MATCH',
        match,
        'COUNT',
        count.toString()
      ];

      /// Sends a command to the server.
      final result = await execute(cmd);

      /// Result is typically a list: [nextCursor, [key1, key2, ...]]
      if (result is List && result.length == 2) {
        final nextCursor = result[0].toString();
        final rawKeys = result[1];

        var keys = <String>[];
        if (rawKeys is List) {
          keys = rawKeys.map((e) => e.toString()).toList();
        }

        return ScanResult(nextCursor, keys);
      } else {
        throw Exception('Unexpected SCAN response format');
      }
    } catch (e) {
      print('Failed to SCAN keys: $e');
      rethrow;
    }
  }
}
