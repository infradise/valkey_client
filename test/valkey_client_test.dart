import 'dart:io';

import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';
import 'package:stream_channel/stream_channel.dart'; // for StreamMatcher
import 'package:async/async.dart' show StreamQueue;

// This flag will be set by setUpAll
bool isServerRunning = false;
const noAuthHost = '127.0.0.1'; // or localhost
// Standard port for no-auth tests
const noAuthPort = 6379;
// Port that is guaranteed to be closed
const closedPort = 6380;

/// Helper function to check server status *before* tests are defined.
Future<bool> checkServerStatus(String host, int port) async {
  final client = ValkeyClient(host: host, port: port);
  try {
    await client.connect();
    await client.close();
    return true; // Server is running
  } catch (e) {
    return false; // Server is not running
  }
}

Future<void> main() async {
  // --- RUN THE CHECK *BEFORE* DEFINING TESTS ---
  final isServerRunning = await checkServerStatus(noAuthHost, noAuthPort);

  // Print the warning ONCE if the server is down.
  if (!isServerRunning) {
    print('=' * 70);
    print('⚠️  WARNING: Valkey server not running on $noAuthHost:$noAuthPort.');
    print('Skipping tests that require a live connection.');
    print('Please start the NO-AUTH server (e.g., Docker) to run all tests.');
    print('=' * 70);
  }

  group('ValkeyClient Connection (No Auth)', () {
    late ValkeyClient client;

    setUpAll(() async {
      if (isServerRunning) {
        client = ValkeyClient(host: noAuthHost, port: noAuthPort);
        await client.connect();

        // Clean the database before running command tests
        await client.execute(['FLUSHDB']);
      }
    });

    // setUp is called before each test.
    setUp(() {
      // Use the default port (6379)
      client = ValkeyClient(host: noAuthHost, port: noAuthPort);
    });

    // tearDown is called after each test.
    tearDown(() async {
      // Ensure the client connection is closed after each test
      // to avoid resource leaks.
      await client.close();
    });

    test('should connect successfully using connect() args', () async {
      final c = ValkeyClient(); // Create with defaults (127.0.0.1)
      // Connect using method args
      await expectLater(
          c.connect(host: noAuthHost, port: noAuthPort), completes);
    });

    test('should connect successfully using constructor args', () async {
      // client (from setUp) was created with constructor args
      await expectLater(client.connect(), completes);
    });

    test('onConnected Future should complete after successful connection',
        () async {
      // Act: Start the connection but don't await the connect() call itself.
      client.connect(); // Do not await
      await expectLater(client.onConnected, completes);
    });

    test('should allow multiple calls to close() without error', () async {
      await client.connect();
      await client.close();
      await expectLater(client.close(), completes);
    });
  },
      // Skip this entire group if the no-auth server is not running
      skip: !isServerRunning
          ? 'Valkey server not running on $noAuthHost:$noAuthPort'
          : false);

  group('ValkeyClient Connection (Failure Scenarios)', () {
    test('should throw a SocketException if connection fails', () async {
      // Act: Attempt to connect to a port where no server is running.
      final client = ValkeyClient(
          host: noAuthHost, port: closedPort); // Bad or Non-standard port

      // This test runs regardless of the server status
      final connectFuture = client.connect();

      await expectLater(
        connectFuture,
        throwsA(isA<SocketException>()),
      );
    });

    test(
        'should throw an Exception when providing auth to a server that does not require it',
        () async {
      // This test requires the NO-AUTH server to be running
      final client = ValkeyClient(
        host: noAuthHost,
        port: noAuthPort,
        password: 'any-password', // Provide a password
      );

      final connectFuture = client.connect();

      // The server will respond with an error (e.g., -ERR Client sent AUTH...)
      // which our client should throw as an Exception.
      await expectLater(
        connectFuture,
        throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
                'ERR AUTH'))), // Changed from 'Valkey authentication failed'
      );
    },
        skip: !isServerRunning
            ? 'Valkey server not running on $noAuthHost:$noAuthPort'
            : false);

    // NOTE: To test *successful* auth, we would need a separate
    // test environment running a password-protected server.
    // We can add that later.
  });

  // --- GROUP FOR COMMANDS ---
  group('ValkeyClient Commands', () {
    late ValkeyClient client;

    // Connect ONCE before all tests in this group
    setUpAll(() async {
      // This assumes the isServerRunning check from the main setUpAll has passed
      client = ValkeyClient(host: noAuthHost, port: noAuthPort);
      await client.connect();
    });

    // Close the connection ONCE after all tests in this group
    tearDownAll(() async {
      await client.close();
    });

    test('PING should return PONG', () async {
      final response = await client.ping();
      expect(response, 'PONG');
    });

    test('PING with message should return the message', () async {
      final response = await client.ping('Hello Valkey');
      expect(response, 'Hello Valkey');
    });

    test('SET should return OK', () async {
      final response = await client.set('test:key', 'test:value');
      expect(response, 'OK');
    });

    test('GET should retrieve the correct value after SET', () async {
      final key = 'test:key:get';
      await client.set(key, 'Hello World');

      final response = await client.get(key);
      expect(response, 'Hello World');
    });

    test('GET on a non-existent key should return null', () async {
      final response = await client.get('test:key:non_existent');
      expect(response, isNull);
    });

    test('MSET/MGET should set and get multiple values', () async {
      // Note: We don't have MSET yet, so we use multiple SETs
      await client.set('test:mget:1', 'hello');
      await client.set('test:mget:2', 'world');

      final response = await client.mget(['test:mget:1', 'test:mget:2']);

      // The response should be a List<String>
      expect(response, isA<List<String?>>());
      expect(response, ['hello', 'world']);
    });

    test('MGET should return null for non-existent keys', () async {
      await client.set('test:mget:exists', 'value');

      final response =
          await client.mget(['test:mget:exists', 'test:mget:does_not_exist']);

      // The response list should contain the value and null
      expect(response, ['value', null]);
    });

    // --- TESTS FOR v0.5.0 (Hashes) ---

    test('HSET should return 1 for a new field', () async {
      final response = await client.hset('test:hash', 'field1', 'value1');
      expect(response, 1);
    });

    test('HSET should return 0 for an updated field', () async {
      await client.hset('test:hash', 'field_to_update', 'initial_value');
      final response =
          await client.hset('test:hash', 'field_to_update', 'updated_value');
      expect(response, 0);
    });

    test('HGET should retrieve the correct value', () async {
      await client.hset('test:hash:get', 'field', 'hello');
      final response = await client.hget('test:hash:get', 'field');
      expect(response, 'hello');
    });

    test('HGET on a non-existent field should return null', () async {
      final response = await client.hget('test:hash:get', 'non_existent_field');
      expect(response, isNull);
    });

    test('HGETALL should return a Map of all fields and values', () async {
      final key = 'test:hash:all';
      await client.hset(key, 'name', 'Valkyrie');
      await client.hset(key, 'project', 'valkey_client');

      final response = await client.hgetall(key);

      expect(response, isA<Map<String, String>>());
      expect(response, {'name': 'Valkyrie', 'project': 'valkey_client'});
    });

    test('HGETALL on a non-existent key should return an empty Map', () async {
      final response = await client.hgetall('test:hash:non_existent');
      expect(response, isA<Map<String, String>>());
      expect(response, isEmpty);
    });

    // --- TESTS FOR v0.6.0 (Lists) ---

    test('LPUSH should return the new length of the list', () async {
      // Key is cleaned by FLUSHDB
      final response1 = await client.lpush('test:list', 'item1');
      expect(response1, 1);
      final response2 = await client.lpush('test:list', 'item2');
      expect(response2, 2);
    });

    test('RPUSH should return the new length of the list', () async {
      // Key is cleaned by FLUSHDB
      final response1 = await client.rpush('test:list:r', 'item1');
      expect(response1, 1);
      final response2 = await client.rpush('test:list:r', 'item2');
      expect(response2, 2);
    });

    test('LPOP should remove and return the first item', () async {
      final key = 'test:list:pop';
      await client.rpush(key, 'itemA'); // List: [itemA]
      await client.rpush(key, 'itemB'); // List: [itemA, itemB]

      final response = await client.lpop(key); // Pops itemA
      expect(response, 'itemA');

      final remaining = await client.lrange(key, 0, -1);
      expect(remaining, ['itemB']);
    });

    test('RPOP should remove and return the last item', () async {
      final key = 'test:list:rpop';
      await client.rpush(key, 'itemA'); // List: [itemA]
      await client.rpush(key, 'itemB'); // List: [itemA, itemB]

      final response = await client.rpop(key); // Pops itemB
      expect(response, 'itemB');

      final remaining = await client.lrange(key, 0, -1);
      expect(remaining, ['itemA']);
    });

    test('LPOP/RPOP on an empty key should return null', () async {
      final response = await client.lpop('test:list:empty');
      expect(response, isNull);
    });

    test('LRANGE should return the correct range', () async {
      final key = 'test:list:range';
      await client.rpush(key, 'one');
      await client.rpush(key, 'two');
      await client.rpush(key, 'three');

      // Get all items (0 to -1)
      final response = await client.lrange(key, 0, -1);
      expect(response, ['one', 'two', 'three']);

      // Get first two items
      final response2 = await client.lrange(key, 0, 1);
      expect(response2, ['one', 'two']);
    });

    // --- TESTS FOR v0.7.0 (Sets) ---

    test('SADD should return 1 for a new member', () async {
      final response = await client.sadd('test:set', 'member1');
      expect(response, 1);
    });

    test('SADD should return 0 for an existing member', () async {
      await client.sadd('test:set:exists', 'member1');
      final response = await client.sadd('test:set:exists', 'member1');
      expect(response, 0);
    });

    test('SREM should return 1 for a removed member', () async {
      await client.sadd('test:set:rem', 'member_to_remove');
      final response = await client.srem('test:set:rem', 'member_to_remove');
      expect(response, 1);
    });

    test('SREM should return 0 for a non-existent member', () async {
      final response = await client.srem('test:set:rem', 'non_existent');
      expect(response, 0);
    });

    test('SMEMBERS should return all members of the set', () async {
      final key = 'test:set:members';
      await client.sadd(key, 'apple');
      await client.sadd(key, 'banana');

      final response = await client.smembers(key);
      expect(response, isA<List<String?>>());
      // Sets are unordered, so check with containsAll
      expect(response, containsAll(['apple', 'banana']));
      expect(response.length, 2);
    });

    // --- TESTS FOR v0.7.0 (Sorted Sets) ---

    test('ZADD should return 1 for a new member', () async {
      final response = await client.zadd('test:zset', 10, 'player1');
      expect(response, 1);
    });

    test('ZADD should return 0 for an updated member', () async {
      await client.zadd('test:zset:update', 10, 'player1');
      final response =
          await client.zadd('test:zset:update', 20, 'player1'); // Update score
      expect(response, 0);
    });

    test('ZREM should return 1 for a removed member', () async {
      await client.zadd('test:zset:rem', 10, 'player_to_remove');
      final response = await client.zrem('test:zset:rem', 'player_to_remove');
      expect(response, 1);
    });

    test('ZRANGE should return members in score order', () async {
      final key = 'test:zset:range';
      await client.zadd(key, 100, 'player_c');
      await client.zadd(key, 50, 'player_a');
      await client.zadd(key, 75, 'player_b');

      // Get all members, lowest score first
      final response = await client.zrange(key, 0, -1);
      expect(response, ['player_a', 'player_b', 'player_c']);
    });

    // --- TESTS FOR v0.8.0 (Key Management) ---

    test('EXISTS should return 1 for an existing key', () async {
      await client.set('test:exists:key', 'value');
      final response = await client.exists('test:exists:key');
      expect(response, 1);
    });

    test('EXISTS should return 0 for a non-existent key', () async {
      final response = await client.exists('test:exists:non_existent');
      expect(response, 0);
    });

    test('DEL should return 1 for a deleted key', () async {
      await client.set('test:del:key', 'value');
      final response = await client.del('test:del:key');
      expect(response, 1);
      // Verify deletion
      final exists = await client.exists('test:del:key');
      expect(exists, 0);
    });

    test('DEL should return 0 for a non-existent key', () async {
      final response = await client.del('test:del:non_existent');
      expect(response, 0);
    });

    test('EXPIRE should set a timeout and return 1', () async {
      await client.set('test:expire:key', 'value');
      final response = await client.expire('test:expire:key', 10); // 10 seconds
      expect(response, 1);
    });

    test('TTL should return remaining time or specific values', () async {
      final key = 'test:ttl:key';
      // Test 1: Key exists, no expire
      await client.set(key, 'value');
      final ttl1 = await client.ttl(key);
      expect(ttl1, -1);

      // Test 2: Set expire
      await client.expire(key, 5); // 5 seconds
      final ttl2 = await client.ttl(key);
      expect(ttl2, greaterThan(0)); // Should be around 5
      expect(ttl2, lessThanOrEqualTo(5));

      // Test 3: Key does not exist
      final ttl3 = await client.ttl('test:ttl:non_existent');
      expect(ttl3, -2);
    });
  },
 
      // Skip this entire group if the no-auth server is not running
      skip: !isServerRunning
          ? 'Valkey server not running on $noAuthHost:$noAuthPort'
          : false);


  // --- NEW GROUP FOR PUB/SUB ---
  group('ValkeyClient Pub/Sub', () {
    late ValkeyClient subscriberClient;
    late ValkeyClient publisherClient;

    // Connect both clients ONCE before tests
    setUpAll(() async {
      if (isServerRunning) {
        subscriberClient = ValkeyClient(host: noAuthHost, port: noAuthPort);
        publisherClient = ValkeyClient(host: noAuthHost, port: noAuthPort);
        await Future.wait([
          subscriberClient.connect(),
          publisherClient.connect(),
        ]);
        // Clean DB
        await publisherClient.execute(['FLUSHDB']);
      }
    });

    // Close connections ONCE after tests
    tearDownAll(() async {
      if (isServerRunning) {
        await Future.wait([
          subscriberClient.close(),
          publisherClient.close(),
        ]);
      }
    });

    test('should receive messages on subscribed channel', () async {
      final channel = 'test:pubsub:channel1';
      final message1 = 'Hello from test 1';
      final message2 = 'Hello from test 2';

      // 1. Subscribe and get the stream
      final messageStream = subscriberClient.subscribe([channel]);

      // 2. Use StreamMatcher to expect messages
      // Use StreamQueue to consume events in order
      final queue = StreamQueue(messageStream);

      // Check the first message
      var receivedMessage = await queue.next;
      expect(receivedMessage, isA<ValkeyMessage>());
      expect(receivedMessage.channel, channel);
      expect(receivedMessage.message, message1);

      // Check the second message
      receivedMessage = await queue.next;
      expect(receivedMessage, isA<ValkeyMessage>());
      expect(receivedMessage.channel, channel);
      expect(receivedMessage.message, message2);

      // 3. Publish messages AFTER setting up the listener
      // Allow a brief moment for the subscription to activate on the server
      await Future.delayed(Duration(milliseconds: 100));
      final count1 = await publisherClient.publish(channel, message1);
      final count2 = await publisherClient.publish(channel, message2);

      // Expect at least one subscriber (our subscriberClient)
      expect(count1, greaterThanOrEqualTo(1));
      expect(count2, greaterThanOrEqualTo(1));

      // Clean up the stream queue
      await queue.cancel();

      // Note: We need to implement UNSUBSCRIBE to properly exit
      // the subscribed state for the client. For now, rely on tearDownAll.
    },
      // Give this test a bit more time due to async nature
      timeout: Timeout(Duration(seconds: 5))
    );

    test('publish should return number of receivers', () async {
      // No active subscribers on this channel yet
      final count = await publisherClient.publish('test:pubsub:no_subs', 'message');
      expect(count, 0); // Expect 0 subscribers
    });

  },

      // Skip the entire group if the server is down
      skip: !isServerRunning
          ? 'Valkey server not running on $noAuthHost:$noAuthPort'
          : false);

}
