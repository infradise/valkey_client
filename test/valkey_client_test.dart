/*
 * Copyright 2025-2026 Infradise Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
// import 'dart:io';

import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';
// import 'package:stream_channel/stream_channel.dart'; // for StreamMatcher
// import 'package:async/async.dart' show StreamQueue;

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
  isServerRunning = await checkServerStatus(noAuthHost, noAuthPort);

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
      await client.connect(); // Do not await
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
    test('should throw a ValkeyConnectionException if connection fails',
        () async {
      // Act: Attempt to connect to a port where no server is running.
      final client = ValkeyClient(
          // host: noAuthHost,
          port: closedPort); // Bad or Non-standard port

      // This test runs regardless of the server status
      final connectFuture = client.connect();

      await expectLater(
        connectFuture,
        throwsA(isA<ValkeyConnectionException>()),
      );
    });

    test(
        'should throw a ValkeyConnectionException when providing auth to a '
        'server that does not require it', () async {
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
        throwsA(isA<ValkeyConnectionException>().having(
            // (e) => e.toString(),
            (e) => e.message,
            'message',
            contains('Authentication failed'))),
        // ERR AUTH, Changed from 'Valkey authentication failed'
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
      // This assumes the isServerRunning check from the main setUpAll has
      // passed
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
      const key = 'test:key:get';
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
      const key = 'test:hash:all';
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
      const key = 'test:list:pop';
      await client.rpush(key, 'itemA'); // List: [itemA]
      await client.rpush(key, 'itemB'); // List: [itemA, itemB]

      final response = await client.lpop(key); // Pops itemA
      expect(response, 'itemA');

      final remaining = await client.lrange(key, 0, -1);
      expect(remaining, ['itemB']);
    });

    test('RPOP should remove and return the last item', () async {
      const key = 'test:list:rpop';
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
      const key = 'test:list:range';
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
      const key = 'test:set:members';
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
      const key = 'test:zset:range';
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
      const key = 'test:ttl:key';
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

    test('should throw ValkeyServerException on WRONGTYPE operation', () async {
      // 1. Set a normal string key
      const key = 'test:wrongtype:key';
      await client.set(key, 'i am a string');

      // 2. Try to use a Hash command (HSET) on the String key
      final hsetFuture = client.hset(key, 'field', 'value');

      // 3. Expect the specific WRONGTYPE error from the server
      await expectLater(
          hsetFuture,
          throwsA(isA<ValkeyServerException>()
              .having((e) => e.code, 'code', 'WRONGTYPE')));

      // 4. Clean up the key
      await client.del(key);
    });
  },

      // Skip this entire group if the no-auth server is not running
      skip: !isServerRunning
          ? 'Valkey server not running on $noAuthHost:$noAuthPort'
          : false);

  // --- GROUP FOR PUB/SUB ---
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
      const channel = 'test:pubsub:channel1';
      const message1 = 'Hello from test 1';
      const message2 = 'Hello from test 2';

      // 1. Subscribe and get the Subscription object
      final sub = subscriberClient
          .subscribe([channel]); // Returns Subscription{messages, ready}

      // --- NEW: Wait for the subscription to be ready ---
      print('TEST: Waiting for subscription ready...');
      await sub.ready.timeout(const Duration(seconds: 2), onTimeout: () {
        throw TimeoutException(
            'Timed out waiting for subscription confirmation');
      });
      print('TEST: Subscription ready!');
      // ---------------------------------------------------

      // 2. Use Completers to wait for messages AFTER subscription is ready
      final completer1 = Completer<ValkeyMessage>();
      final completer2 = Completer<ValkeyMessage>();
      var messageCount = 0;

      final subscriptionListener = sub.messages.listen(// Listen to sub.messages
          (message) {
        print('TEST received: ${message.message}');
        messageCount++;
        if (messageCount == 1 && !completer1.isCompleted) {
          completer1.complete(message);
        } else if (messageCount == 2 && !completer2.isCompleted) {
          completer2.complete(message);
        }
      }, onError: (Object e, StackTrace? s) {
        print('TEST stream error: $e');
        if (!completer1.isCompleted) completer1.completeError(e, s);
        if (!completer2.isCompleted) completer2.completeError(e, s);
      }, onDone: () {
        print('TEST stream done.');
        if (!completer1.isCompleted) {
          completer1.completeError('Stream closed prematurely');
        }
        if (!completer2.isCompleted) {
          completer2.completeError('Stream closed prematurely');
        }
      });

      // 3. Publish messages AFTER awaiting sub.ready
      print('TEST Publishing message 1...');
      final count1 = await publisherClient.publish(channel, message1);
      print('TEST Publishing message 2...');
      final count2 = await publisherClient.publish(channel, message2);

      // Expect at least one subscriber
      expect(count1, greaterThanOrEqualTo(1));
      expect(count2, greaterThanOrEqualTo(1));

      // 4. Wait for messages using Completers
      print('TEST Waiting for message 1...');
      final receivedMessage1 = await completer1.future
          .timeout(const Duration(seconds: 2), onTimeout: () {
        print('TEST Timeout waiting for message 1');
        throw TimeoutException('Timeout waiting for message 1');
      });
      expect(receivedMessage1, isA<ValkeyMessage>());
      expect(receivedMessage1.channel, channel);
      expect(receivedMessage1.message, message1);
      print('TEST Received message 1 OK');

      print('TEST Waiting for message 2...');
      final receivedMessage2 = await completer2.future
          .timeout(const Duration(seconds: 2), onTimeout: () {
        print('TEST Timeout waiting for message 2');
        throw TimeoutException('Timeout waiting for message 2');
      });
      expect(receivedMessage2, isA<ValkeyMessage>());
      expect(receivedMessage2.channel, channel);
      expect(receivedMessage2.message, message2);
      print('TEST Received message 2 OK');

      // Clean up the stream listener
      await subscriptionListener.cancel();

      await subscriberClient.unsubscribe([channel]);
    },
        // Give this test a bit more time due to async nature
        timeout: const Timeout(Duration(seconds: 10)));

    test('publish should return number of receivers', () async {
      // No active subscribers on this channel yet
      final count =
          await publisherClient.publish('test:pubsub:no_subs', 'message');
      expect(count, 0); // Expect 0 subscribers
    });

    // --- TESTS FOR v0.10.0 (Advanced Pub/Sub) ---

    test('unsubscribe should stop receiving messages', () async {
      const channel = 'test:pubsub:unsub';
      const message1 = 'message before unsub';
      const message2 = 'message after unsub';
      var msgCompleter = Completer<ValkeyMessage>();

      // 1. Subscribe
      final sub = subscriberClient.subscribe([channel]);
      await sub.ready; // Wait for confirmation

      // Listen
      final listener = sub.messages.listen((msg) {
        if (!msgCompleter.isCompleted) {
          msgCompleter.complete(msg);
        }
      });

      // 2. Publish message 1 (should be received)
      await Future<void>.delayed(
          const Duration(milliseconds: 100)); // Allow listener setup
      await publisherClient.publish(channel, message1);
      final receivedMsg1 =
          await msgCompleter.future.timeout(const Duration(seconds: 2));
      expect(receivedMsg1.message, message1);

      // 3. Unsubscribe
      await subscriberClient.unsubscribe([channel]);
      // Need a small delay for server to process unsubscribe
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // 4. Publish message 2 (should NOT be received)
      msgCompleter = Completer(); // Reset completer
      await publisherClient.publish(channel, message2);

      // Verify message 2 is NOT received by checking for timeout
      await expectLater(
        msgCompleter.future
            .timeout(const Duration(seconds: 1)), // Shorter timeout
        throwsA(isA<TimeoutException>()),
      );

      await listener.cancel();
    });

    test('psubscribe should receive messages matching pattern', () async {
      const pattern = 'test:psub:*';
      const channel1 = 'test:psub:channelA';
      const channel2 = 'test:psub:channelB';
      const message1 = 'Msg A';
      const message2 = 'Msg B';
      final msg1Completer = Completer<ValkeyMessage>();
      final msg2Completer = Completer<ValkeyMessage>();
      var receivedCount = 0;

      // 1. PSubscribe
      final sub = subscriberClient.psubscribe([pattern]);
      await sub.ready; // Wait for confirmation

      // Listen
      final listener = sub.messages.listen((msg) {
        receivedCount++;
        if (msg.channel == channel1 && !msg1Completer.isCompleted) {
          msg1Completer.complete(msg);
        } else if (msg.channel == channel2 && !msg2Completer.isCompleted) {
          msg2Completer.complete(msg);
        }
      });

      // 2. Publish to matching channels AFTER ready
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await publisherClient.publish(channel1, message1);
      await publisherClient.publish(channel2, message2);

      // 3. Wait and verify messages
      final receivedMsg1 =
          await msg1Completer.future.timeout(const Duration(seconds: 2));
      expect(receivedMsg1.pattern, pattern);
      expect(receivedMsg1.channel, channel1);
      expect(receivedMsg1.message, message1);

      final receivedMsg2 =
          await msg2Completer.future.timeout(const Duration(seconds: 2));
      expect(receivedMsg2.pattern, pattern);
      expect(receivedMsg2.channel, channel2);
      expect(receivedMsg2.message, message2);

      expect(receivedCount, 2); // Ensure only 2 messages received

      await listener.cancel();
      // Need punsubscribe to clean up properly
      await subscriberClient.punsubscribe([pattern]);
      await Future<void>.delayed(
          const Duration(milliseconds: 100)); // Allow punsubscribe processing
    });

    test('punsubscribe should stop receiving pattern messages', () async {
      const pattern = 'test:punsub:*';
      const channel = 'test:punsub:channel';
      const message1 = 'Msg before punsub';
      const message2 = 'Msg after punsub';
      var msgCompleter = Completer<ValkeyMessage>();

      // 1. PSubscribe
      final sub = subscriberClient.psubscribe([pattern]);
      await sub.ready;

      // Listen
      final listener = sub.messages.listen((msg) {
        if (!msgCompleter.isCompleted) msgCompleter.complete(msg);
      });
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 2. Publish message 1 (should be received)
      await publisherClient.publish(channel, message1);
      final receivedMsg1 =
          await msgCompleter.future.timeout(const Duration(seconds: 2));
      expect(receivedMsg1.message, message1);

      // 3. PUnsubscribe
      await subscriberClient.punsubscribe([pattern]);
      await Future<void>.delayed(
          const Duration(milliseconds: 200)); // Allow server processing

      // 4. Publish message 2 (should NOT be received)
      msgCompleter = Completer();
      await publisherClient.publish(channel, message2);
      await expectLater(
        msgCompleter.future.timeout(const Duration(seconds: 1)),
        throwsA(isA<TimeoutException>()),
      );

      await listener.cancel();
    });
  },

      // Skip the entire group if the server is down
      skip: !isServerRunning
          ? 'Valkey server not running on $noAuthHost:$noAuthPort'
          : false);

  // --- GROUP FOR v0.11.0 (Transactions) ---
  group('ValkeyClient Transactions', () {
    late ValkeyClient client;

    // Connect and clean DB before each test in this group
    setUp(() async {
      client = ValkeyClient(host: noAuthHost, port: noAuthPort);
      await client.connect();
      await client.execute(['FLUSHDB']);
      // Ensure we are not in a transaction state from a failed test
      try {
        await client.discard();
      } catch (e) {
        // Ignore errors (e.g., "ERR DISCARD without MULTI")
      }
    });

    tearDown(() async {
      await client.close();
    });
    test('exec() returns null when transaction succeeds with no results',
        () async {
      // Start a transaction
      await client.multi();
      // Do not add any commands
      final execResponse = await client.exec();

      // Since there are no commands, exec() should return null
      expect(execResponse, <List>[]);
    });

    test('exec() throws ValkeyServerException when transaction is aborted',
        () async {
      await client.multi();

      // Intentionally send an invalid command to cause transaction failure
      // (missing value argument for SET)
      // 1) Queue invalid command and assert its immediate error
      final enqueueFuture = client
          .execute(['SET', 'key']); // Missing argument → error // wrong arity
      await expectLater(
        enqueueFuture,
        throwsA(isA<ValkeyServerException>().having(
          // (e) => e.toString(),
          (e) => e.message,
          'message',
          contains('wrong number of arguments'),
        )),
      );

      // 2) Now verify that EXEC reports the aborted transaction
      final execFuture = client.exec(); // Do not await here!
      await expectLater(
        execFuture,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('EXECABORT'),
        )),
      );
    });

    test('MULTI/EXEC successfully executes a simple transaction', () async {
      // 1. Start transaction
      final multiResponse = await client.multi();
      expect(multiResponse, 'OK');

      // 2. Queue commands
      // Note: The futures complete with 'QUEUED'
      final setFuture = client.set('tx:key1', 'tx:value1');
      final incrFuture = client.execute(['INCR', 'tx:counter']);

      // Verify they are queued
      await expectLater(setFuture, completion('QUEUED'));
      await expectLater(incrFuture, completion('QUEUED'));

      // 3. Execute transaction
      final execResponse = await client.exec();

      // 4. Verify EXEC response (array of replies)
      expect(execResponse, isA<List<dynamic>>());
      expect(execResponse, [
        'OK', // Response for SET
        1, // Response for INCR
      ]);

      // 5. Verify data in DB
      final value = await client.get('tx:key1');
      expect(value, 'tx:value1');
    });

    test('DISCARD cancels a transaction', () async {
      // 1. Start transaction
      await client.multi();

      // 2. Queue commands
      await client.set('tx:key2', 'value_to_discard');

      // 3. Discard transaction
      final discardResponse = await client.discard();
      expect(discardResponse, 'OK');

      // 4. Verify data was NOT set
      final value = await client.get('tx:key2');
      expect(value, isNull);
    });

    test(
        'exec() throws ValkeyServerException if transaction was aborted '
        '(e.g., by syntax error)', () async {
      await client.multi();

      // Send a command with a syntax error
      // Note: execute() returns a Future<Exception> here, not 'QUEUED'
      final badCommandFuture = client.execute(['INVALID_COMMAND', 'arg']);

      // Server replies with an error immediately for syntax errors
      await expectLater(
          badCommandFuture,
          throwsA(isA<ValkeyServerException>().having(
              // (e) => e.toString(),
              (e) => e.message,
              'message',
              contains('ERR unknown command'))));

      // Subsequent valid command (will be queued by server, but TX fails)
      await client.set('tx:key3', 'value_to_fail'); // This will return 'QUEUED'

      // Expect an EXECABORT Exception, not null
      final execFuture = client.exec();
      await expectLater(
          execFuture,
          throwsA(isA<Exception>()
              .having((e) => e.toString(), 'message', contains('EXECABORT'))));

      // Verify data was not set
      final value = await client.get('tx:key3');
      expect(value, isNull);
    });

    test('calling EXEC without MULTI throws', () async {
      await expectLater(
          client.exec(),
          throwsA(isA<Exception>().having(
              (e) => e.toString(), 'message', contains('without MULTI'))));
    });

    test('calling DISCARD without MULTI throws', () async {
      await expectLater(
          client.discard(),
          throwsA(isA<Exception>().having(
              (e) => e.toString(), 'message', contains('without MULTI'))));
    });
  },
      // Skip this entire group if the server is down
      skip: !isServerRunning
          ? 'Valkey server not running on $noAuthHost:$noAuthPort'
          : false);

  // --- GROUP FOR v0.12.0 (Pub/Sub Introspection) ---
  group('ValkeyClient Pub/Sub Introspection', () {
    late ValkeyClient client; // Client for sending commands
    late ValkeyClient subClient; // Client to create subscriptions
    StreamSubscription? subListener; // To manage the subscription

    setUp(() async {
      // Create two clients for these tests
      client = ValkeyClient(host: noAuthHost, port: noAuthPort);
      subClient = ValkeyClient(host: noAuthHost, port: noAuthPort);
      await Future.wait([client.connect(), subClient.connect()]);
      await client.execute(['FLUSHDB']);
    });

    tearDown(() async {
      // Ensure listener is cancelled and clients are closed
      await subListener?.cancel();
      await Future.wait([client.close(), subClient.close()]);
    });

    test('pubsubChannels lists active channels', () async {
      const channel1 = 'inspect:channel:1';
      const channel2 = 'inspect:channel:2';

      // 1. No channels active
      var channels = await client.pubsubChannels();
      expect(channels, isEmpty);

      // 2. Subscribe with subClient
      final sub = subClient.subscribe([channel1, channel2]);
      await sub.ready; // Wait for confirmation
      subListener = sub.messages.listen(null); // Attach listener

      // 3. Give server a moment to register subscriptions
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 4. Check active channels
      channels = await client.pubsubChannels('inspect:channel:*');
      expect(channels, containsAll([channel1, channel2]));
      expect(channels.length, 2);
    });

    test('pubsubNumSub returns subscriber counts', () async {
      const channel1 = 'inspect:numsub:1';
      const channel2 = 'inspect:numsub:2';

      // 1. Subscribe with subClient
      final sub = subClient.subscribe([channel1, channel2]);
      await sub.ready;
      subListener = sub.messages.listen(null);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 2. Check counts
      final counts =
          await client.pubsubNumSub([channel1, channel2, 'non_existent']);

      expect(counts, isA<Map<String, int>>());
      expect(counts[channel1], 1); // subClient is 1 subscriber
      expect(counts[channel2], 1);
      expect(counts['non_existent'], 0);

      await subClient.unsubscribe([channel1, channel2]);
    });

    test('pubsubNumPat returns pattern subscription count', () async {
      const pattern1 = 'inspect:pat:*';
      const pattern2 = 'inspect:another:*';

      // 1. No patterns active
      var numPat = await client.pubsubNumPat();
      expect(numPat, 0);

      // 2. PSubscribe with subClient
      final sub = subClient.psubscribe([pattern1, pattern2]);
      await sub.ready;
      subListener = sub.messages.listen(null);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 3. Check pattern count
      numPat = await client.pubsubNumPat();
      expect(numPat, 2);

      await client.punsubscribe([pattern1, pattern2]);
    });
  },
      // Skip this entire group if the server is down
      skip: !isServerRunning
          ? 'Valkey server not running on $noAuthHost:$noAuthPort'
          : false);
}
