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

import '../commands.dart';

extension JsonDel on JsonCommands {
  /// JSON.DEL key [path]
  ///
  /// Deletes a value.
  ///
  /// [key] The key to modify.
  /// [path] The JSON path to delete. Defaults to root (`$`).
  Future<int?> jsonDel({
    required String key,
    String path = r'$',
  }) async {
    final result = await execute(<String>['JSON.DEL', key, path]);

    // Valkey returns the integer number of paths deleted (0 or 1 usually)
    if (result is int) return result;
    return int.tryParse(result.toString());
  }
}
