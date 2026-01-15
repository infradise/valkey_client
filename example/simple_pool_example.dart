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
  // 1. Define connection settings
  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6379,
    // password: 'my-super-secret-password',
  );

  // 2. Create a pool (e.g., max 10 connections)
  final pool = ValkeyPool(connectionSettings: settings, maxConnections: 10);
  ValkeyClient? client;

  try {
    // 3. Acquire a client from the pool
    client = await pool.acquire();

    // 4. Run commands
    await client.set('greeting', 'Hello from ValkeyPool!');
    final value = await client.get('greeting');
    print(value); // Output: Hello from ValkeyPool!
  } on ValkeyConnectionException catch (e) {
    print('Connection or pool acquisition failed: $e');
  } on ValkeyServerException catch (e) {
    print('Server returned an error: $e');
  } finally {
    // 5. Release the client back to the pool
    if (client != null) {
      pool.release(client);
    }
    // 6. Close the pool when the application shuts down
    await pool.close();
  }
}
