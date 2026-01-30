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

Future<void> main() async {
  // We use two clients to demonstrate Optimistic Locking (Race Condition)
  final client1 = ValkeyClient(host: 'localhost', port: 6379);
  final client2 = ValkeyClient(host: 'localhost', port: 6379);

  await client1.connect();
  await client2.connect();

  print('--- 🚀 Transaction WATCH/UNWATCH Example ---\n');

  const inventoryKey = 'item:101:inventory';

  // 1. Setup: Set initial inventory to 1
  await client1.set(inventoryKey, '1');
  print('1. Initial Inventory: 1');

  // ===========================================================================
  // Scenario: Two users try to buy the last item at the same time.
  // ===========================================================================

  // 2. Client 1 starts watching the inventory
  await client1.watch([inventoryKey]);
  print('2. Client 1 WATCHing inventory...');

  // 3. Client 1 checks the value (Business Logic)
  final valStr = await client1.get(inventoryKey);
  final inventory = int.parse(valStr!);
  print('3. Client 1 sees inventory: $inventory');

  if (inventory > 0) {
    // 4. Simulating Race Condition!
    // Before Client 1 can buy it, Client 2 jumps in and buys it (sets to 0).
    print('   [!] Client 2 sneaks in and buys the item!');
    await client2.set(inventoryKey, '0');

    // 5. Client 1 tries to proceed with the transaction
    print('4. Client 1 attempts to buy (decrement to 0)...');
    await client1.multi();
    await client1.set(inventoryKey, (inventory - 1).toString());

    // 6. EXEC
    final result = await client1.exec();

    if (result == null) {
      print('5. Result: Transaction ABORTED 🛑');
      print('   -> Because the watched key was modified by Client 2.');
    } else {
      print('5. Result: Success ✅');
    }
  }

  print('\n--------------------------------------------------\n');

  // ===========================================================================
  // Scenario: UNWATCH Usage
  // ===========================================================================
  print('[UNWATCH Scenario]');

  // Reset inventory
  await client1.set(inventoryKey, '10');

  // 1. Watch
  await client1.watch([inventoryKey]);
  print('1. Client 1 WATCHing inventory again.');

  // 2. Decide not to proceed
  print('2. Client 1 decides not to buy.');

  // 3. Unwatch manually to free the connection's state
  // (Though technically DISCARD or EXEC would also do this,
  // UNWATCH is explicit)
  await client1.unwatch();
  print('3. Client 1 calls UNWATCH.');

  // 4. Even if Client 2 modifies it now...
  await client2.set(inventoryKey, '9');
  print('   [!] Client 2 modified inventory.');

  // 5. Client 1's next transaction will NOT be affected by the previous WATCH
  await client1.multi();
  await client1.set('log:status', 'checked_inventory');
  final result = await client1.exec();

  print('4. Client 1 transaction result: $result (Should allow execution)');

  // Cleanup
  await client1.close(); // disconnect();
  await client2.close(); // disconnect();
}
