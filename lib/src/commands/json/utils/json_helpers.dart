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

class JsonHelpers {
  JsonHelpers._();

  /// Helper to unwrap the result if it is a single-element list.
  /// RedisJSON often returns [result] for path commands.
  static dynamic unwrapOne(dynamic result) {
    if (result is List && result.length == 1) {
      return result.first;
    }
    return result;
  }

  // Future<Null> isKeyExists(String key) async {
  //     // Check key existence first
  //     final existsResult = await execute(<String>['EXISTS', key]);
  //     final exists = _unwrapOne(existsResult);
  //     if (exists is int && exists == 0) {
  //       // e.g., key does not exist -> return null here (or throw alternativly)
  //       return null;
  //     }
  // }
}
