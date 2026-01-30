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

import '../commands.dart' show TransactionCommands;

extension WatchCommand on TransactionCommands {
  /// WATCH key [key ...]
  ///
  /// Marks the given [keys] to be watched for conditional execution of
  /// a transaction.
  /// If any of the watched keys are modified by another client between
  /// the WATCH and the EXEC,
  /// the transaction will fail (EXEC returns a null reply).
  ///
  /// Returns "OK" on success.
  Future<String> watch(List<String> keys) async {
    if (keys.isEmpty) return 'OK';

    final cmd = <String>['WATCH', ...keys];
    final result = await execute(cmd);

    return result.toString();
  }
}
