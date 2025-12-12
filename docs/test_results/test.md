```sh
dart test --exclude-tags example
```

Example:
```log
00:00 +14: test/valkey_client_sharded_test.dart: ValkeyClient Sharded Pub/Sub ssubscribe receives messages published via spublish
Subscribing to shard-channel:{1}...
Publishing to shard-channel:{1}...
Received message on shard-channel:{1}: Hello Sharding
00:00 +20: test/sharded_pubsub_test.dart: SPUBLISH should execute without error
SPUBLISH sent successfully. Receivers: 0
00:00 +50: test/valkey_cluster_sharded_test.dart: ValkeyClusterClient Sharded Pub/Sub ssubscribe receives messages from multiple shards (Scatter-Gather)
Cluster: Subscribing to [shard:channel:{a}, shard:channel:{b}, shard:channel:{c}]...
00:00 +53: test/valkey_cluster_sharded_test.dart: ValkeyClusterClient Sharded Pub/Sub ssubscribe receives messages from multiple shards (Scatter-Gather)
Cluster: Subscription READY.
Cluster: Publishing messages...
00:00 +54: test/valkey_cluster_sharded_test.dart: ValkeyClusterClient Sharded Pub/Sub ssubscribe receives messages from multiple shards (Scatter-Gather)
Cluster Received: [shard:channel:{a}] msg-a
00:00 +55: test/valkey_cluster_sharded_test.dart: ValkeyClusterClient Sharded Pub/Sub ssubscribe receives messages from multiple shards (Scatter-Gather)
Cluster Received: [shard:channel:{b}] msg-b
00:00 +56: test/valkey_cluster_sharded_test.dart: ValkeyClusterClient Sharded Pub/Sub ssubscribe receives messages from multiple shards (Scatter-Gather)
Cluster Received: [shard:channel:{c}] msg-c
✅ All messages received from multiple shards!
00:00 +59: test/valkey_client_test.dart: ValkeyClient Pub/Sub should receive messages on subscribed channel
TEST: Waiting for subscription ready...
TEST: Subscription ready!
TEST Publishing message 1...
TEST received: Hello from test 1
TEST Publishing message 2...
TEST received: Hello from test 2
TEST Waiting for message 1...
TEST Received message 1 OK
TEST Waiting for message 2...
TEST Received message 2 OK
00:00 +60: test/valkey_cluster_sharded_test.dart: ValkeyClusterClient Sharded Pub/Sub ssubscribe receives messages from multiple shards (Scatter-Gather)            
Cluster: Subscribing to [shard:channel:{a}, shard:channel:{b}, shard:channel:{c}]...
Cluster: Subscription READY.
Cluster: Publishing messages...
Cluster Received: [shard:channel:{a}] msg-a
Cluster Received: [shard:channel:{b}] msg-b
Cluster Received: [shard:channel:{c}] msg-c
✅ All messages received from multiple shards!
00:03 +80: All tests passed!
```