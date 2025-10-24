import 'dart:io';

import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

// This flag will be set by setUpAll
bool isServerRunning = false;
// Standard port for no-auth tests
const noAuthPort = 6379;
// Port that is guaranteed to be closed
const closedPort = 6380;

Future<void> main() async {
  // ---
  // This setup runs ONCE before ANY tests.
  // It checks if the default NO-AUTH server is reachable.
  // ---
  setUpAll(() async {
    final client = ValkeyClient(port: noAuthPort);
    try {
      await client.connect();
      isServerRunning = true;
      await client.close();
    } catch (e) {
      isServerRunning = false;
    }

    if (!isServerRunning) {
      print('=' * 70);
      print('⚠️  WARNING: Valkey server not running on localhost:$noAuthPort.');
      print('Skipping tests that require a live connection.');
      print('Please start the NO-AUTH server (e.g., Docker) to run all tests.');
      print('=' * 70);
    }
  });

  group('ValkeyClient Connection (No Auth)', () {
    late ValkeyClient client;

    // setUp is called before each test.
    setUp(() {
      // Use the default port (6379)
      client = ValkeyClient(port: noAuthPort);
    });

    // tearDown is called after each test.
    tearDown(() async {
      // Ensure the client connection is closed after each test
      // to avoid resource leaks.
      await client.close();
    });

    test('should connect successfully using connect() args', () async {
      final c = ValkeyClient(); // Create with defaults
      // Connect using method args
      await expectLater(c.connect(port: noAuthPort), completes);
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
          ? 'Valkey server not running on localhost:$noAuthPort'
          : false);

  group('ValkeyClient Connection (Failure Scenarios)', () {
    test('should throw a SocketException if connection fails', () async {
      // Act: Attempt to connect to a port where no server is running.
      final client = ValkeyClient(port: closedPort); // Non-standard port

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
        port: noAuthPort,
        password: 'any-password', // Provide a password
      );

      final connectFuture = client.connect();

      // The server will respond with an error (e.g., -ERR Client sent AUTH...)
      // which our client should throw as an Exception.
      await expectLater(
        connectFuture,
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Valkey authentication failed'))),
      );
    },
        skip: !isServerRunning
            ? 'Valkey server not running on localhost:$noAuthPort'
            : false);

    // NOTE: To test *successful* auth, we would need a separate
    // test environment running a password-protected server.
    // We can add that later.
  });

  // --- NEW GROUP FOR COMMANDS ---
  group('ValkeyClient Commands', () {
    late ValkeyClient client;

    // Connect ONCE before all tests in this group
    setUpAll(() async {
      // This assumes the isServerRunning check from the main setUpAll has passed
      client = ValkeyClient(port: noAuthPort);
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
  },
      // Skip this entire group if the no-auth server is not running
      skip: !isServerRunning
          ? 'Valkey server not running on localhost:$noAuthPort'
          : false);
}
