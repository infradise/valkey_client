```sh
dart run example/valkey_client_example.dart
```

```log
========================================
Running Example with Constructor Config (fixedClient)
========================================
✅ Connection successful!

--- PING ---
Sending: PING 'Hello'
Received: Hello

--- SET/GET ---
Sending: SET greeting 'Hello, Valkey!'
Received: OK
Sending: GET greeting
Received: Hello, Valkey!

--- MGET (Array Parsing) ---
Sending: MGET greeting non_existent_key
Received: [Hello, Valkey!, null]

--- HASH (Map/Object) ---
Sending: HSET user:1 name 'Valkyrie'
Received (1=new, 0=update): 1
Sending: HSET user:1 project 'valkey_client'
Sending: HGET user:1 name
Received: Valkyrie
Sending: HGETALL user:1
Received Map: {name: Valkyrie, project: valkey_client}

--- LIST (Queue/Stack) ---
Sending: LPUSH mylist 'item1'
Sending: LPUSH mylist 'item2'
Received list length: 2
Sending: LRANGE mylist 0 -1
Received list: [item2, item1]
Sending: RPOP mylist
Received popped item: item1

--- SET (Unique Tags) / SORTED SET (Leaderboard) ---
Sending: SADD users:1:tags 'dart'
Sending: SADD users:1:tags 'valkey'
Sending: SMEMBERS users:1:tags
Received tags (unordered): [dart, valkey]
Sending: ZADD leaderboard 100 'PlayerOne'
Sending: ZADD leaderboard 150 'PlayerTwo'
Sending: ZRANGE leaderboard 0 -1
Received leaderboard (score low to high): [PlayerOne, PlayerTwo]

--- KEY MANAGEMENT (Expiration & Deletion) ---
Sending: EXPIRE greeting 10
Received (1=set, 0=not set): 1
Sending: TTL greeting
Received TTL (seconds, -1=no expire, -2=not exist): 10
Sending: DEL mylist
Received (number of keys deleted): 1
Sending: EXISTS mylist
Received (1=exists, 0=not exist): 0

--- TRANSACTIONS (Atomic Operations) ---
Sending: MULTI
Queueing: SET tx:1 'hello'
Queueing: INCR tx:counter
Awaited SET response: QUEUED
Awaited INCR response: QUEUED
Sending: EXEC
Received EXEC results: [OK, 1]
Sending: MULTI... SET... DISCARD
Value of tx:2 (should be null): null

Closing connection...



========================================
Running Example with Method Config (flexibleClient)
========================================
✅ Connection successful!

--- PING ---
Sending: PING 'Hello'
Received: Hello

--- SET/GET ---
Sending: SET greeting 'Hello, Valkey!'
Received: OK
Sending: GET greeting
Received: Hello, Valkey!

--- MGET (Array Parsing) ---
Sending: MGET greeting non_existent_key
Received: [Hello, Valkey!, null]

--- HASH (Map/Object) ---
Sending: HSET user:1 name 'Valkyrie'
Received (1=new, 0=update): 0
Sending: HSET user:1 project 'valkey_client'
Sending: HGET user:1 name
Received: Valkyrie
Sending: HGETALL user:1
Received Map: {name: Valkyrie, project: valkey_client}

--- LIST (Queue/Stack) ---
Sending: LPUSH mylist 'item1'
Sending: LPUSH mylist 'item2'
Received list length: 2
Sending: LRANGE mylist 0 -1
Received list: [item2, item1]
Sending: RPOP mylist
Received popped item: item1

--- SET (Unique Tags) / SORTED SET (Leaderboard) ---
Sending: SADD users:1:tags 'dart'
Sending: SADD users:1:tags 'valkey'
Sending: SMEMBERS users:1:tags
Received tags (unordered): [dart, valkey]
Sending: ZADD leaderboard 100 'PlayerOne'
Sending: ZADD leaderboard 150 'PlayerTwo'
Sending: ZRANGE leaderboard 0 -1
Received leaderboard (score low to high): [PlayerOne, PlayerTwo]

--- KEY MANAGEMENT (Expiration & Deletion) ---
Sending: EXPIRE greeting 10
Received (1=set, 0=not set): 1
Sending: TTL greeting
Received TTL (seconds, -1=no expire, -2=not exist): 10
Sending: DEL mylist
Received (number of keys deleted): 1
Sending: EXISTS mylist
Received (1=exists, 0=not exist): 0

--- TRANSACTIONS (Atomic Operations) ---
Sending: MULTI
Queueing: SET tx:1 'hello'
Queueing: INCR tx:counter
Awaited SET response: QUEUED
Awaited INCR response: QUEUED
Sending: EXEC
Received EXEC results: [OK, 2]
Sending: MULTI... SET... DISCARD
Value of tx:2 (should be null): null

Closing connection...



========================================
Running Pub/Sub Example
========================================
✅ Subscriber and Publisher connected!

Subscribing to channel: news:updates
Waiting for subscription confirmation...
Subscription confirmed!

Sending: PUBLISH news:updates 'First update!'
📬 Received: First update! (from channel: news:updates)
Sending: PUBLISH news:updates 'Second update!'
📬 Received: Second update! (from channel: news:updates)

Closing connections (will stop subscription)...
Pub/Sub clients closed.



========================================
Running Advanced Pub/Sub Example (Pattern Subscription)
========================================
✅ Subscriber and Publisher connected!

PSubscribing to pattern: log:*
Waiting for psubscribe confirmation...
PSubscription confirmed!

Sending: PUBLISH log:info 'Application started'
Sending: PUBLISH log:error 'Critical error occurred!'
📬 Received: Application started (Pattern: log:*, Channel: log:info)
📬 Received: Critical error occurred! (Pattern: log:*, Channel: log:error)

PUnsubscribing from pattern: log:*
ℹ️ Subscription stream closed.
Sending: PUBLISH log:info 'This message should NOT be received'
Advanced Pub/Sub clients closed.

--- PUBSUB INTROSPECTION (Admin/Info) ---



========================================
Running Pub/Sub Introspection Example
========================================
✅ Admin and Subscriber clients connected!
Sending: PUBSUB CHANNELS 'channel:*'
Received active channels: [channel:inspect]
Sending: PUBSUB NUMSUB 'channel:inspect'
Received subscriber count: {channel:inspect: 1}
Sending: PUBSUB NUMPAT
Received pattern subscription count: 1
Introspection clients closed.
```