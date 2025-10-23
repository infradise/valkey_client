import 'package:valkey_client/valkey_client.dart';

// Here is a basic example of how to connect and close the client.
// For more examples, check the `/example` folder.

void main() async {
  // ---
  // See README.md for Docker instructions on how to run
  // a Valkey server with or without authentication.
  // ---
  // IMPORTANT: Ensure a Valkey server is running on localhost (127.0.0.1:6379).

  // --- Option 1: Configure in the Constructor (Recommended for 90% of cases) ---

  // Set default connection parameters here
  final client = ValkeyClient(
    // Create a new client instance.
    // --- Connection Parameters ---
    // Change these to match your server configuration
    host: '127.0.0.1',
    port: 6379,
    // Set these if your Valkey server requires authentication
    // Provide username (optional if password only)
    username: 'default', // Valkey/Redis 6+ default username
    // Provide password (if any)
    password: 'my-super-secret-password',
    // -----------------------------
  );

  testPing() async {
    // Execute commands
    print("Sending: PING");
    final response = await client.ping();
    print("Received: $response"); // Should be "PONG"

    print("Sending: PING 'Hello World'");
    final response2 = await client.ping('Hello World');
    print("Received: $response2"); // Should be "Hello World"
  }

  try {
    // connect() is called *without* parameters,
    // using the defaults provided in the constructor.
    await client.connect();
    print('✅ (Option 1) Connected successfully using constructor config!');

    // Once connected, you will be able to execute commands:
    testPing();
  } catch (e) {
    // Handle connection or authentication errors (e.g., server not running)
    print('❌ (Option 1) Failed to connect or authenticate: $e');
  } finally {
    // Always close the connection when you are done.
    print('(Option 1) Closing connection...');
    await client.close();
  }

  // --- Option 2: Configure in the connect() method (For advanced cases) ---

  // Create a "stateless" client
  final flexibleClient = ValkeyClient();

  try {
    // Pass connection parameters directly to connect()
    // These will override any constructor defaults.
    await flexibleClient.connect(
      // --- Connection Parameters ---
      // Change these to match your server configuration
      host: '127.0.0.1',
      port: 6379,
      // Set these if your Valkey server requires authentication
      // Provide username (optional if password only)
      username: 'default', // Valkey/Redis 6+ default username
      // Provide password (if any)
      password: 'my-super-secret-password',
      // -----------------------------
    );
    print('✅ (Option 2) Connected successfully using method config!');

    // Once connected, you will be able to execute commands:
    testPing();
  } catch (e) {
    // Handle connection or authentication errors (e.g., server not running)
    print('❌ (Option 2) Failed to connect or authenticate: $e');
  } finally {
    // Always close the connection when you are done.
    print('(Option 2) Closing connection...');
    await flexibleClient.close();
  }
}
