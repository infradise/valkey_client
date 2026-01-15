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

import 'package:test/test.dart';
import 'package:valkey_client/src/cluster_hash.dart';

void main() {
  group('getHashSlot (CRC-16/XMODEM % 16384)', () {
    // Known values calculated from external Redis/Valkey clients / Valkey 9.0.0

    test('should calculate correct slot for simple keys', () {
      // redis-cli> CLUSTER KEYSLOT foo
      // (integer) 12182
      expect(getHashSlot('foo'), 12182);

      // redis-cli> CLUSTER KEYSLOT key:A
      // (integer) 9028
      expect(getHashSlot('key:A'), 9366); // 7002

      // redis-cli> CLUSTER KEYSLOT key:B
      // (integer) 13134
      expect(getHashSlot('key:B'), 5365); // 7001
    });

    test('should use only the hash tag if present', () {
      // The slot should be calculated for "foo" (12182), not the whole string.
      // Slot for "foo" (12182)
      expect(getHashSlot('user:1000:{foo}:profile'), 12182);
      expect(getHashSlot('bar{foo}baz'), 12182);
    });

    test('should ignore empty hash tags', () {
      // If tag is "{}" (empty), hash the whole string.
      // Slot for "foo{}bar"
      expect(getHashSlot('foo{}bar'), 14292);
    });

    test('should ignore incomplete hash tags', () {
      // If tag is unclosed, hash the whole string.
      // Slot for "foo{bar"
      expect(getHashSlot('foo{bar'), 15278);
      // Slot for "foo}bar"
      expect(getHashSlot('foo}bar'), 7223);
    });
  });
}
