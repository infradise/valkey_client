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
