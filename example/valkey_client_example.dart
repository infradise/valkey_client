import 'package:valkey_client/valkey_client.dart';

// Here is a basic example of how to connect and close the client.
// For more examples, check the `/example` folder.

/// This function contains all the command examples.
/// It accepts any client that implements [ValkeyClientBase],
/// demonstrating how robust the interface is.
Future<void> runCommandExamples(ValkeyClientBase client) async {
  try {
    // 1. Connect and authenticate
    // The client will use whichever configuration it was given.
    await client.connect();
    print('✅ Connection successful!');

    // --- PING (v0.2.0) ---
    print("\n--- PING ---");
    print("Sending: PING 'Hello'");
    final pingResponse = await client.ping('Hello');
    print("Received: $pingResponse");

    // --- SET/GET (v0.3.0) ---
    print("\n--- SET/GET ---");
    print("Sending: SET greeting 'Hello, Valkey!'");
    final setResponse = await client.set('greeting', 'Hello, Valkey!');
    print("Received: $setResponse");

    print("Sending: GET greeting");
    final getResponse = await client.get('greeting');
    print("Received: $getResponse");

    // --- MGET (v0.4.0) ---
    print("\n--- MGET (Array Parsing) ---");
    print("Sending: MGET greeting non_existent_key");
    final mgetResponse = await client.mget(['greeting', 'non_existent_key']);
    print("Received: $mgetResponse");

  } catch (e) {
    // Handle connection or authentication errors
    print('❌ Failed: $e');
  } finally {
    // 3. Always close the connection
    print('\nClosing connection...');
    await client.close();
  }
}

/// Main entry point to demonstrate connection patterns.
Future<void> main() async {
  // ---
  // See README.md for Docker instructions on how to run Valkey
  // using the 3 different authentication options.
  // ---

  // Choose ONE of the following client configurations
  // to match your server setup from the README.

  // ====================================================================
  // Configuration for README Option 1: No Authentication
  // ====================================================================
  // final fixedClient = ValkeyClient(
  //   host: '127.0.0.1',
  //   port: 6379,
  // );

  // ====================================================================
  // Configuration for README Option 2: Password Only
  // ====================================================================
  // final fixedClient = ValkeyClient(
  //   host: '127.0.0.1',
  //   port: 6379,
  //   password: 'my-super-secret-password',
  // );

  // ====================================================================
  // Configuration for README Option 3: Username + Password (ACL)
  // ====================================================================
  final fixedClient = ValkeyClient(
    host: '127.0.0.1',
    port: 6379,
    username: 'default',
    password: 'my-super-secret-password',
  );

  print('=' * 40);
  print('Running Example with Constructor Config (fixedClient)');
  print('=' * 40);
  // Using the 'fixedClient' configured above
  await runCommandExamples(fixedClient);


  // ====================================================================
  // Advanced: Using the flexibleClient (Method Config)
  // ====================================================================
  // This pattern is useful if you need to connect to different
  // servers using the same client instance.

  print('\n' * 2);
  print('=' * 40);
  print('Running Example with Method Config (flexibleClient)');
  print('=' * 40);

  final flexibleClient = ValkeyClient(); // No config in constructor

  // Create a reusable connection object (e.g., from a config file)
  final config = (
    host: '127.0.0.1',
    port: 6379,
    username: 'default',
    password: 'my-super-secret-password',
  );

  // We must re-wrap the logic in a try/catch
  // because runCommandExamples handles *command* errors,
  // but this client *instance* needs to be closed.
  try {
    // Pass config directly to the connect() method
    await flexibleClient.connect(
      host: config.host,
      port: config.port,
      username: config.username,
      password: config.password,
    );
    // Once connected, run the same command logic
    await runCommandExamples(flexibleClient);
  } catch (e) {
    print('❌ (flexibleClient) Failed: $e');
  } finally {
    await flexibleClient.close(); // Close this specific client
  }
}
