import 'dart:io';
import 'dart:async';
import 'dart:typed_data'; // We will need this soon for parsing

/// Defines the base functionality for a Valkey client.
abstract class ValkeyClientBase {
  /// Connects to the Valkey server.
  Future<void> connect({String host = '127.0.0.1', int port = 6379});

  /// Closes the connection to the server.
  Future<void> close();
}

/// The main client implementation for communicating with a Valkey server.
class ValkeyClient implements ValkeyClientBase {
  Socket? _socket;
  StreamSubscription<Uint8List>? _subscription;

  // A Completer to let external callers await the connection setup.
  final Completer<void> _connectionCompleter = Completer();

  /// A Future that completes once the connection is successfully established.
  Future<void> get onConnected => _connectionCompleter.future;

  @override
  Future<void> connect({String host = '127.0.0.1', int port = 6379}) async {
    // If already connecting or connected, return the existing future.
    if (_socket != null) {
      return onConnected;
    }

    print('Connecting to $host:$port...');

    try {
      // 1. Attempt to connect the socket.
      _socket = await Socket.connect(host, port);

      print('✅ Successfully connected to $host:$port');

      // 2. Set up the socket stream listener.
      _subscription = _socket!.listen(
        (data) {
          // Chapter 2: This is where we will parse the RESP3 data from the server.
          print('Raw data from server: ${String.fromCharCodes(data)}');
        },
        onError: (error) {
          print('Socket error: $error');
          _cleanup();
          if (!_connectionCompleter.isCompleted) {
            _connectionCompleter.completeError(error);
          }
        },
        onDone: () {
          print('Socket closed by server.');
          _cleanup();
          if (!_connectionCompleter.isCompleted) {
            _connectionCompleter.completeError('Connection closed before setup.');
          }
        },
        // Automatically cancel the subscription on error.
        cancelOnError: true,
      );

      // Notify external listeners that the connection is ready.
      _connectionCompleter.complete();

    } catch (e) {
      print('Failed to connect: $e');
      _cleanup();
      _connectionCompleter.completeError(e);
    }

    return onConnected;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _socket?.close();
    _cleanup();
    print('Connection closed by client.');
  }

  /// Internal helper to clean up socket and subscription resources.
  void _cleanup() {
    _subscription?.cancel();
    _socket?.destroy(); // Ensure the socket is fully destroyed.
    _socket = null;
    _subscription = null;
  }
}