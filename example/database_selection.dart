import 'package:valkey_client/valkey_client.dart';

void main() async {
  print('🗄️ Starting Database Selection Example...');

  // Configure connection to use Database 1 (default is 0)
  final settings = ValkeyConnectionSettings(
    host: '127.0.0.1',
    port: 6379, // for standalone
    // port: 7002, // for cluster
    database: 1, // Select DB 1 automatically
    commandTimeout: Duration(seconds: 2),
  );

  final client = ValkeyClient.fromSettings(settings);

  try {
    await client.connect();

    // 1. Inspect Server Metadata
    if (client.metadata != null) {
      print('\n🔍 Server Metadata Discovered:');
      print('   - Software: ${client.metadata!.serverName}');
      print('   - Version:  ${client.metadata!.version}');
      print('   - Mode:     ${client.metadata!.mode.name}');
      print('   - Max DBs:  ${client.metadata!.maxDatabases}');
    }

    // 2. Write data to DB 1
    await client.set('app:config:mode', 'production');
    final value = await client.get('app:config:mode');
    print('\n✅ Data in DB 1: app:config:mode = $value');

    // 3. Verify Isolation (Conceptual):
    // Data written here won't be visible in DB 0.

  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await client.close();
  }
}


/*
EXPECTED OUTPUT
===============

🗄️ Starting Database Selection Example...

🔍 Server Metadata Discovered:
   - Software: valkey
   - Version:  9.0.0
   - Mode:     standalone
   - Max DBs:  16

✅ Data in DB 1: app:config:mode = production

---

🗄️ Starting Database Selection Example...

🔍 Server Metadata Discovered:
   - Software: valkey
   - Version:  9.0.0
   - Mode:     cluster
   - Max DBs:  1

✅ Data in DB 1: app:config:mode = production
*/
