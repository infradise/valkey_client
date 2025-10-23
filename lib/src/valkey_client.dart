import 'dart:io';
import 'dart:async';
import 'dart:typed_data'; // We will need this soon for parsing
import 'dart:convert'; // For UTF8 encoding
import 'dart:collection'; // A Queue to manage pending commands

import 'package:valkey_client/src/valkey_client_base.dart';

/// The main client implementation for communicating with a Valkey server.
class ValkeyClient implements ValkeyClientBase {
  Socket? _socket;
  StreamSubscription<Uint8List>? _subscription;

  // --- Configuration Storage ---
  final String _defaultHost;
  final int _defaultPort;
  final String? _defaultUsername;
  final String? _defaultPassword;

  String _lastHost = '127.0.0.1';
  int _lastPort = 6379;
  String? _lastUsername;
  String? _lastPassword;

  // --- Command/Response Queue ---
  /// A queue of Completers, each waiting for a response.
  final Queue<Completer<dynamic>> _responseQueue = Queue();

  /// A buffer to store incomplete data chunks from the socket.
  final BytesBuilder _buffer = BytesBuilder();
  // ------------------------------

  /// A Completer for the initial connection/auth handshake.
  Completer<void>? _connectionCompleter;

  // Internal state to manage the auth handshake
  bool _isAuthenticating = false;

  /// Creates a new Valkey client instance.
  ///
  /// [host], [port], [username], and [password] are the default
  /// connection parameters used when [connect] is called.
  ValkeyClient({
    String host = '127.0.0.1',
    int port = 6379,
    String? username,
    String? password,
  })  : _defaultHost = host,
        _defaultPort = port,
        _defaultUsername = username,
        _defaultPassword = password;
  // -----------------------------

  /// A Future that completes once the connection and authentication are successful.
  @override
  Future<void> get onConnected =>
      _connectionCompleter?.future ?? Future.error('Client not connected');

  @override
  Future<void> connect({
    String? host,
    int? port,
    String? username,
    String? password,
  }) async {
    // If already connecting or connected, return the existing future.
    if (_socket != null) {
      return onConnected;
    }

    // --- Use method args if provided, otherwise fallback to defaults ---
    _lastHost = host ?? _defaultHost;
    _lastPort = port ?? _defaultPort;
    _lastUsername = username ?? _defaultUsername;
    _lastPassword = password ?? _defaultPassword;
    // -----------------------------------------------------------------

    // Reset the completer for this new connection attempt
    _connectionCompleter = Completer();

    print('Connecting to $host:$port...');

    try {
      // 1. Attempt to connect the socket.
      _socket = await Socket.connect(_lastHost, _lastPort);

      print('✅ Successfully connected to $host:$port');

      // 2. Set up the socket stream listener.
      _subscription = _socket!.listen(
        // This is our mini-parser (AUTH only)
        // This is where we will parse the RESP3 data from the server.

        _handleSocketData, // Renamed to a generic handler
        onError: _handleSocketError,
        onDone: _handleSocketDone,
        // Automatically cancel the subscription on error.
        cancelOnError: true,
      );

      // --- AUTHENTICATION LOGIC ---
      if (_lastPassword != null) {
        _isAuthenticating = true;
        _sendAuthCommand(_lastPassword!, username: _lastUsername);
      } else {
        // Notify external listeners that the connection is ready.
        // No password, connection is immediately ready.
        _connectionCompleter!.complete();
      }
    } catch (e) {
      print('Failed to connect: $e');
      _cleanup();
      _connectionCompleter!.completeError(e); // Rethrow connection error
    }

    return onConnected;
  }

  // --- Core Data Handler ---

  /// This is now the main entry point for ALL data from the socket.
  void _handleSocketData(Uint8List data) {
    print('Raw data from server: ${String.fromCharCodes(data)}');
    _buffer.add(data);
    _processBuffer(); // Try to process the buffered data
  }

