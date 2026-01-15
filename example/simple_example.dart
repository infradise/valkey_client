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

import 'package:valkey_client/valkey_client.dart';

void main() async {
  // 1. Configure the client
  final client = ValkeyClient(
    host: '127.0.0.1',
    port: 6379,
    // password: 'my-super-secret-password',
  );

  try {
    // 2. Connect
    await client.connect();

    // 3. Run commands
    await client.set('greeting', 'Hello, Valkey!');
    final value = await client.get('greeting');
    print(value); // Output: Hello, Valkey!
  } on ValkeyConnectionException catch (e) {
    print('Connection failed: $e');
  } on ValkeyServerException catch (e) {
    print('Server returned an error: $e');
  } finally {
    // 4. Close the connection
    await client.close();
  }
}
