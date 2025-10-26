import 'dart:io';
import 'dart:async';
import 'dart:typed_data'; // We will need this soon for parsing
import 'dart:convert'; // For UTF8 encoding
import 'dart:collection'; // A Queue to manage pending commands

import 'package:valkey_client/src/valkey_client_base.dart';

/// Internal helper class to read bytes from the buffer.
/// This makes parsing much cleaner.
class _BufferReader {
  final Uint8List _bytes;
  int _offset = 0;

  _BufferReader(this._bytes);

  int get remainingLength => _bytes.length - _offset;
  bool get isDone => _offset >= _bytes.length;

  /// Consumes bytes from the buffer up to the current offset.
  Uint8List consume() => _bytes.sublist(_offset);

  /// Reads a single byte (prefix)
  int readByte() => _bytes[_offset++];

  /// Reads a line (until \r\n) and returns it as a string.
  /// Returns null if no \r\n is found.
  String? readLine() {
    final crlfIndex = _findCRLF(_bytes, _offset);
    if (crlfIndex == -1) return null;

    final lineBytes = _bytes.sublist(_offset, crlfIndex);
    _offset = crlfIndex + 2; // Consume \r\n
    return utf8.decode(lineBytes);
  }

  /// Reads a specific number of bytes.
  /// Returns null if not enough bytes are available.
  Uint8List? readBytes(int length) {
    if (remainingLength < length) return null;

    final data = _bytes.sublist(_offset, _offset + length);
    _offset += length;
    return data;
  }

  /// Reads 2 bytes for the final \r\n
  /// Returns false if not enough bytes or not \r\n
  bool readFinalCRLF() {
    if (remainingLength < 2) return false;
    if (_bytes[_offset] == 13 && _bytes[_offset + 1] == 10) {
      _offset += 2;
      return true;
    }
    return false; // Should throw an error here ideally
  }

  int _findCRLF(Uint8List bytes, int start) {
    for (var i = start; i < bytes.length - 1; i++) {
      if (bytes[i] == 13 /* \r */ && bytes[i + 1] == 10 /* \n */) {
        return i;
      }
    }
    return -1;
  }
}

