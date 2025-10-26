import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert'; // For UTF8 encoding
import 'dart:collection'; // A Queue to manage pending commands

// Import the base class AND the new ValkeyMessage
import 'package:valkey_client/src/valkey_client_base.dart';
// Re-export ValkeyMessage from the main library file
export 'package:valkey_client/src/valkey_client_base.dart' show ValkeyMessage;

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
    if (crlfIndex == -1) return null; // Incomplete line

    final lineBytes = _bytes.sublist(_offset, crlfIndex);
    _offset = crlfIndex + 2; // Consume \r\n
    return utf8.decode(lineBytes);
  }

  /// Reads a specific number of bytes.
  /// Returns null if not enough bytes are available.
  Uint8List? readBytes(int length) {
    if (length < 0) {
      throw Exception('Invalid RESP length: $length'); // Added check
    }
    if (remainingLength < length) return null; // Not enough bytes

    final data = _bytes.sublist(_offset, _offset + length);
    _offset += length;
    return data;
  }

  /// Reads 2 bytes for the final \r\n
  /// Returns false if not enough bytes or not \r\n
  bool readFinalCRLF() {
    if (remainingLength < 2) return false; // Not enough bytes
    if (_bytes[_offset] == 13 && _bytes[_offset + 1] == 10) {
      _offset += 2;
      return true;
    }
    // If it's not CRLF, throw an error because RESP requires it after bulk strings
    throw Exception(
        'Expected CRLF after bulk string data, but got different bytes.');
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
class _IncompleteDataException implements Exception {
  final String message;
  _IncompleteDataException([this.message = 'Incomplete data in buffer']);
  @override
  String toString() => message;
}

/// The main client implementation for communicating with a Valkey server.
class ValkeyClient implements ValkeyClientBase {
  Socket? _socket;
  StreamSubscription<Uint8List>? _subscription;

  // Configuration Storage
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

  // Pub/Sub State
  // --- Fields for Pub/Sub ---
  /// Controller to broadcast incoming pub/sub messages.
  StreamController<ValkeyMessage>? _pubSubController;

  /// Flag to indicate if the client is currently in subscribed mode.
  bool _isSubscribed = false;

  /// Set of channels currently subscribed to.
  final Set<String> _subscribedChannels = {};
  // ------------------------------
  /// Completer for the 'ready' future of the current subscription.
  Completer<void>? _subscribeReadyCompleter;

  /// Number of channels we expect confirmation for.
  int _expectedSubscribeConfirmations = 0;

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
      _connectionCompleter?.future ??
      Future.error('Client not connected or connection attempt failed.');

  @override
  Future<void> connect({
    String? host,
    int? port,
    String? username,
    String? password,
  }) async {
    // Prevent multiple concurrent connection attempts
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      return onConnected;
    }
    // If already connecting or connected, return the existing future.
    // If already connected successfully, return immediately
    if (_socket != null &&
        _connectionCompleter != null &&
        _connectionCompleter!.isCompleted) {
      // Check if the completed future was successful
      bool wasSuccessful =
          await onConnected.then((_) => true, onError: (_) => false);
      if (wasSuccessful) return onConnected;
      // If the future completed with an error, allow reconnect attempt
      await close(); // Ensure cleanup before reconnect
    }

    // --- Use method args if provided, otherwise fallback to defaults ---
    _lastHost = host ?? _defaultHost;
    _lastPort = port ?? _defaultPort;
    _lastUsername = username ?? _defaultUsername;
    _lastPassword = password ?? _defaultPassword;
    // -----------------------------------------------------------------

    // Reset the completer for this new connection attempt
    _connectionCompleter = Completer();
    // Reset states for a fresh connection
    _isAuthenticating = false;
    _isSubscribed = false;
    _subscribedChannels.clear();
    _buffer.clear();
    _responseQueue.clear();
    // Close existing pub/sub controller if any
    _resetPubSubState();

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
        cancelOnError: true, // Automatically cancel the subscription on error.
      );
      print('[STREAM LOG] Subscription CREATED/LISTENED.');

      // --- AUTHENTICATION LOGIC ---
      if (_lastPassword != null) {
        _isAuthenticating = true;
        _sendAuthCommand(_lastPassword!, username: _lastUsername);
      } else {
        // Notify external listeners that the connection is ready.
        // No password, connection is immediately ready.
        // No auth needed, connection is ready
        if (!_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete();
        }
      }
    } catch (e, s) {
      print('Failed to connect: $e');
      _cleanup(); // Clean up socket if connection fails
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError(e, s); // Rethrow connection error
      }
    }

    return onConnected;
  }

  // --- Core Data Handler & Parser ---

  /// This is now the main entry point for ALL data from the socket.
  void _handleSocketData(Uint8List data) {
    print('Raw data from server: ${String.fromCharCodes(data)}');
    // print('[DEBUG 1] _handleSocketData received: ${data.length} bytes');
    // try { print('[DEBUG 1.1] Data as string:\n${utf8.decode(data).replaceAll('\r', '\\r').replaceAll('\n', '\\n\n')}'); } catch (_) {}
    _buffer.add(data);
    _processBuffer(); // Try to process the buffered data
  }

  /// This is the new parser entry point.
  /// It loops and tries to parse one full response at a time.
  ///
  /// Processes the buffer, parsing messages and routing them.
  void _processBuffer() {
    // print('[DEBUG 2] _processBuffer entered. Buffer size: ${_buffer.length}, Queue size: ${_responseQueue.length}, Subscribed: $_isSubscribed, Authenticating: $_isAuthenticating');
    while (_buffer.isNotEmpty) {
      final reader = _BufferReader(_buffer.toBytes());
      final initialOffset = reader._offset; // Track if we consumed anything

      try {
        // Attempt to parse ONE full response from the current buffer state
        // print('[DEBUG 3] Attempting _parseResponse... (Buffer start: ${_buffer.toBytes().take(20).join(',')})');
        final response =
            _parseResponse(reader); // Might throw _IncompleteDataException

        // print('[DEBUG 4] _parseResponse SUCCEEDED. Type: ${response.runtimeType}, Consumed: ${reader._offset - initialOffset} bytes');
        // if (response is List) { print('[DEBUG 4.1] Parsed Response (List): ${response.map((e) => e?.toString() ?? 'null').join(', ')}'); } else { print('[DEBUG 4.1] Parsed Response: $response'); }

        // --- Handle Push Messages (Pub/Sub) ---
        // 1. Is it a Pub/Sub push message?
        if (_isPubSubPushMessage(response)) {
          // print('[DEBUG 5.1] Handling as PubSub Push Message...');
          _handlePubSubMessage(response as List<dynamic>);
        }

        // --- Handle Regular Command Responses ---
        // 2. Is it the response to the initial AUTH command?
        else if (_isAuthenticating) {
          // print('[DEBUG 5.2] Handling as AUTH Response...');
          _resolveNextCommand(response); // Completes _connectionCompleter
        }
        // 3. Is it a response to a command we sent via execute()?
        else if (_responseQueue.isNotEmpty) {
          // print('[DEBUG 5.3] Handling as Command Response (Queue has ${_responseQueue.length})...');
          _resolveNextCommand(response); // Completes command completer
        }
        // 4. Otherwise, it's unexpected data.
        else {
          print(
              'Warning: Discarding unexpected message when queue is empty: $response');
          // print('[DEBUG 5.4] Handling as Unexpected Message (Queue empty, not auth, not push)...');
          // Discarding for now
        }

        // Consume the bytes for the successfully parsed message
        final remainingBytes = reader.consume();
        _buffer.clear();
        _buffer.add(remainingBytes);

        // If we didn't consume any bytes (e.g., incomplete data), stop looping

        // print('[DEBUG 5.5] Buffer consumed. Remaining size: ${_buffer.length}');

        // Defensive check: If parser succeeded but didn't consume bytes, break.
        if (reader._offset == initialOffset) {
          print(
              'CRITICAL WARNING: Parser completed but did not advance. Breaking loop to prevent stall.');
          break;
        }
      } on _IncompleteDataException {
        // Not enough data in the buffer to parse a full response.
        // Stop looping and wait for more socket data.

        // print('[DEBUG 6] IncompleteDataException. Breaking loop, need more data.');
        break; // Exit the while loop and wait for next _handleSocketData
      } catch (e, s) {
        // print('[DEBUG 7] Catch block error during parsing/handling: $e');
        // print('[DEBUG 7.1] Stacktrace: $s');

        // If subscribed mode error, maybe close stream?
        // Try to report error to the correct place
        if (_isSubscribed &&
            _pubSubController != null &&
            !_pubSubController!.isClosed) {
          _pubSubController!.addError(e, s);
          _resetPubSubState(); // Reset on error // Exit subscribed mode on error
        } else if (_isAuthenticating) {
          _resolveNextCommand(e,
              isError: true, stackTrace: s); // Fail connection
        } else if (_responseQueue.isNotEmpty) {
          _resolveNextCommand(e, isError: true, stackTrace: s); // Fail command
        }
        // Clear buffer to avoid infinite error loop
        _buffer.clear(); // Clear potentially corrupted buffer
        break; // Stop processing on error
      }
    } // end while
    // print('[DEBUG 8] _processBuffer finished this round. Buffer size: ${_buffer.length}');
  }

  /// Checks if a parsed RESP Array is a Pub/Sub push message.
  /// e.g., ['message', 'channel_name', 'payload']
  /// e.g., ['subscribe', 'channel_name', 1] (confirmation)
  bool _isPubSubPushMessage(dynamic response) {
    if (response is List && response.isNotEmpty && response[0] is String) {
      final type = response[0] as String;
      // Check for known push types (adjust as needed)
      return type == 'message' ||
          type == 'subscribe' ||
          type == 'unsubscribe'; // Add pmessage later

      // TODO: Add pmessage, psubscribe, punsubscribe later
    }
    return false;
  }

  /// Handles incoming Pub/Sub push messages (after parsing).
  void _handlePubSubMessage(List<dynamic> messageArray) {
    final type = messageArray[0] as String;
    // print('[DEBUG 9] _handlePubSubMessage received type: $type, Data: ${messageArray.skip(1).join(', ')}');

    if (type == 'message' && messageArray.length == 3) {
      final channel = messageArray[1] as String;
      final message = messageArray[2]
          as String?; // Allow null message? Redis usually sends empty string
      // print('[DEBUG 10] Adding message to StreamController for channel $channel...');
      if (_pubSubController != null && !_pubSubController!.isClosed) {
        _pubSubController!.add(
            ValkeyMessage(channel, message ?? '')); // Handle potential null
      } else {
        // print('[DEBUG 10.1] StreamController is null or closed, cannot add message.');
      }
    } else if (type == 'subscribe' && messageArray.length == 3) {
      // Handle the initial subscription confirmation
      final channel = messageArray[1]
          as String?; // Can be null on multi-subscribe? Check RESP spec
      final count = messageArray[2]; // Should be int

      // print('[DEBUG 11] Handling subscribe confirmation for ${channel ?? 'unknown channel'}. Count: $count');
      if (channel != null && count is int) {
        if (!_isSubscribed && count > 0) {
          // print('[DEBUG 11.1] Setting _isSubscribed = true');
          _isSubscribed = true; // Set state upon first confirmation
        }
        _subscribedChannels.add(channel);
        // Completer is handled in _resolveNextCommand

        // --- FIX: Check if all expected channels are confirmed ---
        // Decrement expected count (or check if _subscribedChannels.length reaches expected)
        _expectedSubscribeConfirmations--;
        // print('[DEBUG 11.3] Subscription confirmed for $channel. Remaining confirmations needed: $_expectedSubscribeConfirmations');

        // Complete the 'ready' future only when all confirmations are received
        if (_expectedSubscribeConfirmations <=
                0 && // Should be exactly 0 ideally
            _subscribeReadyCompleter != null &&
            !_subscribeReadyCompleter!.isCompleted) {
          print(
              '[DEBUG 11.4] All subscribe confirmations received. Completing ready future.');
          _subscribeReadyCompleter!.complete();
        }
        // --- DO NOT complete the command completer here ---
        // --- DO NOT add this confirmation to _pubSubController ---
      } else {
        // print('[DEBUG 11.2] Invalid subscribe confirmation format: $messageArray');
      }
    } else if (type == 'unsubscribe' /* ...or other types... */) {
      // Handle unsubscribe confirmations etc. later
      // print('[DEBUG 9.1] Unhandled push message type: $type');
    }
  }

  /// The core recursive RESP parser.
  dynamic _parseResponse(_BufferReader reader) {
    // print('[DEBUG P.1] _parseResponse entered. Offset: ${reader._offset}');
    if (reader.isDone) {
      throw _IncompleteDataException('Cannot parse, buffer empty');
    }

    final responseType = reader.readByte();
    // print('[DEBUG P.2] Response type prefix: ${String.fromCharCode(responseType)} ($responseType)');

    try {
      dynamic result;
      switch (responseType) {
        case 43: // '+' Simple String
          final line = reader.readLine();
          if (line == null) {
            throw _IncompleteDataException('Incomplete simple string');
          }
          result = line;
          break;
        case 45: // '-' Error
          final line = reader.readLine();
          if (line == null) {
            throw _IncompleteDataException('Incomplete error string');
          }
          // RETURN the error string instead of throwing immediately
          // The caller (_processBuffer) will decide how to handle it
          result = Exception(line); // Return as Exception
          break;
        case 36: // '$' Bulk String
          final line = reader.readLine();
          if (line == null) {
            throw _IncompleteDataException('Incomplete bulk string length');
          }
          final dataLength = int.parse(line);
          if (dataLength == -1) {
            result = null; // Null response
          } else {
            final data = reader.readBytes(dataLength);
            if (data == null) {
              throw _IncompleteDataException('Incomplete bulk string data');
            }
            if (!reader.readFinalCRLF()) {
              throw _IncompleteDataException(
                  'Missing CRLF after bulk string data');
            }
            result = utf8.decode(data);
          }
          break;
        case 42: // '*' Array
          final line = reader.readLine();
          if (line == null) {
            throw _IncompleteDataException('Incomplete array length');
          }
          final arrayLength = int.parse(line);
          if (arrayLength == -1) {
            result = null; // Null array
          } else {
            final list = <dynamic>[];
            for (var i = 0; i < arrayLength; i++) {
              // print('[DEBUG P.3] Parsing array element $i/$arrayLength...');
              // Parse each item in the array
              final item = _parseResponse(reader); // Recursive call
              list.add(item);
            }
            result = list;
          }
          break;
        case 58: // ':' Integer
          final line = reader.readLine();
          if (line == null) {
            throw _IncompleteDataException('Incomplete integer');
          }
          result = int.parse(line);
          break;
        default:
          // Instead of throwing, return an exception object
          result = Exception(
              'Unknown RESP prefix type: ${String.fromCharCode(responseType)} ($responseType)');
      }
      // print('[DEBUG P.4] _parseResponse SUCCESS. Offset: ${reader._offset}, Result type: ${result.runtimeType}');
      return result;
    } catch (e) {
      // If parsing itself fails (e.g., bad integer format), return exception
      // return e;

      // print('[DEBUG P.5] _parseResponse FAILED. Offset: ${reader._offset}, Error: $e');
      rethrow; // Rethrow to be caught by _processBuffer
    }
  }

  /// Helper to resolve the next command in the queue.

  /// Resolves the next command, now checks if response is an Exception.
  /// Resolves the next command completer in the queue.
  void _resolveNextCommand(dynamic response,
      {bool isError = false /* deprecated */, StackTrace? stackTrace}) {
    // print('[DEBUG R.1] _resolveNextCommand called. IsError(arg): $isError, ResponseType: ${response.runtimeType}');

    // Determine if the response itself is an error
    final bool responseIsError = response is Exception;
    final dynamic result = response;

    if (_isAuthenticating) {
      // print('[DEBUG R.2] Resolving AUTH completer.');
      // This is the AUTH response
      _isAuthenticating = false;
      if (responseIsError) {
        _connectionCompleter!.completeError(result, stackTrace);
      } else {
        _connectionCompleter!.complete();
      }
    } else {
      if (_responseQueue.isEmpty) {
        // Safety check
        // print('[DEBUG R.3] Warning: _resolveNextCommand called but queue is empty.');
        return; // Should not happen, (but safe guard)
      }

      final completer = _responseQueue.removeFirst();
      // print('[DEBUG R.4] Resolving command completer. Queue left: ${_responseQueue.length}');

      if (completer.isCompleted) return; // Already completed

      // print('[DEBUG R.4] Resolving command completer. Queue left: ${_responseQueue.length}');

      // Normal command completion/error
      if (responseIsError) {
        completer.completeError(result, stackTrace);
      } else {
        completer.complete(result);
      }
    }
  }

  // --- Public Command Methods ---

  /// Executes a raw command. (This will be our main internal method)
  /// Returns a Future that completes with the server's response.
  @override
  Future<dynamic> execute(List<String> command) async {
    // --- Check if in subscribed mode ---
    // Prevent most commands in subscribed mode
    if (_isSubscribed) {
      final cmd = command.isNotEmpty ? command[0].toUpperCase() : '';
      // Allow only specific commands in subscribed mode
      const allowedCommands = {
        'UNSUBSCRIBE',
        'PUNSUBSCRIBE',
        'PING',
        'QUIT'
      }; // Allowed when subscribed
      // Removed PSUBSCRIBE/SUBSCRIBE for now
      if (!allowedCommands.contains(cmd)) {
        return Future.error(Exception(
            'Cannot execute command $cmd while subscribed. Only UNSUBSCRIBE, PUNSUBSCRIBE, PING, QUIT are allowed.'));
      }
    }
    // ---------------------------------

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
      if (_socket == null) {
        throw Exception('Client not connected.');
      }
      // Ensure connection/auth is complete before sending commands (unless it's AUTH itself)
      if (command.isNotEmpty && command[0].toUpperCase() != 'AUTH') {
        await onConnected; // Wait if connection/auth is still in progress
      }
      _socket!.write(buffer.toString());
    } catch (e, s) {
      // If write fails, remove the completer and throw
      // If write fails or onConnected fails, remove completer and complete with error
      if (_responseQueue.contains(completer)) {
        _responseQueue.remove(completer);
      }
      // Avoid completing if already completed
      if (!completer.isCompleted) {
        completer.completeError(e, s);
      }
    }

    // 4. Return the Future

    return completer.future;
  }

  // --- COMMANDS ---

  // --- PING (v0.2.0) ---

  @override
  Future<String> ping([String? message]) async {
    final command = (message == null) ? ['PING'] : ['PING', message];
    // PING response can be Simple String or Bulk String
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
    if (keys.isEmpty) return []; // Avoid sending empty MGET
    final command = ['MGET', ...keys];
    // The parser will return List<dynamic> containing String?
    final response =
        await execute(command) as List<dynamic>?; // Can return null array
    // Cast to the correct type
    return response?.cast<String?>() ??
        List<String?>.filled(keys.length, null); // Match return type
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
    final response = await execute(['HGETALL', key])
        as List<dynamic>?; // Can return null array
    if (response == null || response.isEmpty) return {};

    // Convert the flat list into a Map
    final map = <String, String>{};
    for (var i = 0; i < response.length; i += 2) {
      // We know the structure is [String, String, String, String, ...]
      // Assume server returns strings for fields/values
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
    // LRANGE can return null array if key doesn't exist
    return (response as List<dynamic>?)?.cast<String?>() ?? [];
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
    // SMEMBERS can return null array if key doesn't exist
    return (response as List<dynamic>?)?.cast<String?>() ?? [];
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
    // ZRANGE can return null array if key doesn't exist
    return (response as List<dynamic>?)?.cast<String?>() ?? [];
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

  // --- PUB/SUB COMMANDS (v0.9.0 / v0.9.1) ---

  @override
  Future<int> publish(String channel, String message) async {
    // PUBLISH returns an Integer (:) - number of clients received
    final response = await execute(['PUBLISH', channel, message]);
    return response as int;
  }

  @override
  Subscription subscribe(List<String> channels) {
    if (_isSubscribed) {
      // Cannot call subscribe again while already subscribed (use PSUBSCRIBE?)
      // For now, just return the existing stream or throw an error.
      throw Exception(
          'Client is already in subscribed mode. Create a new client instance.');
    }
    // Ensure channels list is not empty
    if (channels.isEmpty) {
      throw ArgumentError('Channel list cannot be empty for SUBSCRIBE.');
    }

    if (_pubSubController == null || _pubSubController!.isClosed) {
      _pubSubController = StreamController<ValkeyMessage>.broadcast();
    }

    _subscribedChannels.clear(); // Reset channel list for this subscription
    // --- NEW: Initialize ready completer ---
    _subscribeReadyCompleter = Completer<void>();
    _expectedSubscribeConfirmations = channels.length;
    // ------------------------------------

    // Send the command, handle errors, but don't await the Future from execute() here.
    execute(['SUBSCRIBE', ...channels]).catchError((e, s) {
      // If the command itself fails (e.g., network error before confirmation)
      if (_subscribeReadyCompleter != null &&
          !_subscribeReadyCompleter!.isCompleted) {
        _subscribeReadyCompleter!.completeError(e, s);
      }
      if (_pubSubController != null && !_pubSubController!.isClosed) {
        _pubSubController!.addError(e, s);
      }
      _resetPubSubState();
    });

    // Return the Subscription object immediately
    return Subscription(
        _pubSubController!.stream, _subscribeReadyCompleter!.future);
  }

  /// Resets the Pub/Sub state (e.g., after unsubscribe or error).
  void _resetPubSubState() {
    // print('[DEBUG X.1] Resetting PubSub state.');
    _isSubscribed = false;
    _subscribedChannels.clear();
    if (_pubSubController != null && !_pubSubController!.isClosed) {
      _pubSubController!.close();
    }
    _pubSubController = null;
  }

  // --- Socket Lifecycle Handlers ---

  void _handleSocketError(Object error, StackTrace stackTrace) {
    print('[STREAM LOG] onError CALLED. Error: $error');
    // print('Socket error: $error');
    // print('[DEBUG E.1] Socket Error: $error');
    _cleanup(); // Close socket etc.
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.completeError(error, stackTrace);
    }
    // Fail all pending commands
    _failAllPendingCommands(error, stackTrace);
    if (_pubSubController != null && !_pubSubController!.isClosed) {
      // --- Close PubSub stream on error ---
      _pubSubController!.addError(error, stackTrace);
    }
    _resetPubSubState();
    // ----------------------------------
  }

  void _handleSocketDone() {
    print('[STREAM LOG] onDone CALLED.');
    // print('Socket closed by server.');
    // print('[DEBUG D.1] Socket Done.');
    _cleanup();
    final error = Exception('Connection closed unexpectedly by the server.');
    final stackTrace = StackTrace.current;
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      // Connection closed prematurely.
      _connectionCompleter!
          .completeError(error, stackTrace); // Connection closed before setup.
    }
    // Fail all pending commands
    _failAllPendingCommands(error, stackTrace);
    if (_pubSubController != null && !_pubSubController!.isClosed) {
      // --- Close PubSub stream on disconnect ---
      _pubSubController!.addError(error, stackTrace);
    }
    _resetPubSubState();
  }

  void _failAllPendingCommands(Object error, [StackTrace? stackTrace]) {
    // print('[DEBUG F.1] Failing all ${_responseQueue.length} pending commands due to error.');
    while (_responseQueue.isNotEmpty) {
      final completer = _responseQueue.removeFirst();
      if (!completer.isCompleted) {
        // Avoid completing already completed futures
        completer.completeError(error, stackTrace);
      }
    }
  }

  /// Sends the AUTH command in RESP Array format.
  /// Sends the AUTH command. Internal use only.
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
    // Auth command is sent immediately after connect, socket should exist
    try {
      // Send to socket
      _socket?.write(buffer.toString());
    } catch (e) {
      // If sending AUTH fails, connection setup fails
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!
            .completeError(Exception('Failed to send AUTH command: $e'));
      }
      _cleanup();
    }
  }

  @override
  Future<void> close() async {
    print('[DEBUG C.1] Close called by user.');
    print('[STREAM LOG] close(): Attempting to CANCEL subscription...');
    await _subscription?.cancel();
    await _socket?.close(); // Graceful close if possible
    _cleanup(); // Ensure resources are released
    // Complete the completer with an error if it wasn't completed? Or just let onDone handle it?
    // Let onDone handle it for now.
    // Fail pending commands immediately? _handleSocketDone will do it eventually.
    // Reset pub/sub state immediately
    print('Connection closed by client.');
    // (No need to fail commands here, _handleSocketDone will do it)
    _resetPubSubState();
  }

  /// Internal helper to clean up socket and subscription resources.
  /// Cleans up resources like socket and subscription.
  void _cleanup() {
    print('[DEBUG CL.1] Cleaning up client resources.');
    print('[STREAM LOG] _cleanup(): Attempting to CANCEL subscription...');

    _subscription?.cancel();
    _socket?.destroy(); // Force close // Ensure the socket is fully destroyed.
    _socket = null;
    _subscription = null;
    _buffer.clear();
    // Reset flags
    _isAuthenticating = false;
    // Don't reset _isSubscribed here, rely on _resetPubSubState
    // Do not create a new completer here, let connect() handle it.
  }
}
