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
import 'dart:io';
import 'package:valkey_client/valkey_client.dart';

void main() async {
  // Configure with a known cluster entry point
  final initialNodes = [
    ValkeyConnectionSettings(host: '127.0.0.1', port: 7001),
  ];

  // Enable retries for failover
  final client = ValkeyClusterClient(initialNodes, maxRedirects: 10);

  int successCount = 0;
  int failCount = 0;

  String nodeStr = '';
  final delay = Duration(milliseconds: 500); // set to human friendly value

  try {
    await client.connect();
    print('✅ Cluster connected. Starting Stress Test...');
    print('Press Ctrl+C to stop.');
    print('----------------------------------------------------------------');
    print(
        'ACTION: Kill a master node (e.g., valkey-cli -p 7001 DEBUG SEGFAULT)');
    print('        and watch the client recover automatically.');
    print('----------------------------------------------------------------');

    int i = 0;
    while (true) {
      i++;
      final key = 'stress:key:$i';
      final value = 'val-$i';

      final stopwatch = Stopwatch()..start();
      String status = '';

      try {
        // Perform Set & Get
        await client.set(key, value);
        final res = await client.get(key);

        if (res == value) {
          final node = client.getMasterFor(key);
          nodeStr = node != null ? '${node.host}:${node.port}' : 'Unknown';

          successCount++;
        } else {
          failCount++;
          print('\n❌ Data Mismatch for $key');
        }
      } catch (e) {
        failCount++;
        print('\n❌ Operation Failed: $e');
        status = 'FAILED';
      } finally {
        stopwatch.stop();

        // If operation took longer than 500ms, it likely involved a failover/retry
        status = 'OK';
        if (stopwatch.elapsedMilliseconds > 500) {
          status = 'RECOVERED (${stopwatch.elapsedMilliseconds}ms)';
        }

        // Print Dashboard (Overwriting current line for a dashboard effect)
        String output =
            '\r[Stress Test] nodeStr = $nodeStr | Success: $successCount | Failed: $failCount | Last: $status';
        output += '${' ' * 30} ';

        stdout.write(output);
      }

      // Throttle slightly to allow reading the logs
      await Future.delayed(delay);
    }
  } catch (e) {
    print('\nFatal Error: $e');
  } finally {
    await client.close();
  }
}
