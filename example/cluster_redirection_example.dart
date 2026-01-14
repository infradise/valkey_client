/*
 * Copyright 2026 Infradise Inc.
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

import 'dart:async';
import 'package:valkey_client/valkey_client.dart';

void main() async {
  // 1. Connect to the cluster
  final initialNodes = [
    ValkeyConnectionSettings(
      host: '127.0.0.1',
      port: 7001,
      commandTimeout: Duration(seconds: 2), // Short timeout for fast failover
    ),
  ];

  // Create client with Auto-NAT logic
  final client = ValkeyClusterClient(initialNodes, maxRedirects: 3);

  try {
    print('Connecting to cluster...');
    await client.connect();
    print('✅ Connected.');

    print('\nStarting Resilience & Continuous Operations Test Loop...');
    print('----------------------------------------------------------------');
    print('👉 ACTION REQUIRED: Kill the current master node to see failover!');
    print('   Run: valkey-cli -p <PORT> DEBUG SEGFAULT');
    // e.g., valkey-cli -h valkey-7001 -p 7001 DEBUG SEGFAULT
    // e.g., valkey-cli -p <port> cluster nodes
    print('----------------------------------------------------------------\n');
    print('👉 TIP: Now open your terminal and try these chaos actions:');
    print('   1. valkey-cli -p 7001 DEBUG SEGFAULT (Kill a node)');
    print('   2. valkey-cli --cluster reshard ... (Move slots)');
    print(
        '   3. Watch this client recover automatically! (MOVED/ASK handling)\n');

    int count = 0;
    const key = 'resilience:key';

    // Infinite loop to demonstrate resilience
    while (true) {
      try {
        count++;
        final value = 'val-$count';

        // 1. Write
        await client.set(key, value);

        // 2. Read
        final result = await client.get(key);

        // 3. Check WHO served this request (New Feature)
        final node = client.getMasterFor(key);
        final nodeStr = node != null ? '${node.host}:${node.port}' : 'Unknown';

        if (result == value) {
          // Print Success with Node info
          print('[SUCCESS $count] Node $nodeStr | $key = $result');
        } else {
          print(
              '[FAILURE $count] Node $nodeStr | Value mismatch! Expected $value, got $result');
        }
      } on ValkeyClientException catch (e) {
        // Client-side errors (e.g. pool exhausted during failover)
        print('[RETRY $count] Client error: $e');
      } on ValkeyServerException catch (e) {
        // Server errors (e.g. CLUSTERDOWN)
        print('[RETRY $count] Server error: $e');
      } catch (e) {
        print('[ERROR $count] Unexpected: $e');
      }

      // await client.del(key);

      // Wait a bit before next op
      await Future.delayed(Duration(seconds: 1));
    }
  } finally {
    await client.close();
  }
}

/*
EXPECTED OUTPUT
===============

Connecting to cluster...
✅ Connected.

Starting Resilience & Continuous Operations Test Loop...
----------------------------------------------------------------
👉 ACTION REQUIRED: Kill the current master node to see failover!
   Run: valkey-cli -p <PORT> DEBUG SEGFAULT
----------------------------------------------------------------

👉 TIP: Now open your terminal and try these chaos actions:
   1. valkey-cli -p 7001 DEBUG SEGFAULT (Kill a node)
   2. valkey-cli --cluster reshard ... (Move slots)
   3. Watch this client recover automatically! (MOVED/ASK handling)

[SUCCESS 1] Node 192.168.65.254:7004 | resilience:key = val-1
[SUCCESS 2] Node 192.168.65.254:7004 | resilience:key = val-2
[SUCCESS 3] Node 192.168.65.254:7004 | resilience:key = val-3
[SUCCESS 4] Node 192.168.65.254:7004 | resilience:key = val-4
[SUCCESS 5] Node 192.168.65.254:7004 | resilience:key = val-5
[SUCCESS 6] Node 192.168.65.254:7004 | resilience:key = val-6
[SUCCESS 7] Node 192.168.65.254:7004 | resilience:key = val-7
[SUCCESS 8] Node 192.168.65.254:7004 | resilience:key = val-8
[SUCCESS 9] Node 192.168.65.254:7004 | resilience:key = val-9
[SUCCESS 10] Node 192.168.65.254:7004 | resilience:key = val-10
[SUCCESS 11] Node 192.168.65.254:7004 | resilience:key = val-11
[SUCCESS 12] Node 192.168.65.254:7004 | resilience:key = val-12
[SUCCESS 13] Node 192.168.65.254:7004 | resilience:key = val-13
[SUCCESS 14] Node 192.168.65.254:7004 | resilience:key = val-14
[SUCCESS 15] Node 192.168.65.254:7004 | resilience:key = val-15
[RETRY 16] Client error: ValkeyClientException: Cluster operation failed after 4 retries. Last error: ValkeyConnectionException: Failed to create new pool connection: ValkeyConnectionException: Failed to connect to 127.0.0.1:7004. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63573 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63573) (Original: ValkeyConnectionException: Failed to connect to 127.0.0.1:7004. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63573 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63573))
[RETRY 17] Client error: ValkeyClientException: Cluster operation failed after 4 retries. Last error: ValkeyConnectionException: Failed to create new pool connection: ValkeyConnectionException: Failed to connect to 127.0.0.1:7004. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63616 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63616) (Original: ValkeyConnectionException: Failed to connect to 127.0.0.1:7004. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63616 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63616))
[RETRY 18] Client error: ValkeyClientException: Cluster operation failed after 4 retries. Last error: ValkeyConnectionException: Failed to create new pool connection: ValkeyConnectionException: Failed to connect to 127.0.0.1:7004. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63657 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63657) (Original: ValkeyConnectionException: Failed to connect to 127.0.0.1:7004. SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63657 (Original: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = 127.0.0.1, port = 63657))
[SUCCESS 19] Node 192.168.65.254:7002 | resilience:key = val-19
[SUCCESS 20] Node 192.168.65.254:7002 | resilience:key = val-20
[SUCCESS 21] Node 192.168.65.254:7002 | resilience:key = val-21
[SUCCESS 22] Node 192.168.65.254:7002 | resilience:key = val-22
[SUCCESS 23] Node 192.168.65.254:7002 | resilience:key = val-23
[SUCCESS 24] Node 192.168.65.254:7002 | resilience:key = val-24
[SUCCESS 25] Node 192.168.65.254:7002 | resilience:key = val-25
[SUCCESS 26] Node 192.168.65.254:7002 | resilience:key = val-26

*/
