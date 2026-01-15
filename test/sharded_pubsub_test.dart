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
import 'package:valkey_client/valkey_client.dart';

void main() {
  // Configure the port according to the test environment
  final client = ValkeyClient(host: '127.0.0.1', port: 6379);

  setUpAll(() async {
    await client.connect();
  });

  tearDownAll(() async {
    await client.close();
  });

  test('SPUBLISH should execute without error', () async {
    const channel = 'shard-chan:{123}'; // Hashtag used to fix slot if needed

    // Since there are no subscribers, it should return 0 (success as long as
    // no error occurs)
    final receiverCount = await client.spublish(channel, 'Hello Sharding!');

    expect(receiverCount, greaterThanOrEqualTo(0));
    print('SPUBLISH sent successfully. Receivers: $receiverCount');
  });
}
