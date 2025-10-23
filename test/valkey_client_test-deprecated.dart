import 'dart:io';

import 'package:test/test.dart';
import 'package:valkey_client/valkey_client.dart';

void main() {
  // ---
  // IMPORTANT: These tests require a LIVE Valkey server running on localhost:6379.
  //
  // Start one easily with Docker:
  // docker run -d --name valkey-test -p 6379:6379 valkey/valkey:latest
  //
  // These tests also assume that localhost:6380 (a different port) is NOT running.
  // ---

  group('ValkeyClient Connection', () {
    late ValkeyClient client;

    // setUp is called before each test.
    setUp(() {
      client = ValkeyClient();
    });

    // tearDown is called after each test.
    tearDown(() async {
      // Ensure the client connection is closed after each test
      // to avoid resource leaks.
      await client.close();
    });

    test('should connect and disconnect successfully when server is running',
        () async {
      // Act: Connect to the server.
      // Assert: The connect() Future should complete without throwing any errors.
      await expectLater(client.connect(), completes);
    });

    test('onConnected Future should complete after successful connection',
        () async {
      // Act: Start the connection but don't await the connect() call itself.
      client.connect();

      // Assert: The onConnected getter Future should complete.
      // This proves our Completer logic is working.
      await expectLater(client.onConnected, completes);
    });

    test('should throw a SocketException if connection fails', () async {
      // Act: Attempt to connect to a port where no server is running.
      final connectFuture = client.connect(port: 6380); // Non-standard port

      // Assert: The Future should complete with a SocketException.
      await expectLater(
        connectFuture,
        throwsA(isA<SocketException>()),
      );
    });

    test('should allow multiple calls to close() without error', () async {
      // Arrange
      await client.connect();

      // Act
      await client.close();

      // Assert: Calling close() again on an already closed client
      // should not throw an error.
      await expectLater(client.close(), completes);
    });
  });

  // We will add more groups here as we add features, e.g.:
  // group('ValkeyClient Commands - PING', () { ... });
  // group('ValkeyClient Commands - SET/GET', () { ... });
}