/// Helper exception for when the buffer doesn't have enough data.
class _IncompleteDataException implements Exception {}

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

    print('Connecting to $_lastHost:$_lastPort...');

    try {
      // 1. Attempt to connect the socket.
      _socket = await Socket.connect(_lastHost, _lastPort);

      print('✅ Successfully connected to $_lastHost:$_lastPort');

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

  /// This is the new parser entry point.
  /// It loops and tries to parse one full response at a time.
  void _processBuffer() {
    while (true) {
      if (_responseQueue.isEmpty && !_isAuthenticating) {
        // If we are not waiting for auth AND not waiting for commands,
        // then we can stop processing.
        break;
      }

      final reader = _BufferReader(_buffer.toBytes());

      try {
        // --- THIS IS THE NEW RECURSIVE PARSER ---
        final response = _parseResponse(reader);
        // ----------------------------------------

        // If we got here, we successfully parsed one full message.
        _resolveNextCommand(response);

        // Consume the processed bytes from the buffer
        _buffer.clear();
        _buffer.add(reader.consume());
      } on _IncompleteDataException {
        // Not enough data in the buffer to parse a full response.
        // Stop looping and wait for more socket data.
        break;
      } catch (e) {
        // A real parsing error (e.g., unknown prefix)
        _resolveNextCommand(e, isError: true);
        // Clear buffer to avoid infinite error loop
        _buffer.clear();
      }
    }
  }

  /// The core recursive RESP parser.
  dynamic _parseResponse(_BufferReader reader) {
    if (reader.isDone) throw _IncompleteDataException();

    final responseType = reader.readByte();

    switch (responseType) {
      // '+' (Simple String)
      case 43: // '+'
        final line = reader.readLine();
        if (line == null) throw _IncompleteDataException();
        return line;

      // '-' (Error)
      case 45: // '-'
        final line = reader.readLine();
        if (line == null) throw _IncompleteDataException();
        throw Exception(line); // Throw errors as exceptions

      // '$' (Bulk String)
      case 36: // '$'
        final line = reader.readLine();
        if (line == null) throw _IncompleteDataException();

        final dataLength = int.parse(line);
        if (dataLength == -1) {
          return null; // Null response
        }

        final data = reader.readBytes(dataLength);
        if (data == null) throw _IncompleteDataException();

        if (!reader.readFinalCRLF()) throw _IncompleteDataException();

        return utf8.decode(data);

      // '*' (Array)
      case 42: // '*'
        final line = reader.readLine();
        if (line == null) throw _IncompleteDataException();

        final arrayLength = int.parse(line);
        if (arrayLength == -1) {
          return null; // Null array
        }

        final list = <dynamic>[];
        for (var i = 0; i < arrayLength; i++) {
          // --- RECURSION ---
          // Parse each item in the array
          final item = _parseResponse(reader);
          list.add(item);
        }
        return list;

      // ':' (Integer)
      case 58: // ':'
        final line = reader.readLine();
        if (line == null) throw _IncompleteDataException();
        return int.parse(line);

      default:
        throw Exception(
            'Unknown RESP prefix type: ${String.fromCharCode(responseType)}');
    }
  }

  /// Helper to resolve the next command in the queue.
  void _resolveNextCommand(dynamic response, {bool isError = false}) {
    if (_isAuthenticating) {
      // This is the AUTH response
      _isAuthenticating = false;
      if (isError) {
        _connectionCompleter!.completeError(response);
      } else {
        _connectionCompleter!.complete();
      }
    } else {
      if (_responseQueue.isEmpty) return; // Should not happen, but safe guard

      final completer = _responseQueue.removeFirst();
      if (isError) {
        completer.completeError(response);
      } else {
        completer.complete(response);
      }
    }
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

  // --- COMMANDS ---

  // --- PING (v0.2.0) ---

  @override
  Future<String> ping([String? message]) async {
    final command = (message == null) ? ['PING'] : ['PING', message];
    final response = await execute(command);
    // Our simple parser will return "PONG" or the message.
    return response as String;
  }

  // --- SET/GET (v0.3.0) ---

  @override
  Future<String?> get(String key) async {
    final response = await execute(['GET', key]);
    // The parser will return a String or null.
    return response as String?;
  }

  @override
  Future<String> set(String key, String value) async {
    final response = await execute(['SET', key, value]);
    // SET returns "+OK"
    return response as String;
  }

  // --- MGET (v0.4.0) ---

  @override
  Future<List<String?>> mget(List<String> keys) async {
    final command = ['MGET', ...keys];
    // The parser will return List<dynamic> containing String?
    final response = await execute(command) as List<dynamic>;
    // Cast to the correct type
    return response.cast<String?>();
  }

  // --- HASH (v0.5.0) ---

  @override
  Future<String?> hget(String key, String field) async {
    final response = await execute(['HGET', key, field]);
    // Returns a Bulk String ($) or Null ($-1)
    return response as String?;
  }

  @override
  Future<int> hset(String key, String field, String value) async {
    final response = await execute(['HSET', key, field, value]);
    // Returns an Integer (:)
    return response as int;
  }

  @override
  Future<Map<String, String>> hgetall(String key) async {
    // HGETALL returns a flat array: ['field1', 'value1', 'field2', 'value2']
    final response = await execute(['HGETALL', key]) as List<dynamic>;

    // Convert the flat list into a Map
    final map = <String, String>{};
    for (var i = 0; i < response.length; i += 2) {
      // We know the structure is [String, String, String, String, ...]
      map[response[i] as String] = response[i + 1] as String;
    }
    return map;
  }

  // --- LIST (v0.6.0) ---

  @override
  Future<int> lpush(String key, String value) async {
    // LPUSH returns an Integer (:)
    final response = await execute(['LPUSH', key, value]);
    return response as int;
  }

  @override
  Future<int> rpush(String key, String value) async {
    // RPUSH returns an Integer (:)
    final response = await execute(['RPUSH', key, value]);
    return response as int;
  }

  @override
  Future<String?> lpop(String key) async {
    // LPOP returns a Bulk String ($) or Null ($-1)
    final response = await execute(['LPOP', key]);
    return response as String?;
  }

  @override
  Future<String?> rpop(String key) async {
    // RPOP returns a Bulk String ($) or Null ($-1)
    final response = await execute(['RPOP', key]);
    return response as String?;
  }

  @override
  Future<List<String?>> lrange(String key, int start, int stop) async {
    // LRANGE returns an Array (*)
    final response =
        await execute(['LRANGE', key, start.toString(), stop.toString()]);
    return (response as List<dynamic>).cast<String?>();
  }

  // --- SET (v0.7.0) ---

  @override
  Future<int> sadd(String key, String member) async {
    // SADD returns an Integer (:)
    final response = await execute(['SADD', key, member]);
    return response as int;
  }

  @override
  Future<int> srem(String key, String member) async {
    // SREM returns an Integer (:)
    final response = await execute(['SREM', key, member]);
    return response as int;
  }

  @override
  Future<List<String?>> smembers(String key) async {
    // SMEMBERS returns an Array (*) of Bulk Strings ($)
    final response = await execute(['SMEMBERS', key]);
    return (response as List<dynamic>).cast<String?>();
  }

  // --- SORTED SET (v0.7.0) ---

  @override
  Future<int> zadd(String key, double score, String member) async {
    // ZADD returns an Integer (:)
    final response = await execute(['ZADD', key, score.toString(), member]);
    return response as int;
  }

  @override
  Future<int> zrem(String key, String member) async {
    // ZREM returns an Integer (:)
    final response = await execute(['ZREM', key, member]);
    return response as int;
  }

  @override
  Future<List<String?>> zrange(String key, int start, int stop) async {
    // ZRANGE returns an Array (*) of Bulk Strings ($)
    final response =
        await execute(['ZRANGE', key, start.toString(), stop.toString()]);
    return (response as List<dynamic>).cast<String?>();
  }

  // --- KEY MANAGEMENT (v0.8.0) ---

  @override
  Future<int> del(String key) async {
    // DEL returns an Integer (:)
    final response = await execute(['DEL', key]);
    return response as int;
  }

  @override
  Future<int> exists(String key) async {
    // EXISTS returns an Integer (:)
    final response = await execute(['EXISTS', key]);
    return response as int;
  }

  @override
  Future<int> expire(String key, int seconds) async {
    // EXPIRE returns an Integer (:)
    final response = await execute(['EXPIRE', key, seconds.toString()]);
    return response as int;
  }

  @override
  Future<int> ttl(String key) async {
    // TTL returns an Integer (:)
    final response = await execute(['TTL', key]);
    return response as int;
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
