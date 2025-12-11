import 'dart:async';
import 'package:valkey_client/valkey_client.dart';

/// Standalone & Pool Example: The essence of Smart Release
///
/// This example demonstrates the DX improvement in v1.7.0 where developers
/// no longer need to worry about discarding connections — simply calling
/// `release` is enough.
/// After "polluting" a connection with Transaction and Pub/Sub,
/// you can see that a single `release` call cleans it up neatly.

void main() async {
  // 1. Configure the Connection Pool (Standalone)
  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6379,
  );

  // Create a pool with a limit of 5 connections
  final pool = ValkeyPool(
    connectionSettings: settings,
    maxConnections: 5
  );

  print('--- Starting v1.7.0 Smart Pool Example ---');

  try {
    // [Scenario 1] Transaction (Stateful Operation)
    print('\n1. Performing Transaction...');
    final clientTx = await pool.acquire();

    // Start a transaction (Changes client state to "In Transaction")
    await clientTx.multi();
    await clientTx.set('tx_key', 'tx_value');
    await clientTx.exec();
    print('   Transaction executed.');

    // v1.7.0 MAGIC:
    // Even though the client was stateful, we just call release().
    // The pool detects the state change and automatically refreshes the connection.
    pool.release(clientTx);
    print('   Client released (Smart Release handled cleanup).');


    // [Scenario 2] Pub/Sub (Stateful Operation)
    print('\n2. Performing Pub/Sub...');
    final clientSub = await pool.acquire();

    // Enter Pub/Sub mode (Changes client state to "Listening")
    final sub = clientSub.subscribe(['my-channel']);
    await sub.ready;
    print('   Subscribed to channel. Client is now dirty (Stateful).');

    // v1.7.0 MAGIC:
    // Previously, you had to manually discard() or unsubscribe().
    // Now, just release(). The pool sees 'isStateful == true' and discards it.
    pool.release(clientSub);
    print('   Pub/Sub Client released (Automatically discarded & replaced).');


    // [Scenario 3] Verification (Reuse)
    print('\n3. Verifying Pool Health...');
    // If Smart Release worked, we should get a fresh, clean client here.
    final clientClean = await pool.acquire();

    // If the previous clients weren't cleaned up, this PING might fail
    // or we might get a client stuck in Pub/Sub mode.
    final response = await clientClean.ping();
    print('   Ping response: $response (Pool is healthy!)');

    pool.release(clientClean);

  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await pool.close();
    print('\n✅ Example finished successfully.');
  }
}