import 'package:valkey_client/redis_client.dart';

void main() async {
  var config = RedisConnectionSettings(host: 'localhost', port: 6379);

  // var client = RedisClient(config);
  // final client = RedisClient(initialNodes: ['redis://localhost:6379']);
  final client = RedisClient(connectionSettings: config);

  await client.connect();
  await client.set('key', 'value');

  await client.get('key');
}