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
  // 1. Configure the client to connect to ONE node of the cluster.
  // We assume a cluster node is running on port 7001.
  final client = ValkeyClient(
    host: '127.0.0.1',
    port: 7001,
  );

  try {
    // 2. Connect
    await client.connect();
    print('✅ Connected to cluster node at 127.0.0.1:7001');

    // 3. Run the new v1.2.0 command
    print('\nFetching cluster topology using CLUSTER SLOTS...');
    final List<ClusterSlotRange> slotRanges = await client.clusterSlots();

    // 4. Print the results
    print('Cluster topology loaded. Found ${slotRanges.length} slot ranges:');
    for (final range in slotRanges) {
      print('--------------------');
      print('  Slots: ${range.startSlot} - ${range.endSlot}');
      print(
          '  Master: ${range.master.host}:${range.master.port} (ID: ${range.master.id})');
      if (range.replicas.isNotEmpty) {
        print('  Replicas:');
        for (final replica in range.replicas) {
          print('    - ${replica.host}:${replica.port} (ID: ${replica.id})');
        }
      } else {
        print('  Replicas: None');
      }
    }
  } on ValkeyConnectionException catch (e) {
    print('\n❌ Connection Failed: $e');
    print('Ensure a Valkey CLUSTER node is running on 127.0.0.1:7001.');
  } on ValkeyServerException catch (e) {
    print('\n❌ Server Error: $e');
    print('Did you run this against a standalone (non-cluster) server?');
  } on ValkeyParsingException catch (e) {
    print('\n❌ Parsing Error: $e');
    print('Failed to parse the server response.');
  } on ValkeyClientException catch (e) {
    print('\n❌ Client Error: $e');
  } catch (e) {
    print('\n❌ Unknown Error: $e');
  } finally {
    // 5. Close the connection
    print('\nClosing connection...');
    await client.close();
  }
}

/*
EXPECTED OUTPUT
===============

✅ Connected to cluster node at 127.0.0.1:7001

Fetching cluster topology using CLUSTER SLOTS...
Cluster topology loaded. Found 3 slot ranges:
--------------------
  Slots: 0 - 5460
  Master: 192.168.65.254:7001 (ID: 9cb6e8f7e10d85a7a6a30f5fc17f06a5775b1805)
  Replicas:
    - 192.168.65.254:7006 (ID: 30620559f4420dd5f05308401a2c96b34362739c)
--------------------
  Slots: 5461 - 10922
  Master: 192.168.65.254:7002 (ID: 75d08706344d98c243c9579abf89a6075f39534f)
  Replicas:
    - 192.168.65.254:7004 (ID: 9a493209da40578023c314f49a1b234de045d995)
--------------------
  Slots: 10923 - 16383
  Master: 192.168.65.254:7003 (ID: e61e5a1ebab6ead786f21183d054fc239c510495)
  Replicas:
    - 192.168.65.254:7005 (ID: bdad94835d820ffc4302ea689f2bdba6c439be8e)

Closing connection...
*/
