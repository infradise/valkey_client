import 'dart:io';
import 'dart:async';
import 'dart:typed_data'; // We will need this soon for parsing
import 'dart:convert'; // For UTF8 encoding

/// Defines the base functionality for a Valkey client.
abstract class ValkeyClientBase {
  /// Connects and authenticates to the Valkey server.
  ///
  /// If [host], [port], [username], or [password] are provided,
  /// they will override the default values set in the constructor.
  Future<void> connect({
    String? host,
    int? port,
    String? username,
    String? password,
  });

  /// Closes the connection to the server.
  Future<void> close();
}

/// The main client implementation for communicating with a Valkey server.
class ValkeyClient implements ValkeyClientBase {
  Socket? _socket;
  StreamSubscription<Uint8List>? _subscription;

  // A Completer to let external callers await the connection AND auth.
  final Completer<void> _connectionCompleter = Completer();

  // Internal state to manage the auth handshake
  bool _isAuthenticating = false;

  // --- Configuration Storage ---
  // Store the default configuration from the constructor.
  final String _defaultHost;
  final int _defaultPort;
  final String? _defaultUsername;
  final String? _defaultPassword;

  // Store the last used config for potential reconnects
  String _lastHost = '127.0.0.1';
  int _lastPort = 6379;
  String? _lastUsername;
  String? _lastPassword;
  // -----------------------------

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
  Future<void> get onConnected => _connectionCompleter.future;

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

    print('Connecting to $host:$port...');

    try {
      // 1. Attempt to connect the socket.
      _socket = await Socket.connect(_lastHost, _lastPort);

      print('✅ Successfully connected to $host:$port');

      // 2. Set up the socket stream listener.
      _subscription = _socket!.listen(
        _handleAuthResponse, // This is our mini-parser for Chapter 1.5 (AUTH only)
        // (data) {
        //   // This is where we will parse the RESP3 data from the server.
        //   print('Raw data from server: ${String.fromCharCodes(data)}');
        //   
        //   _handleAuthResponse(data);
        // },
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
            // Connection closed prematurely.
            _connectionCompleter.completeError('Connection closed before setup.');
          }
        },
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
        _connectionCompleter.complete();
      }

    } catch (e) {
      print('Failed to connect: $e');
      _cleanup();
      _connectionCompleter.completeError(e); // Rethrow connection error
    }

    return onConnected;
  }

  /// Handles the response data *only* for the AUTH command.
  void _handleAuthResponse(Uint8List data) {
    if (!_isAuthenticating) {
      // This is data for Chapter 2 (PING, SET, etc.).
      _isAuthenticating = false;
      final response = utf8.decode(data); // Simple string conversion

      // Valkey/Redis Simple String reply for OK
      if (response.startsWith('+OK')) {
        _connectionCompleter.complete();
      } else {
        // Failed auth (e.g., -WRONGPASS or -ERR)
        _connectionCompleter.completeError(
          Exception('Valkey authentication failed: ${response.trim()}'),
        );
      }
    } else {
      // Data received *after* auth.
      print('Data (Post-Auth): ${utf8.decode(data)}');
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
  }

  /// Internal helper to clean up socket and subscription resources.
  void _cleanup() {
    _subscription?.cancel();
    _socket?.destroy(); // Ensure the socket is fully destroyed.
    _socket = null;
    _subscription = null;
  }
}