  /// This is our new "Proto-Parser"
  /// It tries to parse RESP Simple Strings (+OK, +PONG, -ERR) from the buffer.
  void _processBuffer() {
    // This is a *very simple* parser. It only looks for \r\n
    // We will make this much smarter in Chapter 2.2

    var bytes = _buffer.toBytes();
    var offset = 0;

    while (true) {
      // Find the next CRLF (\r\n)
      final crlfIndex = _findCRLF(bytes, offset);
      if (crlfIndex == -1) {
        // No complete message found, stop processing
        break;
      }

      // We found a complete message
      final lineBytes = bytes.sublist(offset, crlfIndex);
      final responseType = lineBytes[0]; // e.g., '+' or '-'
      final responseData = utf8.decode(lineBytes.sublist(1));

      // Move offset to the start of the next message
      offset = crlfIndex + 2; // +2 for \r\n

      // --- Handle the parsed message ---
      if (_isAuthenticating) {
        // This is the AUTH response
        _isAuthenticating = false;
        if (responseType == 43) {
          // '+' (OK)
          _connectionCompleter!.complete();
        } else {
          // '-' (ERR)
          _connectionCompleter!.completeError(
              Exception('Valkey authentication failed: $responseData'));
        }
      } else {
        // This is a response to a command (e.g., PING)
        if (_responseQueue.isEmpty) {
          // We got a response we didn't ask for (e.g., Pub/Sub message)
          // Ignore for now.
        } else {
          // Pop the oldest command completer and resolve it.
          final completer = _responseQueue.removeFirst();
          if (responseType == 43) {
            // '+' (Simple String)
            completer.complete(responseData);
          } else if (responseType == 45) {
            // '-' (Error)
            completer.completeError(Exception(responseData));
          } else {
            // We don't support Bulk Strings ($) or Arrays (*) yet!
            completer.completeError(Exception(
                'Unsupported RESP type: ${String.fromCharCode(responseType)}'));
          }
        }
      }
    }

    // Clear the buffer up to the processed offset
    if (offset > 0) {
      final remainingBytes = bytes.sublist(offset);
      _buffer.clear();
      _buffer.add(remainingBytes);
    }
  }

  /// Helper to find the first \r\n in a byte list
  int _findCRLF(Uint8List bytes, int start) {
    for (var i = start; i < bytes.length - 1; i++) {
      if (bytes[i] == 13 /* \r */ && bytes[i + 1] == 10 /* \n */) {
        return i;
      }
    }
    return -1;
  }

  // --- Public Command Methods ---

  /// Executes a raw command. (This will be our main internal method)
  /// Returns a Future that completes with the server's response.
  @override
  Future<dynamic> execute(List<String> command) async {
    // 1. Create a Completer and add it to the queue.
    final completer = Completer<dynamic>();
    _responseQueue.add(completer);

    // 2. Serialize the command to RESP Array format.
    final buffer = StringBuffer();
    buffer.write('*${command.length}\r\n');
    for (final arg in command) {
      final bytes = utf8.encode(arg);
      buffer.write('\$${bytes.length}\r\n');
      buffer.write('$arg\r\n');
    }

    // 3. Send to socket
    try {
      _socket?.write(buffer.toString());
    } catch (e) {
      // If write fails, remove the completer and throw
      _responseQueue.remove(completer);
      completer.completeError(e);
    }

    // 4. Return the Future
    return completer.future;
  }

  /// Our first *real* command: PING
  @override
  Future<String> ping([String? message]) async {
    final command = (message == null) ? ['PING'] : ['PING', message];
    final response = await execute(command);
    // Our simple parser will return "PONG" or the message.
    return response as String;
  }

  // --- Socket Lifecycle Handlers ---

  void _handleSocketError(Object error) {
    // print('Socket error: $error');
    _cleanup();
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.completeError(error);
    }
    // Fail all pending commands
    _failAllPendingCommands(error);
  }

  void _handleSocketDone() {
    // print('Socket closed by server.');
    _cleanup();
    final error = Exception('Connection closed unexpectedly.');
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      // Connection closed prematurely.
      _connectionCompleter!
          .completeError(error); // Connection closed before setup.
    }
    // Fail all pending commands
    _failAllPendingCommands(error);
  }

  void _failAllPendingCommands(Object error) {
    while (_responseQueue.isNotEmpty) {
      _responseQueue.removeFirst().completeError(error);
    }
  }

  /// Sends the AUTH command in RESP Array format.
  void _sendAuthCommand(String password, {String? username}) {
    List<String> command;
    if (username != null) {
      // RESP Array: *3\r\n$4\r\nAUTH\r\n$<user_len>\r\n<username>\r\n$<pass_len>\r\n<password>\r\n
      command = ['AUTH', username, password];
    } else {
      // RESP Array: *2\r\n$4\r\nAUTH\r\n$<pass_len>\r\n<password>\r\n
      command = ['AUTH', password];
    }

    // Build the RESP Array command
    final buffer = StringBuffer();
    buffer.write('*${command.length}\r\n'); // Number of arguments
    for (final arg in command) {
      final bytes = utf8.encode(arg);
      buffer.write('\$${bytes.length}\r\n'); // Argument length
      buffer.write('$arg\r\n'); // Argument value
    }

    // Send to socket
    _socket?.write(buffer.toString());
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _socket?.close();
    _cleanup();
    print('Connection closed by client.');
    // (No need to fail commands here, _handleSocketDone will do it)
  }

  /// Internal helper to clean up socket and subscription resources.
  void _cleanup() {
    _subscription?.cancel();
    _socket?.destroy(); // Ensure the socket is fully destroyed.
    _socket = null;
    _subscription = null;
    _buffer.clear();
  }
}
