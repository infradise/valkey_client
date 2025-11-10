import 'package:valkey_client/valkey_client.dart';

void main() async {
  // 1. Define the initial nodes to connect to.
  // The client only needs one node to discover the entire cluster.
  // We assume a cluster node is running on port 7001.
  final initialNodes = [
    ValkeyConnectionSettings(
      host: '127.0.0.1',
      port: 7001,
      commandTimeout: Duration(seconds: 5), // Set timeout for all commands
    ),
    // You could add other seed nodes here if desired
    // ValkeyConnectionSettings(host: '127.0.0.1', port: 7002),
    // ValkeyConnectionSettings(host: '127.0.0.1', port: 7003),
  ];

  // 2. Create the new ValkeyClusterClient
  final client = ValkeyClusterClient(initialNodes);

  try {
    // 3. Connect to the cluster.
    // This will fetch the topology (CLUSTER SLOTS) and set up
    // connection pools for each master node.
    print('Connecting to cluster...');
    await client.connect();
    print('✅ Cluster connected and slot map loaded.');

    // 4. Run commands.
    // The client will automatically route these commands to the correct node
    // based on the key's hash slot.
    print('\nRunning SET command for "key:A"...');
    final setResponse = await client.set('key:A', 'Hello from Cluster!');
    print('SET response: $setResponse');

    print('\nRunning GET command for "key:A"...');
    final getResponse = await client.get('key:A');
    print('GET response: $getResponse'); // Output: Hello from Cluster!

    print('\nRunning SET command for "key:B"...');
    await client.set('key:B', 'Valkey rocks!');
    print('SET response: OK');

    print('\nRunning GET command for "key:B"...');
    final getResponseB = await client.get('key:B');
    print('GET response: $getResponseB'); // Output: Valkey rocks!

    // Note: MGET is not supported in v1.3.0
    // await client.mget(['key:A', 'key:B']); // Throws UnimplementedError

  } on ValkeyConnectionException catch (e) {
    print('\n❌ Connection Failed: $e');
    print('Ensure a Valkey CLUSTER node is running.');
  } on ValkeyServerException catch (e) {
    print('\n❌ Server Error: $e');
  } on ValkeyClientException catch (e) {
    print('\n❌ Client Error: $e');
  } on UnimplementedError catch (e) {
    print('\n❌ Feature Not Implemented: $e');
  } catch (e) {
    print('\n❌ Unknown Error: $e');
  } finally {
    // 5. Close all cluster connections
    print('\nClosing all cluster connections...');
    await client.close();
  }
}