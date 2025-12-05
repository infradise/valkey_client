import 'package:valkey_client/redis_client.dart';

void main() async {
  // var config = RedisConnectionSettings(host: 'localhost', port: 6379);

  // var client = RedisClient(config);
  // final client = RedisClient(initialNodes: ['redis://localhost:6379']);
  // final client = RedisClient(connectionSettings: config);

// final initialNodes = [
//     RedisConnectionSettings(
//       host: '127.0.0.1',
//       port: 6379, // standalone: 6379, cluster: 7001
//       commandTimeout: Duration(seconds: 5), // Set timeout for all commands
//     ),
//     // You could add other seed nodes here if desired
//     // RedisConnectionSettings(host: '127.0.0.1', port: 7002),
//     // RedisConnectionSettings(host: '127.0.0.1', port: 7003),
//   ];

  // For cluster-mode:
  // If you try to connect a standalone server,
  //   you will get "ValkeyServerException(ERR): ERR This instance has cluster support disabled".
  // final client = RedisClusterClient(
  //   initialNodes,
  // );

  // For standalone-mode:
  final client = RedisClient();
  try {
    await client.connect(host: '127.0.0.1', port: 6379);

    await client.set('key', 'value');

    print(await client.get('key'));
  } catch (e) {
    print('❌ Failed: $e');
  } finally {
    await client.close();
  }
}
