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

import '../commands/json/commands.dart' show JsonCommands;

/// Prints the parsed the module list in a formatted ASCII table.
///
/// [moduleList] should be the result from [JsonCommands.getModuleList].
void printPrettyModuleList(List<Map<String, dynamic>> moduleList) {
  if (moduleList.isEmpty) {
    print('No modules loaded.');
    return;
  }

  final headers = {'name', 'ver', 'path', 'args'}; // Columns to display

  // 1. Calculate column widths dynamically
  final colWidths = <String, int>{'name': 6, 'ver': 5, 'path': 10, 'args': 6};

  for (final row in moduleList) {
    for (final col in headers) {
      final value = row[col];
      final strVal = (value is List) ? value.join(', ') : value.toString();

      if (strVal.length > (colWidths[col] ?? 0)) {
        colWidths[col] = strVal.length;
      }
    }
  }

  // 2. Helper to create a separator line
  String createSeparator() {
    final buffer = StringBuffer('+');
    for (final col in headers) {
      buffer.write('-' * ((colWidths[col] ?? 0) + 2));
      buffer.write('+');
    }
    return buffer.toString();
  }

  // 3. Print Table
  print('\n📦 Loaded Modules:');
  final separator = createSeparator();
  print(separator);

  // Print Header
  final headerRow = StringBuffer();
  headerRow.write('|');
  for (final col in headers) {
    headerRow.write(' ${col.toUpperCase().padRight(colWidths[col]!)} |');
  }
  print(headerRow.toString());
  print(separator);

  // Print Data Rows
  for (final row in moduleList) {
    final dataRow = StringBuffer();
    dataRow.write('|');
    for (final col in headers) {
      final value = row[col];
      // Handle list types (like 'args') specifically for display
      final text = (value is List)
          ? (value.isEmpty ? '-' : value.join(', '))
          : (value?.toString() ?? '-');

      dataRow.write(' ${text.padRight(colWidths[col]!)} |');
    }
    print(dataRow.toString());
  }
  print(separator);
  print(''); // Empty line at the end
}
