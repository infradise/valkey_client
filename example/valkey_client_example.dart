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
    print("Received: $mgetResponse"); // Should be "[Hello, Valkey!, null]"

    // --- HASH (v0.5.0) ---
    print("\n--- HASH (Map/Object) ---");
    print("Sending: HSET user:1 name 'Valkyrie'");
    final hsetResponse = await client.hset('user:1', 'name', 'Valkyrie');
    print("Received (1=new, 0=update): $hsetResponse");

    print("Sending: HSET user:1 project 'valkey_client'");
    await client.hset('user:1', 'project', 'valkey_client');

    print("Sending: HGET user:1 name");
    final hgetResponse = await client.hget('user:1', 'name');
    print("Received: $hgetResponse"); // Should be "Valkyrie"

    print("Sending: HGETALL user:1");
    final hgetAllResponse = await client.hgetall('user:1');
    print(
        "Received Map: $hgetAllResponse"); // Should be {name: Valkyrie, project: valkey_client}

    // --- LIST (v0.6.0) ---
    print("\n--- LIST (Queue/Stack) ---");
    print("Sending: LPUSH mylist 'item1'");
    await client.lpush('mylist', 'item1');
    print("Sending: LPUSH mylist 'item2'");
    final length = await client.lpush('mylist', 'item2');
    print("Received list length: $length"); // Should be 2

    print("Sending: LRANGE mylist 0 -1");
    final listResponse = await client.lrange('mylist', 0, -1);
    print(
        "Received list: $listResponse"); // Should be [item2, item1] (LPUSH prepends)

    print("Sending: RPOP mylist");
    final poppedItem = await client.rpop('mylist');
    print(
        "Received popped item: $poppedItem"); // Should be "item1" (RPOP removes from the end)

    // --- SET / SORTED SET (v0.7.0) ---
    print("\n--- SET (Unique Tags) / SORTED SET (Leaderboard) ---");
    print("Sending: SADD users:1:tags 'dart'");
    await client.sadd('users:1:tags', 'dart');
    print("Sending: SADD users:1:tags 'valkey'");
    await client.sadd('users:1:tags', 'valkey');

    print("Sending: SMEMBERS users:1:tags");
    final tags = await client.smembers('users:1:tags');
    print("Received tags (unordered): $tags"); // Should contain [dart, valkey]

    print("Sending: ZADD leaderboard 100 'PlayerOne'");
    await client.zadd('leaderboard', 100, 'PlayerOne');
    print("Sending: ZADD leaderboard 150 'PlayerTwo'");
    await client.zadd('leaderboard', 150, 'PlayerTwo');

    print("Sending: ZRANGE leaderboard 0 -1"); // Get all players by score
    final leaderboard = await client.zrange('leaderboard', 0, -1);
    print(
        "Received leaderboard (score low to high): $leaderboard"); // Should be [PlayerOne, PlayerTwo]

    // --- KEY MANAGEMENT (v0.8.0) ---
    print("\n--- KEY MANAGEMENT (Expiration & Deletion) ---");
    print("Sending: EXPIRE greeting 10"); // Expire the 'greeting' key in 10s
    final expireResponse = await client.expire('greeting', 10);
    print("Received (1=set, 0=not set): $expireResponse");

    print("Sending: TTL greeting");
    final ttlResponse = await client.ttl('greeting');
    print(
        "Received TTL (seconds, -1=no expire, -2=not exist): $ttlResponse"); // Should be <= 10

    print("Sending: DEL mylist"); // Delete the list key
    final delResponse = await client.del('mylist');
    print("Received (number of keys deleted): $delResponse"); // Should be 1

    print("Sending: EXISTS mylist");
    final existsResponse = await client.exists('mylist');
    print("Received (1=exists, 0=not exist): $existsResponse"); // Should be 0
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
