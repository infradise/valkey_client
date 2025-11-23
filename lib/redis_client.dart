// /// This library provides a Redis-compatible interface.
// /// It allows users to use the client with familiar class names.
// library;

// import 'package:valkey_client/valkey_client.dart' as v;

// export 'package:valkey_client/valkey_client.dart'
//     show
//         ValkeyConnectionSettings, // RedisConnectionSettings
//         ValkeyException,
//         ValkeyConnectionException,
//         ValkeyPool;

// /// A fully compatible Redis client.
// /// This is a wrapper around [ValkeyClient] to provide a familiar interface for Redis users.
// class RedisClient extends v.ValkeyClient {

//   /// Creates a client for Redis.
//   RedisClient(super.connectionSettings);

//   // Add override here for Redis dedicated method or operations
// }

// class RedisConnectionSettings extends v.ValkeyConnectionSettings {
//   RedisConnectionSettings({
//     super.host,
//     super.port,
//     super.password,
//     // super.ssl,
//   });
// }

import 'package:valkey_client/valkey_client.dart';


typedef RedisClient = ValkeyClient;
typedef RedisConnectionSettings = ValkeyConnectionSettings;