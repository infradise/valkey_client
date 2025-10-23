import 'package:valkey_client/valkey_client.dart';

void main() async {
  // ---
  // IMPORTANT: Ensure a Valkey server is running on localhost (127.0.0.1:6379).
  //
  // You can easily start one using Docker:
  // docker run -d --name my-valkey -p 6379:6379 valkey/valkey:latest
  // ---

  // 1. Create a new client instance.
  final client = ValkeyClient();

  try {
    // 2. Connect to the Valkey server.
    // This future completes once the socket connection is established.
    await client.connect();

    print('✅ Connection successful!');

    // 3. (Preview for Chapter 2)
    // Once connected, you will be able to execute commands:
    //
    // print('Sending PING...');
    // final response = await client.ping();
    // print('Server response: $response'); // Expected output: PONG

  } catch (e) {
    // Handle connection errors (e.g., server not running)
    print('❌ Connection failed: $e');
  } finally {
    // 4. Always close the connection when you are done.
    print('Closing connection...');
    await client.close();
  }
}
