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

extension HIncrByFloatCommand on HashCommands {
  /// HINCRBYFLOAT key field increment
  ///
  /// Increment the specified [field] of a hash stored at [key], and
  /// representing a floating point number, by the specified [increment].
  /// If the field does not exist, it is set to 0 before performing
  /// the operation.
  ///
  /// Returns the value of [field] after the increment.
  Future<double> hIncrByFloat(
      String key, String field, double increment) async {
    final cmd = <String>['HINCRBYFLOAT', key, field, increment.toString()];
    final result = await execute(cmd);

    if (result is String) {
      return double.tryParse(result) ?? 0.0;
    } else if (result is num) {
      return result.toDouble();
    }
    throw Exception('Unexpected return type for HINCRBYFLOAT');
  }
}
