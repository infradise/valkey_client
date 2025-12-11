import 'package:valkey_client/valkey_client.dart';

void main() async {
  // 1. Configure the client
  final client = ValkeyClient(
    host: '127.0.0.1',
    port: 6379,
    // password: 'my-super-secret-password',
  );

  try {
    // 2. Connect
    await client.connect();

    // 3. Run commands
    await client.set('greeting', 'Hello, Valkey!');
    final value = await client.get('greeting');
    print(value); // Output: Hello, Valkey!
  } on ValkeyConnectionException catch (e) {
    print('Connection failed: $e');
  } on ValkeyServerException catch (e) {
    print('Server returned an error: $e');
  } finally {
    // 4. Close the connection
    await client.close();
  }
}

/*
EXPECTED OUTPUT
===============

Hello, Valkey!
*/

