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

/// Parses and prints the module list in a formatted ASCII table.
///
/// [rawModuleList] is the raw response from 'MODULE LIST' command.
/// Example input: [[name, json, ver, 10002...], [name, search...]]
@Deprecated('Will be removed in the future.')
void printPrettyModuleList1(List<dynamic> rawModuleList) {
  if (rawModuleList.isEmpty) {
    print('No modules loaded.');
    return;
  }

  // // 1. Parse raw list into a list of maps
  // final rows = <Map<String, String>>[];
  // final headers = {'name', 'ver', 'path', 'args'}; // Columns to display

  // for (final item in rawModuleList) {
  //   if (item is List) {
  //     final moduleMap = <String, String>{};
  //     for (var i = 0; i < item.length; i += 2) {
  //       final key = item[i].toString();
  //       final value = item[i + 1];

  //       // specific handling for 'args' which is a list
  //       if (value is List) {
  //         moduleMap[key] = value.isEmpty ? '-' : value.join(', ');
  //       } else {
  //         moduleMap[key] = value.toString();
  //       }
  //     }
  //     rows.add(moduleMap);
  //   }
  // }

  // // 2. Calculate column widths dynamically
  // final colWidths = <String, int>{
  //   'name': 6, // min width
  //   'ver': 5,
  //   'path': 10,
  //   'args': 6
  // };

  // for (final row in rows) {
  //   for (final col in headers) {
  //     final len = row[col]?.length ?? 0;
  //     if (len > (colWidths[col] ?? 0)) {
  //       colWidths[col] = len;
  //     }
  //   }
  // }

  // // 3. Helper to create a separator line
  // String createSeparator() {
  //   final buffer = StringBuffer('+');
  //   for (final col in headers) {
  //     buffer.write('-' * ((colWidths[col] ?? 0) + 2)); // +2 for padding
  //     buffer.write('+');
  //   }
  //   return buffer.toString();
  // }

  // // 4. Print Table
  // print('\n📦 Loaded Modules:');
  // final separator = createSeparator();
  // print(separator);

  // // Print Header
  // var headerRow = '|';
  // for (final col in headers) {
  //   headerRow += ' ${col.toUpperCase().padRight(colWidths[col]!)} |';
  // }
  // print(headerRow);
  // print(separator);
  // // final headerRow = StringBuffer();
  // // headerRow.write('|');
  // // for (final col in headers) {
  // //   headerRow.write(' ${col.toUpperCase().padRight(colWidths[col]!)} |');
  // // }
  // // print(headerRow.toString());
  // // print(separator);

  // // Print Data Rows
  // for (final row in rows) {
  //   var dataRow = '|';
  //   for (final col in headers) {
  //     final text = row[col] ?? '-';
  //     dataRow += ' ${text.padRight(colWidths[col]!)} |';
  //   }
  //   print(dataRow);
  // }
  // print(separator);
  // print(''); // Empty line at the end

  // // for (final row in rows) {
  // //   final dataRow = StringBuffer();
  // //   dataRow.write('|');
  // //   for (final col in headers) {
  // //     final text = row[col] ?? '-';
  // //     dataRow.write(' ${text.padRight(colWidths[col]!)} |');
  // //   }
  // //   print(dataRow.toString());
  // // }
  // // print(separator);
  // // print(''); // Empty line at the end
}
