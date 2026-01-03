import 'package:valkey_client/valkey_client.dart';

void main() async {
  print('🚀 Starting Replica Read & Load Balancing Example...');

  final portMaster = 6379; // Master Port (e.g., 1 Master and 2 Replicas)
  final portReplica1 = 6380;
  final portReplica2 = 6381;

  // Base settings for Master
  final masterSettings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: portMaster,
    // [v2.2.0] Prefer reading from replicas
    readPreference: ReadPreference.preferReplica, // (or testing for ReadPreference.master)
    // [v2.2.0] Use Round-Robin to distribute load among replicas
    loadBalancingStrategy: LoadBalancingStrategy.roundRobin,
    commandTimeout: Duration(seconds: 2),
    // If you had password/SSL, you'd set it here once.
  );

  // 1. Configure Connection Settings
  // We connect to the Master (6379), but request to read from Replicas.

  // Define full settings for this connection, including explicit replicas
  final settings = masterSettings.copyWith(
    explicitReplicas: [
      // Inherit master settings (Auth, SSL, etc.) and just change Port
      masterSettings.copyWith(port: portReplica1),
      masterSettings.copyWith(port: portReplica2),
    ],
  );

  final client = ValkeyClient.fromSettings(settings);

  try {
    // 2. Connect
    // Internally, this will connect to Master AND discover/connect to Replicas (6380, 6381).
    await client.connect();
    print('✅ Connected to Master and Discovered Replicas.');

    // --- Data Setup ---
    // 3. Write Operation (Always goes to Master)
    // SET is not a read-only command.
    print('\n✍️  Writing data (Routed to Master)...');
    for (int i = 0; i < 5; i++) {
      await client.set('user:$i', 'value_$i');
    }

    // Wait briefly for replication to happen (usually near-instant)
    await Future.delayed(Duration(milliseconds: 100)); // 100 or 200: Replication wait

    // --- Read & Verify Load Balancing ---
    // 4. Read Operations (Routed to Replicas)
    // GET is a read-only command.
    // Because we use Round-Robin, requests should alternate between Replica 1 and Replica 2.
    print('\n📖 Reading data (Routed to Replicas via Round-Robin)...');

    for (int i = 0; i < 5; i++) {
      final key = 'user:$i';
      final value = await client.get(key);

      final usedConfig = client.lastUsedConnectionConfig;

      String sourceName = 'Unknown';
      if (usedConfig != null) {
        if (usedConfig.port == portMaster) {
          sourceName = 'Master';
        } else {
          sourceName = 'Replica (${usedConfig.port})';
        }
      }

      print('   [GET $key] -> Result: $value -- from $sourceName');
      // Conceptually:
      // Req 1 -> Replica 1 (6380)
      // Req 2 -> Replica 2 (6381)
      // Req 3 -> Replica 1 (6380) ...
    }

  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await client.close();
    print('\n👋 Connection closed.');
  }
}

/*
EXPECTED OUTPUT
===============

1 Master only

🚀 Starting Replica Read & Load Balancing Example...
✅ Connected to Master and Discovered Replicas.

✍️  Writing data (Routed to Master)...

📖 Reading data (Routed to Replicas via Round-Robin)...
   [GET user:0] -> Result: value_0 -- from Master
   [GET user:1] -> Result: value_1 -- from Master
   [GET user:2] -> Result: value_2 -- from Master
   [GET user:3] -> Result: value_3 -- from Master
   [GET user:4] -> Result: value_4 -- from Master

👋 Connection closed.

---

1 Master and 2 Replicas

🚀 Starting Replica Read & Load Balancing Example...
✅ Connected to Master and Discovered Replicas.

✍️  Writing data (Routed to Master)...

📖 Reading data (Routed to Replicas via Round-Robin)...
   [GET user:0] -> Result: value_0 -- from Replica
   [GET user:1] -> Result: value_1 -- from Replica
   [GET user:2] -> Result: value_2 -- from Replica
   [GET user:3] -> Result: value_3 -- from Replica
   [GET user:4] -> Result: value_4 -- from Replica

👋 Connection closed.

---

3 Master and 3 Replicas

Add here.

*/
