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

import '../commands.dart' show TransactionsCommands;

extension UnwatchCommand on TransactionsCommands {
  /// UNWATCH
  ///
  /// Flushes all the watched keys.
  /// If you call EXEC or DISCARD, there's no need to manually call UNWATCH.
  ///
  /// Returns "OK" on success.
  Future<String> unwatch() async {
    final cmd = <String>['UNWATCH'];
    final result = await execute(cmd);

    return result.toString();
  }
}
