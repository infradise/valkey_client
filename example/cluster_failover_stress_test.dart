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

  try {
    await client.connect();
    print('✅ Cluster connected. Starting Stress Test...');
    print('Press Ctrl+C to stop.');
    print('----------------------------------------------------------------');
    print('ACTION: Kill a master node (e.g., valkey-cli -p 7001 DEBUG SEGFAULT)');
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
          // final node = client.getMasterFor(key);
          // final nodeStr = node != null ? '${node.host}:${node.port}' : 'Unknown';

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
        stdout.write(
            '\r[Stress Test] Success: $successCount | Failed: $failCount | Last: $status        '); // (+): nodeStr = $nodeStr
      }

      // Throttle slightly to allow reading the logs
      await Future.delayed(Duration(milliseconds: 50));
    }
  } catch (e) {
    print('\nFatal Error: $e');
  } finally {
    await client.close();
  }
}
