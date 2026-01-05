import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert'; // For UTF8 encoding
import 'dart:collection'; // A Queue to manage pending commands
import 'dart:math'; // [v2.2.0] For Random LoadBalancing

// Import the base class and the ValkeyMessage / Subscription
import 'package:valkey_client/valkey_client_base.dart';
// Import the new exceptions file
import 'package:valkey_client/src/exceptions.dart';
import 'package:valkey_client/src/logging.dart';
// Re-export ValkeyMessage from the main library file
export 'package:valkey_client/valkey_client_base.dart'
    show ValkeyMessage, Subscription;
// Import the top-level function from the parser file
import 'package:valkey_client/src/cluster_slots_parser.dart'
    show parseClusterSlotsResponse;

// Internal helper class to read bytes from the buffer.
class _BufferReader {
  final Uint8List _bytes;
  int _offset = 0;

  _BufferReader(this._bytes);

  int get remainingLength => _bytes.length - _offset;
  bool get isDone => _offset >= _bytes.length;

  /// Consumes bytes from the buffer up to the current offset.
  Uint8List consume() => _bytes.sublist(_offset);

  /// Reads a single byte (prefix)
  int readByte() {
    if (isDone) {
      throw _IncompleteDataException('Cannot read byte, buffer empty');
    }
    return _bytes[_offset++];
  }

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
      throw ValkeyParsingException('Invalid RESP length: $length');
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
    // If it's not CRLF, throw a specific parsing exception
    throw ValkeyParsingException(
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
  static final _log = ValkeyLogger('ValkeyClient');

  /// Sets the logging level for all ValkeyClient instances.
  ///
  /// By default, logging is `ValkeyLogLevel.off`.
  /// Use `ValkeyLogLevel.info` or `ValkeyLogLevel.warning` for debugging connection
  /// or parsing issues.
  static void setLogLevel(ValkeyLogLevel level) {
    ValkeyLogger.level = level;
  }

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

  /// The timeout duration for commands.
  final Duration _commandTimeout;

  // final Duration _connectTimeout;
  // final ValkeyConnectionSettings _config;

  // [v2.0.0] SSL Configuration
  final bool _useSsl;
  final SecurityContext? _sslContext;
  final bool Function(X509Certificate)? _onBadCertificate;

  // [v2.1.0] Config & Metadata
  final ValkeyConnectionSettings _config;
  ServerMetadata? _metadata;

  /// Returns the metadata of the connected server.
  ServerMetadata? get metadata => _metadata;

  // [v2.2.0] Read-only commands whitelist
  // This is a comprehensive list of commands that are safe to send to replicas.
  static const Set<String> _readOnlyCommands = {
    'GET',
    'EXISTS',
    'TTL',
    'PTTL',
    'GETRANGE',
    'MGET',
    'STRLEN',
    'HGET',
    'HGETALL',
    'HMGET',
    'HEXISTS',
    'HLEN',
    'HSTRLEN',
    'LINDEX',
    'LLEN',
    'LRANGE',
    'SCARD',
    'SISMEMBER',
    'SMEMBERS',
    'SRANDMEMBER',
    'ZCARD',
    'ZCOUNT',
    'ZRANGE',
    'ZOO',
    'ZSCORE',
    'ZRANK',
    'ZREVRANK',
    'ZLEXCOUNT',
    'ZRANGEBYLEX',
    'ZRANGEBYSCORE',
    'PFCOUNT',
    'GEOHASH',
    'GEOPOS',
    'GEODIST',
    'GEORADIUS_RO',
    'GEORADIUSBYMEMBER_RO',
    'BITCOUNT',
    'BITPOS',
    'GETBIT',
    'TYPE',
    'SCAN',
    'HSCAN',
    'SSCAN',
    'ZSCAN'
  };

  // [v2.2.0] Replica Management
  final List<ValkeyClient> _replicas = [];
  int _roundRobinIndex = 0;
  final Random _random = Random();

  // [v2.2.0 Debug Feature] Track the last client used for execution
  ValkeyClient? _lastUsedClient;

  /// Returns the configuration of the connection used for the last command.
  /// Useful for debugging load balancing strategies.
  ValkeyConnectionSettings? get lastUsedConnectionConfig =>
      _lastUsedClient?._config;

  // Command/Response Queue
  /// A queue of Completers, each waiting for a response.
  final Queue<Completer<dynamic>> _responseQueue = Queue();

  /// A buffer to store incomplete data chunks from the socket.
  final BytesBuilder _buffer = BytesBuilder();

  // Connection/Auth State
  /// A Completer for the initial connection/auth handshake.
  Completer<void>? _connectionCompleter;

  /// Internal state to manage the auth handshake
  bool _isAuthenticating = false;

  // Pub/Sub State
  /// Controller to broadcast incoming pub/sub messages.
  StreamController<ValkeyMessage>? _pubSubController;

  /// Flag indicating if the client is in *any* Pub/Sub mode (channel or pattern).
  bool _isInPubSubMode = false;

  /// Channels currently subscribed to via SUBSCRIBE.
  final Set<String> _subscribedChannels = {};

  /// Patterns currently subscribed to via PSUBSCRIBE.
  final Set<String> _subscribedPatterns = {};

  /// Completer for the 'ready' future of the current SUBSCRIBE command.
  Completer<void>? _subscribeReadyCompleter;

  /// Number of channels we expect confirmation for.
  int _expectedSubscribeConfirmations = 0;

  /// Completer for the 'ready' future of the current PSUBSCRIBE command.
  Completer<void>? _psubscribeReadyCompleter;
  int _expectedPSubscribeConfirmations = 0;

  /// Completer for the current UNSUBSCRIBE command.
  Completer<void>? _unsubscribeCompleter;

  /// Completer for the current PUNSUBSCRIBE command.
  Completer<void>? _punsubscribeCompleter;

  // Transaction State
  /// Flag indicating if the client is currently in a MULTI...EXEC block.
  bool _isInTransaction = false;

  /// Queue to hold commands during a MULTI...EXEC block.
  final Queue<List<String>> _transactionQueue = Queue();

  // --- v1.6.0: Sharded Pub/Sub State ---
  Completer<void>? _ssubscribeReadyCompleter;
  int _expectedSsubscribeConfirmations = 0;
  Completer<void>? _sunsubscribeCompleter;
  // -------------------------------------

  // --- v1.7.0: Smart Connection Pool Support ---

  /// Returns true if the client has an active socket connection.
  bool get isConnected => _socket != null;

  /// Returns true if the client is in a stateful mode that makes it
  /// unsuitable for reuse without a reset (e.g., Pub/Sub, Transaction).
  ///
  /// Used by [ValkeyPool] to determine if a connection should be discarded
  /// instead of reused.
  bool get isStateful {
    // 1. Pub/Sub Mode? (SUBSCRIBE, PSUBSCRIBE, SSUBSCRIBE)
    if (_isInPubSubMode) return true;

    // 2. Transaction Mode? (MULTI started but not EXEC/DISCARDed)
    if (_isInTransaction) return true;

    // 3. (Future) Blocking commands?
    // If we support BLPOP in the future, check blocking state here.

    return false;
  }
  // ---------------------------------------------

  /// Creates a new Valkey client instance.
  ///
  /// [host], [port], [username], and [password] are the default
  /// connection parameters used when [connect] is called.
  ///
  /// [commandTimeout] specifies the maximum duration to wait for a command
  /// response before throwing a [ValkeyClientException].
  ValkeyClient({
    String host = '127.0.0.1',
    int port = 6379,
    String? username,
    String? password,
    Duration commandTimeout = const Duration(seconds: 10),
    Duration connectTimeout = const Duration(seconds: 10),
    // [v2.0.0] Add SSL parameters
    bool useSsl = false,
    SecurityContext? sslContext,
    bool Function(X509Certificate)? onBadCertificate,
    int database = 0,
    ReadPreference readPreference = ReadPreference.master,
    LoadBalancingStrategy loadBalancingStrategy =
        LoadBalancingStrategy.roundRobin,
    List<ValkeyConnectionSettings>? explicitReplicas,
    AddressMapper? addressMapper,
  })  : _config = ValkeyConnectionSettings(
          host: host,
          port: port,
          username: username,
          password: password,
          commandTimeout: commandTimeout,
          connectTimeout: connectTimeout,
          // [v2.0.0] Initialize SSL settings
          useSsl: useSsl,
          sslContext: sslContext,
          onBadCertificate: onBadCertificate,
          database: database,
          readPreference: readPreference,
          loadBalancingStrategy: loadBalancingStrategy,
          explicitReplicas: explicitReplicas ?? [],
          addressMapper: addressMapper,
        ),
        _defaultHost = host,
        _defaultPort = port,
        _defaultUsername = username,
        _defaultPassword = password,
        _commandTimeout = commandTimeout,
        // _connectTimeout = connectTimeout,
        // [v2.0.0] Initialize SSL settings
        _useSsl = useSsl,
        _sslContext = sslContext,
        _onBadCertificate = onBadCertificate;

  // Constructor utilizing an existing settings object
  // ValkeyClient.fromSettings(this._config);

  /// Creates a client using a [ValkeyConnectionSettings] object.
  factory ValkeyClient.fromSettings(ValkeyConnectionSettings settings) =>
      ValkeyClient(
        host: settings.host,
        port: settings.port,
        username: settings.username,
        password: settings.password,
        commandTimeout: settings.commandTimeout,
        // [v2.0.0] SSL Options mapping
        useSsl: settings.useSsl,
        sslContext: settings.sslContext,
        onBadCertificate: settings.onBadCertificate,
        database: settings.database,
        readPreference: settings.readPreference,
        loadBalancingStrategy: settings.loadBalancingStrategy,
        explicitReplicas: settings.explicitReplicas,
        addressMapper: settings.addressMapper,
      );

  /// A Future that completes once the connection and authentication are successful.
  @override
  Future<void> get onConnected =>
      _connectionCompleter?.future ??
      Future.error(ValkeyClientException(
          'Client not connected or connection attempt failed.'));

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
    // If already connected successfully, return immediately
    if (_socket != null &&
        _connectionCompleter != null &&
        _connectionCompleter!.isCompleted) {
      // Check if the completed future was successful
      bool wasSuccessful =
          await onConnected.then((_) => true, onError: (_) => false);
      if (wasSuccessful) return onConnected;
      // If the future completed with an error, allow reconnect attempt
      await close(); // Ensure cleanup before reconnect if previous connection failed
    }

    // Use method args if provided, otherwise fallback to defaults
    _lastHost = host ?? _defaultHost;
    _lastPort = port ?? _defaultPort;
    _lastUsername = username ?? _defaultUsername;
    _lastPassword = password ?? _defaultPassword;

    // Reset the completer for this new connection attempt
    _connectionCompleter = Completer();
    // Reset states for a fresh connection
    _isAuthenticating = false;

    _isInPubSubMode = false; // Reset pubsub state on new connection
    _subscribedChannels.clear();
    _subscribedPatterns.clear(); // Clear patterns too
    _buffer.clear();
    _responseQueue.clear();
    _resetPubSubState(); // Close existing controller and reset completers

    try {
      // 1. Attempt to connect the socket.
      // _socket = await Socket.connect(_lastHost, _lastPort);

      // --- BEGIN: v1.3.0 IPv6 HOTFIX ---
      // On macOS/Windows, Docker often binds to IPv4 (127.0.0.1) but not
      // IPv6 (::1). Dart's Socket.connect defaults to IPv6 first when
      // 'localhost' or '127.0.0.1' is used, causing a connection hang.
      // We explicitly force IPv4 for loopback addresses.
      dynamic hostToConnect = _lastHost;
      if (_lastHost == '127.0.0.1' || _lastHost == 'localhost') {
        _log.fine('Forcing IPv4 loopback address for 127.0.0.1/localhost');
        hostToConnect = InternetAddress.loopbackIPv4;
      }

      // 1. Attempt to connect the socket (SSL or Plain).
      if (_useSsl) {
        // [v2.0.0] Secure Connection
        _socket = await SecureSocket.connect(
          hostToConnect,
          _lastPort,
          context: _sslContext,
          onBadCertificate: _onBadCertificate,
          timeout: _config.connectTimeout,
        );
      } else {
        // Plain Connection
        _socket = await Socket.connect(
          hostToConnect,
          _lastPort,
          timeout: _config.connectTimeout,
        );
      }
      // --- END: v1.3.0 IPv6 HOTFIX ---

      // 2. Set up the socket stream listener.
      _subscription = _socket!.listen(
        // This is where we will parse the RESP3 data from the server.
        _handleSocketData,
        onError: _handleSocketError,
        onDone: _handleSocketDone,
        // false: The subscription will NOT be automatically cancelled if an error occurs. Error handling (including potential cancellation) is managed by the onError callback (_handleSocketError).
        // true: Automatically cancel the subscription on error.
        cancelOnError: false, // Keep false
      );

      // AUTHENTICATION LOGIC
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
      final connEx = ValkeyConnectionException(
          'Failed to connect to $_lastHost:$_lastPort. $e', e);
      _cleanup(); // Clean up socket if connection fails
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!
            .completeError(connEx, s); // Rethrow connection error
      }
    }

    // return onConnected;

    // [v2.1.0 Logic Addition]
    // Wait for the basic connection and auth to complete first.
    await onConnected;

    // Initialize Metadata & DB Selection (v2.1.0)
    try {
      await _initializeConnection();
    } catch (e) {
      // If DB selection fails (e.g. index out of range), close connection and rethrow.
      await close();
      throw ValkeyConnectionException(
          'Failed to initialize connection (DB Selection): $e', e);
    }

    // Return void as the Future<void> signature requires

    // 3. [v2.2.0] Replica Discovery: Discover & Connect to Replicas
    // Only if the user requested a preference other than 'master'
    if (_config.readPreference != ReadPreference.master) {
      // Avoid recursion: If this instance is already a replica (or auxiliary client), skip.
      // \ We can check this by ensuring we don't pass 'readPreference' to children,
      // \ OR simply by checking if we are the main client context.
      // \ For now, _discoverAndConnectReplicas handles recursion by creating clients with ReadPreference.master.
      await _discoverAndConnectReplicas();
    }
  }

  /// [v2.2.0] Discovers replicas via Explicit Config AND Auto-Discovery.
  /// Auto-Discovery: INFO REPLICATION (Standalone) or CLUSTER SLOTS (Cluster).
  Future<void> _discoverAndConnectReplicas() async {
    _replicas.clear(); // Clear existing if reconnecting

    // 1. Connect to Explicit Replicas (if any)
    // These are prioritized as the user manually defined them.
    if (_config.explicitReplicas != null) {
      for (final replicaConfig in _config.explicitReplicas!) {
        await _addReplicaFromConfig(replicaConfig);
      }
    }

    // 2. Auto Discovery (Cluster or Standalone) + AutoNAT
    // Always run auto-discovery to find dynamic nodes.

    // 2-1. Cluster Mode Discovery
    if (_metadata?.mode == RunningMode.cluster) {
      try {
        final slots = await clusterSlots();

        // Iterate through slots to find replica nodes
        for (final slot in slots) {
          for (final replicaNode in slot.replicas) {
            // [AutoNAT] Apply Mapping
            var targetHost = replicaNode.host;
            var targetPort = replicaNode.port;

            if (_config.addressMapper != null) {
              final mapped = _config.addressMapper!(targetHost, targetPort);
              targetHost = mapped.host;
              targetPort = mapped.port;
            }

            // Create config inheriting from Master but overriding Host/Port
            final discoveredConfig = _config.copyWith(
              // host: replicaNode.host,
              // port: replicaNode.port,
              host: targetHost,
              port: targetPort,
              readPreference: ReadPreference.master, // Prevent recursion
              explicitReplicas: [], // Clear explicit list for child
            );
            // await _addReplica(replicaNode.host, replicaNode.port);
            await _addReplicaFromConfig(discoveredConfig);
          }
        }
      } catch (e) {
        _log.warning('Failed to discover replicas via CLUSTER SLOTS: $e');
      }
    }
    // 2-2. Standalone / Sentinel Mode Discovery
    else {
      try {
        final info = await execute(['INFO', 'REPLICATION']);
        // final info = await _executeInternal(['INFO', 'REPLICATION']);
        _log.info(info);
        // if (info is! String) return;

        if (info is String) {
          final lines = info.split('\r\n');
          for (var line in lines) {
            // Parse slave lines: "slave0:ip=127.0.0.1,port=6380,state=online,..."
            // Parse slave lines: "slave0:ip=172.x.x.x,port=6380,state=online,..."
            if (line.startsWith('slave')) {
              final parts = line.split(',');
              String? ip;
              int? port;
              String state = 'offline';

              for (var part in parts) {
                if (part.contains('ip=')) ip = part.split('=')[1];
                if (part.contains('port=')) {
                  port = int.tryParse(part.split('=')[1]);
                }
                if (part.contains('state=')) state = part.split('=')[1];
              }

              if (ip != null && port != null && state == 'online') {
                // [AutoNAT] Apply Mapping
                // \ Convert Internal IP(172.x) to External IP(127.0.0.1)
                var targetHost = ip;
                var targetPort = port;

                if (_config.addressMapper != null) {
                  final mapped = _config.addressMapper!(targetHost, targetPort);
                  targetHost = mapped.host;
                  targetPort = mapped.port;
                }

                // Auto-discovered nodes inherit Master's Auth/SSL settings
                final discoveredConfig = _config.copyWith(
                  // host: ip,
                  // port: port,
                  host: targetHost,
                  port: targetPort,
                  readPreference: ReadPreference.master,
                  explicitReplicas: [],
                );
                // NOTE: Avoid connecting to self if something is wrong, but usually IP:Port differs.
                // await _addReplica(ip, port);
                await _addReplicaFromConfig(discoveredConfig);
              }
            }
          }
        }
      } catch (e) {
        // _log.warning('Auto-discovery failed: $e');
        _log.warning('Failed to discover replicas via INFO REPLICATION: $e');
        // Do not fail the master connection just because replica discovery failed.
      }
    }

    // Check constraint: If replicaOnly is set but no replicas found
    if (_config.readPreference == ReadPreference.replicaOnly &&
        _replicas.isEmpty) {
      throw ValkeyConnectionException(
          'ReadPreference is replicaOnly but no online replicas were found.');
    }
  }

  /// Helper to connect and add a replica using a full settings object.
  Future<void> _addReplicaFromConfig(ValkeyConnectionSettings settings) async {
    // 1. Deduplication
    //    \ Implement deduplication logic to prevent redundant connections.
    //    \ If a client with the same IP and Port is already in the list, skip it.
    //    \ NOTE: Check to prevent connecting to the same replica multiple times.
    //    \ NOTE: Avoid adding duplicates if multiple slots share the same replica
    for (final r in _replicas) {
      // Accessing private member '_config' is allowed since we are in the same class.
      if (r._config.host == settings.host && r._config.port == settings.port) {
        _log.info(
            'Replica ${settings.host}:${settings.port} is already connected. Skipping.');
        return;
      }
    }

    try {
      // 2. Ensure recursion safety
      //    \ Create settings (a new client) for the replica.
      //    \ Force ReadPreference.master to prevent infinite recursion
      //    \ NOTE: A replica client should not try to discover its own replicas.
      final safeSettings = settings.copyWith(
        readPreference: ReadPreference.master, // Stop recursion
        explicitReplicas: [],
      );

      // 3. Connect to the replica
      final replicaClient = ValkeyClient.fromSettings(safeSettings);

      // TODO: REVIEW REQUIRED => REMOVE. NEED CONSENSUS.
      // final replicaClient = ValkeyClient(
      //   host: settings.host,
      //   port: settings.port,
      //   username: settings.username,
      //   password: settings.password,
      //   commandTimeout: settings.commandTimeout,
      //   useSsl: settings.useSsl,
      //   sslContext: settings.sslContext,
      //   onBadCertificate: settings.onBadCertificate,
      //   database: settings.database,
      //   readPreference: ReadPreference.master,
      //   explicitReplicas: settings.explicitReplicas,
      //   loadBalancingStrategy: settings.loadBalancingStrategy,
      // );

      await replicaClient.connect();

      // 4. [Cluster Mode] If metadata indicates cluster, we MUST send READONLY
      // to enable reading from a replica node.
      if (_metadata?.mode == RunningMode.cluster) {
        await replicaClient.execute(['READONLY']);
        //  await replicaClient._executeInternal(['READONLY']);
      }

      // 5. Add to the list and log success
      _replicas.add(replicaClient);
      _log.info('Added replica connection: ${settings.host}:${settings.port}');
    } catch (e) {
      // Log connection failure
      _log.warning(
          'Failed to connect to replica at ${settings.host}:${settings.port} : $e');
    }
  }

  // TODO: REVIEW REQUIRED => REMOVE. NEED CONSENSUS.
  // Future<void> _addReplica(String host, int port) async {
  //   // 1. Implement deduplication logic to prevent redundant connections.
  //   // If a client with the same IP and Port is already in the list, skip it.
  //   // \ NOTE: Check to prevent connecting to the same replica multiple times.
  //   // \ NOTE: Avoid adding duplicates if multiple slots share the same replica
  //   for (final r in _replicas) {
  //      // Accessing private member '_config' is allowed since we are in the same class.
  //      if (r._config.host == host && r._config.port == port) {
  //       _log.info('Replica $host:$port is already connected. Skipping.');
  //       return;
  //     }
  //   }

  //   try {
  //     // 2. Create settings (a new client) for the replica.
  //     // Force ReadPreference.master to prevent infinite recursion
  //     // \ NOTE: A replica client should not try to discover its own replicas.
  //     final replicaSettings = _config.copyWith(
  //       host: host,
  //       port: port,
  //       readPreference: ReadPreference.master, // Stop recursion
  //     );

  //     // 3. Connect to the replica
  //     final replicaClient = ValkeyClient.fromSettings(replicaSettings);
  //     await replicaClient.connect();

  //     // 4. [Cluster Mode] If metadata indicates cluster, we MUST send READONLY
  //     // to enable reading from a replica node.
  //     if (_metadata?.mode == RunningMode.cluster) {
  //       await replicaClient.execute(['READONLY']);
  //     }

  //     // 5. Add to the list and log success
  //     _replicas.add(replicaClient);
  //     _log.info('Added replica connection: $host:$port');
  //   } catch (e) {
  //     // Log connection failure
  //     _log.warning('Failed to connect to replica at $host:$port : $e');
  //   }
  // }

  /// [v2.1.0] Detects server info and selects the configured database.
  Future<void> _initializeConnection() async {
    // 1. Get INFO SERVER
    final infoString = await execute(['INFO', 'SERVER']) as String;
    // Use _executeInternal to bypass routing during initialization
    // final infoString = await _executeInternal(['INFO', 'SERVER']) as String;

    // 2. Parse Metadata (Version, Mode, Max DBs)
    _metadata = await _parseServerMetadata(infoString);

    // 3. Select Database if needed
    if (_config.database > 0) {
      // Check range
      if (_config.database >= _metadata!.maxDatabases) {
        throw ValkeyClientException(
            'Requested database index ${_config.database} is out of range. '
            'Server (${_metadata!.serverName}) supports 0 to ${_metadata!.maxDatabases - 1}.');
      }

      // Perform SELECT
      await execute(['SELECT', _config.database.toString()]);
      // Use _executeInternal to bypass routing during initialization
      // await _executeInternal(['SELECT', _config.database.toString()]);
    }
  }

  /// Parses 'INFO SERVER' and checks configs based on User Rules.
  Future<ServerMetadata> _parseServerMetadata(String info) async {
    final Map<String, String> infoMap = {};
    final lines = info.split('\r\n');
    for (var line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          infoMap[parts[0]] = parts[1];
        }
      }
    }

    // --- Rule 1: Determine Name & Version ---
    String serverName = 'unknown';
    String version = '0.0.0';

    if (infoMap.containsKey('valkey_version')) {
      serverName = 'valkey';
      version = infoMap['valkey_version']!;
    } else if (infoMap.containsKey('redis_version')) {
      serverName = 'redis';
      version = infoMap['redis_version']!;
    }

    // --- Detect Mode ---
    final serverMode = infoMap['server_mode'] ?? 'unknown';
    RunningMode mode = switch (serverMode) {
      'cluster' => RunningMode.cluster,
      'sentinel' => RunningMode.sentinel,
      'standalone' => RunningMode.standalone,
      _ => RunningMode.unknown,
    };

    // --- Rule 2: Determine Max Databases ---
    int maxDatabases = 16; // Default fallback

    // Logic:
    // If Valkey >= 9.0.0 -> Check 'cluster-databases'
    // Else (Valkey < 9.0 OR Redis) -> Check 'databases'

    bool isValkey9OrAbove = false;
    if (serverName == 'valkey') {
      isValkey9OrAbove = _compareVersions(version, '9.0.0') >= 0;
    }

    String configKeyToCheck = switch (serverMode) {
      'cluster' => isValkey9OrAbove
          ? 'cluster-databases' // Default for Valkey 9.0+
          : 'databases', // Default for Old Valkey (9.0-)
      _ => 'databases', // Default for Redis
    };

    // Fetch the specific config
    try {
      final configVal = await _getConfigValue(configKeyToCheck);
      if (configVal != null) {
        maxDatabases = int.tryParse(configVal) ?? 16;
      } else {
        // If config fetch returns null
        if (mode == RunningMode.cluster && !isValkey9OrAbove) {
          // Redis Cluster / Old Valkey Cluster usually supports only DB 0.
          maxDatabases = 1;
        }
      }
    } catch (_) {
      // If CONFIG GET fails (permission error, etc.)
      if (mode == RunningMode.cluster && !isValkey9OrAbove) {
        maxDatabases = 1;
      }
    }

    return ServerMetadata(
      version: version,
      serverName: serverName,
      mode: mode,
      maxDatabases: maxDatabases,
    );
  }

  /// Helper to get a single config value. Returns null if not found/error.
  Future<String?> _getConfigValue(String parameter) async {
    try {
      // CONFIG GET returns ['parameter', 'value']
      final result = await execute(['CONFIG', 'GET', parameter]);
      if (result is List && result.length >= 2) {
        return result[1] as String;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Helper to compare semantic versions.
  /// Returns 1 if v1 > v2, -1 if v1 < v2, 0 if equal.
  int _compareVersions(String v1, String v2) {
    var v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    var v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (var i = 0; i < 3; i++) {
      // Compare major, minor, patch
      int p1 = (i < v1Parts.length) ? v1Parts[i] : 0;
      int p2 = (i < v2Parts.length) ? v2Parts[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  // --- Core Data Handler & Parser ---

  /// This is now the main entry point for ALL data from the socket.
  void _handleSocketData(Uint8List data) {
    // _log.info('Raw data from server: ${String.fromCharCodes(data)}');
    // _log.info('[DEBUG 1] _handleSocketData received: ${data.length} bytes');
    // try { _log.info('[DEBUG 1.1] Data as string:\n${utf8.decode(data).replaceAll('\r', '\\r').replaceAll('\n', '\\n\n')}'); } catch (_) {}
    _buffer.add(data);
    _processBuffer(); // Try to process the buffered data
  }

  /// This is the new parser entry point.
  /// It loops and tries to parse one full response at a time.
  ///
  /// Processes the buffer, parsing messages and routing them.
  void _processBuffer() {
    // _log.info('[DEBUG 2] _processBuffer entered. Buffer size: ${_buffer.length}, Queue size: ${_responseQueue.length}, Subscribed: $_isInPubSubMode, Authenticating: $_isAuthenticating');
    while (_buffer.isNotEmpty) {
      // Process as long as there's data
      final reader = _BufferReader(_buffer.toBytes());
      final initialOffset = reader._offset; // Track if we consumed anything

      try {
        // Attempt to parse ONE full response from the current buffer state
        // _log.info('[DEBUG 3] Attempting _parseResponse... (Buffer start: ${_buffer.toBytes().take(20).join(',')})');
        final response =
            _parseResponse(reader); // Might throw _IncompleteDataException

        // _log.info('[DEBUG 4] _parseResponse SUCCEEDED. Type: ${response.runtimeType}, Consumed: ${reader._offset - initialOffset} bytes');
        // if (response is List) { _log.info('[DEBUG 4.1] Parsed Response (List): ${response.map((e) => e?.toString() ?? 'null').join(', ')}'); } else { _log.info('[DEBUG 4.1] Parsed Response: $response'); }

        // --- Handle Push Messages (Pub/Sub) ---
        // Is it a Pub/Sub push message?
        // Check if it's a PUSH message FIRST
        if (_isPubSubPushMessage(response)) {
          _handlePubSubMessage(response as List<dynamic>);
        }

        // --- Handle Regular Command Responses ---
        // Is it the response to the initial AUTH command?
        // If NOT a push message, check if we are AUTHENTICATING
        else if (_isAuthenticating) {
          _resolveNextCommand(response); // Completes _connectionCompleter
        }

        // If we are in a transaction, most responses are just '+QUEUED'.
        else if (_isInTransaction) {
          // Check if it's the response to MULTI, EXEC, or DISCARD itself
          // final lastQueuedCommand = _transactionQueue.isNotEmpty ? _transactionQueue.last[0].toUpperCase() : '';

          if (response == 'QUEUED') {
            // If in transaction, 'QUEUED' response completes the command's future.
            _resolveNextCommand(response);
          }
          // Handle EXEC or DISCARD responses
          else if (_responseQueue.isNotEmpty) {
            _resolveNextCommand(response);
          }
        }
        // Is it a response to a command we sent via execute()?
        // If NOT push and NOT auth, check if it's a COMMAND response
        else if (_responseQueue.isNotEmpty) {
          _resolveNextCommand(response); // Completes command completer
        }
        // Otherwise, it's unexpected data.
        else {
          throw ValkeyClientException(
              'Received unexpected message when queue was empty: $response');
        }

        // Consume the bytes for the successfully parsed message
        final remainingBytes = reader.consume();
        _buffer.clear();
        _buffer.add(remainingBytes);

        // _log.info('[DEBUG 5.5] Buffer consumed. Remaining size: ${_buffer.length}');

        // Defensive check: If parser succeeded but didn't consume bytes, break.
        if (reader._offset == initialOffset) {
          throw ValkeyParsingException(
              'Parser completed but did not advance (Buffer: ${_buffer.toBytes()}). Breaking loop.');
        }
      } on _IncompleteDataException {
        // Not enough data in the buffer to parse a full response.
        // Stop looping and wait for more socket data.
        // _log.info('IncompleteDataException. Breaking loop, need more data.');
        break; // Exit the while loop and wait for next _handleSocketData
      } catch (e, s) {
        // This catches parsing errors (from _parseResponse)
        // or errors returned *as* responses (like '-' which _parseResponse turns into Exception)
        _log.severe('Error during buffer processing', e, s);

        // If subscribed mode error, maybe close stream?
        // Try to report error to the correct place
        // Determine if this error should go to a command or the connection
        if (_isInPubSubMode &&
            _pubSubController != null &&
            !_pubSubController!.isClosed) {
          _pubSubController!.addError(e, s);
          _resetPubSubState(); // Reset on error // Exit subscribed mode on error
        } else if (_isAuthenticating) {
          // Authentication error (e.g., -WRONGPASS)
          _resolveNextCommand(e,
              isError: true, stackTrace: s); // Fail connection
        } else if (_responseQueue.isNotEmpty) {
          // Command error (e.g., -ERR wrong number of arguments)
          _resolveNextCommand(e, isError: true, stackTrace: s); // Fail command
        }
        // Clear buffer to avoid infinite error loop
        _buffer.clear(); // Clear potentially corrupted buffer
        break; // Stop processing on error
      }
    } // end while
    // _log.info('_processBuffer finished this round. Buffer size: ${_buffer.length}');
  }

  /// Checks if a parsed RESP Array is a Pub/Sub push message.
  /// e.g., ['message', 'channel_name', 'payload']
  /// e.g., ['subscribe', 'channel_name', 1] (confirmation)
  bool _isPubSubPushMessage(dynamic response) {
    if (response is List && response.isNotEmpty && response[0] is String) {
      final type = response[0] as String;
      return type == 'message' ||
          type == 'subscribe' ||
          type == 'unsubscribe' ||
          type == 'pmessage' ||
          type == 'psubscribe' ||
          type == 'punsubscribe' ||
          type == 'smessage' ||
          type == 'ssubscribe' ||
          type == 'sunsubscribe';
    }
    return false;
  }

  /// Handles incoming Pub/Sub push messages (after parsing).
  void _handlePubSubMessage(List<dynamic> messageArray) {
    final type = messageArray[0] as String;
    int? currentRemainingCount; // Variable to store the count from ack message
    // _log.info('_handlePubSubMessage received type: $type, Data: ${messageArray.skip(1).join(', ')}');

    // 1. Sharded Message (smessage)
    if (type == 'smessage' && messageArray.length == 3) {
      final channel = messageArray[1] as String;
      final message = messageArray[2] as String?;
      if (_pubSubController != null && !_pubSubController!.isClosed) {
        _pubSubController!
            .add(ValkeyMessage(channel: channel, message: message ?? ''));
      }
    }
    // 2. Sharded Subscribe Confirmation (ssubscribe)
    else if (type == 'ssubscribe' && messageArray.length == 3) {
      final channel = messageArray[1] as String?;
      final count = messageArray[2];

      if (channel != null && count is int) {
        if (!_isInPubSubMode && count > 0) {
          _isInPubSubMode = true;
        }
        _subscribedChannels
            .add(channel); // We reuse the same set for simplicity

        _expectedSsubscribeConfirmations--;

        if (_expectedSsubscribeConfirmations <= 0 &&
            _ssubscribeReadyCompleter != null &&
            !_ssubscribeReadyCompleter!.isCompleted) {
          _ssubscribeReadyCompleter!.complete();
        }
        currentRemainingCount = count;
      }
    }
    // 3. Sharded Unsubscribe Confirmation (sunsubscribe)
    else if (type == 'sunsubscribe' && messageArray.length == 3) {
      final channel = messageArray[1] as String?;
      final count = messageArray[2];

      if (channel != null && count is int) {
        _subscribedChannels.remove(channel);
      } else if (channel == null && count is int) {
        // If we clear all sharded subs, we might not want to clear regular subs
        // But for simplicity in this version, we assume mixed usage is rare or managed carefully.
        // Ideally, track sharded channels separately.
      }

      if (count is int) {
        currentRemainingCount = count;
        if (_sunsubscribeCompleter != null &&
            !_sunsubscribeCompleter!.isCompleted) {
          // Basic completion logic
          if (count == 0 || channel != null) {
            _sunsubscribeCompleter!.complete();
            _sunsubscribeCompleter = null;
          }
        }
      }
    } else {
      if (type == 'message' && messageArray.length == 3) {
        final channel = messageArray[1] as String;
        final message = messageArray[2]
            as String?; // Allow null message? Redis usually sends empty string
        if (_pubSubController != null && !_pubSubController!.isClosed) {
          _pubSubController!.add(ValkeyMessage(
              channel: channel,
              message: message ?? '')); // Handle potential null
        } else {
          // _log.info('StreamController is null or closed, cannot add message.');
        }
      } else if (type == 'pmessage' && messageArray.length == 4) {
        final pattern = messageArray[1] as String;
        final channel = messageArray[2] as String;
        final message = messageArray[3] as String?;
        if (_pubSubController != null && !_pubSubController!.isClosed) {
          _pubSubController!.add(ValkeyMessage(
              pattern: pattern, channel: channel, message: message ?? ''));
        }
      } else if (type == 'subscribe' && messageArray.length == 3) {
        // Handle the initial subscription confirmation
        final channel = messageArray[1]
            as String?; // Can be null on multi-subscribe? Check RESP spec
        final count = messageArray[2]; // Current total *combined* count

        // _log.info('Handling subscribe confirmation for ${channel ?? 'unknown channel'}. Count: $count');
        if (channel != null && count is int) {
          if (!_isInPubSubMode && count > 0) {
            _isInPubSubMode = true; // Set state upon first confirmation
          }
          _subscribedChannels.add(channel);
          // Completer is handled in _resolveNextCommand

          // Check if all expected channels are confirmed ---
          // Decrement expected count (or check if _subscribedChannels.length reaches expected)
          // Complete the 'ready' future for SUBSCRIBE
          _expectedSubscribeConfirmations--;
          // _log.info('Subscription confirmed for $channel. Remaining confirmations needed: $_expectedSubscribeConfirmations');

          // Complete the 'ready' future only when all confirmations are received
          if (_expectedSubscribeConfirmations <=
                  0 && // Should be exactly 0 ideally
              _subscribeReadyCompleter != null &&
              !_subscribeReadyCompleter!.isCompleted) {
            // _log.info('All subscribe confirmations received. Completing ready future.');
            _subscribeReadyCompleter!.complete();
          }
          currentRemainingCount = count; // Store count
          // --- DO NOT complete the command completer here ---
          // --- DO NOT add this confirmation to _pubSubController ---
        } else {
          // _log.info('Invalid subscribe confirmation format: $messageArray');
        }
      } else if (type == 'psubscribe' && messageArray.length == 3) {
        final pattern = messageArray[1] as String?;
        final count = messageArray[2]; // Current total *combined* count

        if (pattern != null && count is int) {
          if (!_isInPubSubMode && count > 0) {
            _isInPubSubMode = true;
          }
          _subscribedPatterns.add(pattern);

          // Complete the 'ready' future for PSUBSCRIBE
          _expectedPSubscribeConfirmations--;
          if (_expectedPSubscribeConfirmations <= 0 &&
              _psubscribeReadyCompleter != null &&
              !_psubscribeReadyCompleter!.isCompleted) {
            _psubscribeReadyCompleter!.complete();
          }
          // currentRemainingCount = count;
          currentRemainingCount = count as int?; // Store count
        }
      }

      // Note: Ensure subscribe/psubscribe only complete their respective READY completers,
      // and DO NOT complete the command completer from the queue.

      else if (type == 'unsubscribe' && messageArray.length == 3) {
        final channel =
            messageArray[1] as String?; // Can be null if unsubscribing from all
        final count = messageArray[2]; // Remaining total *combined* count

        // Update internal state
        if (channel != null && count is int) {
          _subscribedChannels.remove(channel);
        }
        // Unsubscribed from all requested/known channels
        else if (channel == null && count is int) {
          // count might not be 0 if patterns remain
          _subscribedChannels
              .clear(); // Assume null means all channels user knew about are gone.
        }

        if (count is int) {
          currentRemainingCount = count;
          // --- Complete the dedicated UNSUBSCRIBE completer ---
          // Complete only if count drops to 0 OR if specific channels were requested
          // and this is the last confirmation (logic needs refinement,
          // but for now, complete on *any* confirmation if completer exists)
          // A safer bet: complete *only* when count hits 0 (if unsubscribing all)
          // or when the specific channel list is processed (needs tracking)
          // Let's try completing when count == 0 and patterns empty
          if (_unsubscribeCompleter != null &&
              !_unsubscribeCompleter!.isCompleted) {
            if (count == 0 || channel != null) {
              // Complete on any confirmation
              _unsubscribeCompleter!.complete();
              _unsubscribeCompleter = null; // Reset
            }
          }
        }
      } else if (type == 'punsubscribe' && messageArray.length == 3) {
        final pattern = messageArray[1] as String?; // Can be null
        final count = messageArray[2]; // Remaining total *combined* count

        // Update internal state
        if (pattern != null && count is int) {
          _subscribedPatterns.remove(pattern);
        }
        // Unsubscribed from all requested/known patterns
        else if (pattern == null && count is int) {
          // count might not be 0 if channels remain
          _subscribedPatterns.clear();
        }

        if (count is int) {
          currentRemainingCount = count;
          // Complete the dedicated PUNSUBSCRIBE completer
          if (_punsubscribeCompleter != null &&
              !_punsubscribeCompleter!.isCompleted) {
            if (count == 0 || pattern != null) {
              // Complete on any confirmation
              _punsubscribeCompleter!.complete();
              _punsubscribeCompleter = null; // Reset
            }
          }
        }
      } else {
        _pubSubController?.addError(ValkeyClientException(
            'Received unhandled Pub/Sub push message type: $type'));
      }
    }

    // Reset State Logic
    // Safer check: If count is 0, AND both lists are empty, reset.
    if (currentRemainingCount is int &&
        currentRemainingCount == 0 &&
        _subscribedChannels.isEmpty &&
        _subscribedPatterns.isEmpty) {
      _resetPubSubState();
    }
  }

  /// Helper to safely complete the next command in the queue.
  void _tryCompleteCommandFromQueue(dynamic result,
      {bool isError = false, StackTrace? stackTrace}) {
    if (_responseQueue.isNotEmpty) {
      final completer = _responseQueue.removeFirst();
      if (!completer.isCompleted) {
        // Complete in the next event loop cycle
        scheduleMicrotask(() {
          if (!completer.isCompleted) {
            // Double check completion
            if (isError) {
              completer.completeError(
                  result ?? ValkeyException("Unknown error"), stackTrace);
            } else {
              // Completing command successfully via microtask with result
              completer.complete(result);
            }
          } else {
            // _log.info("Completer was already done before microtask ran.");
          }
        });
      } else {
        // _log.info("Tried to complete command but completer was already done.");
      }
    } else {
      // This can happen if a push message arrives (like unsubscribe)
      // but no command was awaiting it (e.g., server auto-unsub)
      // _log.info("Tried to complete command but response queue was empty.");
    }
  }

  /// The core recursive RESP parser.
  dynamic _parseResponse(_BufferReader reader) {
    // _log.info('_parseResponse entered. Offset: ${reader._offset}');
    if (reader.isDone) {
      throw _IncompleteDataException('Cannot parse, buffer empty');
    }

    final responseType = reader.readByte();
    // _log.info('Response type prefix: ${String.fromCharCode(responseType)} ($responseType)');

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
          // Throw specific server exception
          result =
              ValkeyServerException(line); // Return as ValkeyServerException
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
              // _log.info('Parsing array element $i/$arrayLength...');
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
          // Throw specific parsing exception
          result = ValkeyParsingException(
              'Unknown RESP prefix type: ${String.fromCharCode(responseType)} ($responseType)');
      }
      // _log.info('_parseResponse SUCCESS. Offset: ${reader._offset}, Result type: ${result.runtimeType}');
      return result;
    } catch (e) {
      if (e is ValkeyException || e is _IncompleteDataException) rethrow;
      // Wrap other parsing errors (e.g., int.parse)
      throw ValkeyParsingException('Failed to parse RESP response: $e');
    }
  }

  /// Helper to resolve the next command in the queue.

  /// Resolves the next command completer in the queue, now checks if response is an Exception.
  void _resolveNextCommand(dynamic response,
      {bool isError = false /* deprecated */, StackTrace? stackTrace}) {
    // _log.info('_resolveNextCommand called. IsError(arg): $isError, ResponseType: ${response.runtimeType}');

    // Determine if the response itself is an error
    // Check for *any* Exception, not just ValkeyConnectionException
    final bool responseIsError = response is Exception;
    final dynamic result = response;

    if (_isAuthenticating) {
      // This is the AUTH response
      _isAuthenticating = false;

      if (!_connectionCompleter!.isCompleted) {
        if (responseIsError) {
          // _connectionCompleter!.completeError(result, stackTrace);

          // Wrap auth error (using ValkeyServerException if possible)
          final authError = ValkeyConnectionException(
              'Authentication failed: ${response is ValkeyServerException ? response.message : response.toString()}',
              response);
          _connectionCompleter!.completeError(authError, stackTrace);
        } else {
          _connectionCompleter!.complete();
        }
      }
    } else {
      // Use the helper, passing error status correctly
      _tryCompleteCommandFromQueue(result,
          isError: responseIsError, stackTrace: stackTrace);
    }
  }

  // --- Public Command Methods ---

  /// [v2.2.0] Routing Logic
  @override
  Future<dynamic> execute(List<String> command) async {
    final cmdName = command.isNotEmpty ? command[0].toUpperCase() : '';

    // 1. Determine if this is a Read-Only command
    final isReadOnly = _readOnlyCommands.contains(cmdName);

    // 2. Decide Target Client
    ValkeyClient targetClient = this; // Default to Master (this instance)

    if (isReadOnly && _config.readPreference != ReadPreference.master) {
      if (_replicas.isNotEmpty) {
        // We have replicas, use one according to strategy
        targetClient = _selectReplica();
      } else if (_config.readPreference == ReadPreference.replicaOnly) {
        // Strict mode: Fail if no replicas
        throw ValkeyClientException(
            'ReadPreference is replicaOnly but no replicas are available.');
      }
      // If preferReplica and no replicas, we naturally stay with 'this' (Master)
      _log.fine('PreferReplica set but no replicas connected. Using Master.');
    }

    _lastUsedClient =
        targetClient; // Most recently selected client record (for debugging)

    // 3. Execute
    if (targetClient == this) {
      return _executeInternal(command); // Execute on this socket
    } else {
      // Forward to replica
      // Note: We should handle if replica fails (e.g., retry on master if preferReplica)
      try {
        return await targetClient.execute(command);
        // return await targetClient._executeInternal(command);
      } catch (e) {
        // Failover logic for 'preferReplica'
        if (_config.readPreference == ReadPreference.preferReplica) {
          _log.warning('Replica failed, falling back to master: $e');
          _lastUsedClient = this;
          return _executeInternal(command);
        }
        rethrow;
      }
    }
  }

  /// Selects a replica based on LoadBalancingStrategy
  ValkeyClient _selectReplica() {
    if (_replicas.isEmpty) return this; // Should not happen given checks

    if (_config.loadBalancingStrategy == LoadBalancingStrategy.random) {
      return _replicas[_random.nextInt(_replicas.length)];
    } else {
      // Round Robin
      final replica = _replicas[_roundRobinIndex % _replicas.length];
      _roundRobinIndex = (_roundRobinIndex + 1) % _replicas.length;
      return replica;
    }
  }

  /// Executes a raw command. (This will be our main internal method)
  /// Returns a Future that completes with the server's response.
  /// Handle SSUBSCRIBE/SUNSUBSCRIBE futures
  // Removed @override -> Renamed original 'execute' logic to '_executeInternal'
  Future<dynamic> _executeInternal(List<String> command) async {
    final cmdUpper = command.isNotEmpty ? command[0].toUpperCase() : '';

    if (_isInTransaction &&
        cmdUpper != 'EXEC' &&
        cmdUpper != 'DISCARD' &&
        cmdUpper != 'MULTI') {
      // _transactionQueue.add(command);
    }
    // Handle starting or ending a transaction
    if (cmdUpper == 'MULTI') {
      _isInTransaction = true;
      _transactionQueue.clear(); // Clear previous (if any)
    } else if (cmdUpper == 'EXEC' || cmdUpper == 'DISCARD') {
      _isInTransaction = false; // Transaction ends
    }

    // Identify ALL Pub/Sub management commands
    // Add Allowlist here to avoid the message:
    //   e.g., "ValkeyClientException: Cannot execute command SUNSUBSCRIBE while in Pub/Sub mode..."
    const pubSubManagementCommands = {
      'SUBSCRIBE',
      'UNSUBSCRIBE',
      'PSUBSCRIBE',
      'PUNSUBSCRIBE',
      'SSUBSCRIBE',
      'SUNSUBSCRIBE'
    };
    final bool isPubSubManagementCmd =
        pubSubManagementCommands.contains(cmdUpper);

    // Prevent most commands in Pub/Sub mode
    if (_isInPubSubMode) {
      // Allow specific commands needed for Pub/Sub management
      const allowedCommands = {
        'PING',
        'QUIT', // QUIT should probably disconnect
        ...pubSubManagementCommands
      };
      if (!allowedCommands.contains(cmdUpper)) {
        // Throw specific client exception
        return Future.error(ValkeyClientException(
            'Cannot execute command $cmdUpper while in Pub/Sub mode...'));
      }
    }
    // ---------------------------------

    // 1. Create a Completer and add it to the queue.
    Completer<dynamic>? completer;
    // Only add completer if NOT a Pub/Sub management command
    if (!isPubSubManagementCmd && cmdUpper != 'AUTH') {
      // AUTH is handled by _connectionCompleter
      completer = Completer<dynamic>();
      _responseQueue.add(completer);
    }

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
        throw ValkeyConnectionException('Client not connected.');
      }

      const skipWaitCommands = {'AUTH', ...pubSubManagementCommands};
      if (!skipWaitCommands.contains(cmdUpper)) {
        await onConnected; // Wait if connection/auth is still in progress
      }
      _socket!.write(buffer.toString());
    } catch (e, s) {
      // Wrap write error
      final writeError = ValkeyConnectionException(
          'Failed to write command $cmdUpper to socket: $e', e);
      if (completer != null &&
          _responseQueue.contains(completer) &&
          !completer.isCompleted) {
        _responseQueue.remove(completer);
        completer.completeError(writeError, s);
      } else if (completer != null && !completer.isCompleted) {
        completer.completeError(writeError, s);
      } else if (isPubSubManagementCmd) {
        // Error sending Pub/Sub command, fail the relevant completer
        final error =
            ValkeyConnectionException('Failed to send $cmdUpper command: $e');
        if ((cmdUpper == 'SUBSCRIBE' &&
            _subscribeReadyCompleter != null &&
            !_subscribeReadyCompleter!.isCompleted)) {
          _subscribeReadyCompleter!.completeError(error, s);
        } else if (cmdUpper == 'PSUBSCRIBE' &&
            _psubscribeReadyCompleter != null &&
            !_psubscribeReadyCompleter!.isCompleted) {
          _psubscribeReadyCompleter!.completeError(error, s);
        } else if (cmdUpper == 'UNSUBSCRIBE' &&
            _unsubscribeCompleter != null &&
            !_unsubscribeCompleter!.isCompleted) {
          _unsubscribeCompleter!.completeError(error, s);
        } else if (cmdUpper == 'PUNSUBSCRIBE' &&
            _punsubscribeCompleter != null &&
            !_punsubscribeCompleter!.isCompleted) {
          _punsubscribeCompleter!.completeError(error, s);
        }
      }

      // Optional: rethrow e; // Rethrow if needed for higher-level handlers
    }

    // 4. Return the Future
    // return completer.future;

    // Return the correct Future ---
    if (cmdUpper == 'SUBSCRIBE') {
      return _subscribeReadyCompleter?.future ??
          Future.error(
              ValkeyClientException('Subscribe completer not initialized'));
    }
    if (cmdUpper == 'PSUBSCRIBE') {
      return _psubscribeReadyCompleter?.future ??
          Future.error(
              ValkeyClientException('PSubscribe completer not initialized'));
    }
    // if (isPubSubManagementCmd) {
    //    // UNSUBSCRIBE/PUNSUBSCRIBE: Return a new Future tied to the queue
    //    completer = Completer<dynamic>();
    //    _responseQueue.add(completer);
    //    return completer.future;
    // }
    if (cmdUpper == 'UNSUBSCRIBE') {
      return _unsubscribeCompleter?.future ??
          Future.error('Unsubscribe completer not initialized');
    }
    if (cmdUpper == 'PUNSUBSCRIBE') {
      return _punsubscribeCompleter?.future ??
          Future.error('Punsubscribe completer not initialized');
    }

    if (cmdUpper == 'SSUBSCRIBE') {
      return _ssubscribeReadyCompleter?.future ??
          Future.error('Ssubscribe completer not initialized');
    }
    if (cmdUpper == 'SUNSUBSCRIBE') {
      return _sunsubscribeCompleter?.future ??
          Future.error('Sunsubscribe completer not initialized');
    }
    // If it's a regular command (completer is not null)
    if (completer != null) {
      return completer.future.timeout(
        _commandTimeout,
        onTimeout: () {
          // IMPORTANT: Remove the stale completer from the queue
          // to prevent desynchronization on a late response.
          // We check 'contains' for safety, though it should be there.
          if (_responseQueue.contains(completer)) {
            _responseQueue.remove(completer);
          }

          // Throw a clear exception (this will be caught by the example)
          throw ValkeyClientException(
              'Command timed out after ${_commandTimeout.inMilliseconds}ms: ${command.join(' ')}');
        },
      );
    }

    // Fallback for commands that don't queue (e.g., PING in Pub/Sub mode)
    return completer?.future ??
        Future.value(null); // Default case (e.g., PING in Pub/Sub mode)
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

  // --- Atomic Counters (v1.6.0) ---

  @override
  Future<int> incr(String key) async {
    final response = await execute(['INCR', key]);
    // Returns an Integer (:)
    return response as int;
  }

  @override
  Future<int> decr(String key) async {
    final response = await execute(['DECR', key]);
    // Returns an Integer (:)
    return response as int;
  }

  @override
  Future<int> incrBy(String key, int amount) async {
    final response = await execute(['INCRBY', key, amount.toString()]);
    // Returns an Integer (:)
    return response as int;
  }

  @override
  Future<int> decrBy(String key, int amount) async {
    final response = await execute(['DECRBY', key, amount.toString()]);
    // Returns an Integer (:)
    return response as int;
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

  // --- PUB/SUB (v0.9.0 / v0.9.1) ---

  @override
  Future<int> publish(String channel, String message) async {
    // PUBLISH returns an Integer (:) - number of clients received
    final response = await execute(['PUBLISH', channel, message]);
    return response as int;
  }

  @override
  Subscription subscribe(List<String> channels) {
    if (_isInPubSubMode && _subscribedPatterns.isNotEmpty) {
      throw ValkeyClientException(
          'Client is already in subscribed mode. Mixing channel and pattern subscriptions on the same client instance is discouraged due to complexity. Please use separate client instances for channel (subscribe) and pattern (psubscribe) subscriptions.');
    }
    // Ensure channels list is not empty
    if (channels.isEmpty) {
      throw ArgumentError('Channel list cannot be empty for SUBSCRIBE.');
    }

    if (_pubSubController == null || _pubSubController!.isClosed) {
      _pubSubController = StreamController<ValkeyMessage>.broadcast();
    }

    _subscribedChannels.clear(); // Reset channel list for this subscription
    // Initialize or reset ready completer
    if (_subscribeReadyCompleter == null ||
        _subscribeReadyCompleter!.isCompleted) {
      _subscribeReadyCompleter = Completer<void>();
    }
    _expectedSubscribeConfirmations = channels.length;

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
      // Reset state needed if the initial command send fails,
      // ensuring the client returns to a normal operational state.
      _resetPubSubState();
    });

    // Return the Subscription object (immediately) with unsubscribe callback
    return Subscription(
      _pubSubController!.stream,
      _subscribeReadyCompleter!.future,
      onUnsubscribe: () => unsubscribe(channels), // callback added
    );
  }

  @override
  Subscription ssubscribe(List<String> channels) {
    if (_isInPubSubMode && _subscribedPatterns.isNotEmpty) {
      throw ValkeyClientException(
          'Mixing SSUBSCRIBE with PSUBSCRIBE is discouraged.');
    }
    if (channels.isEmpty) {
      throw ArgumentError('Channel list cannot be empty for SSUBSCRIBE.');
    }

    if (_pubSubController == null || _pubSubController!.isClosed) {
      _pubSubController = StreamController<ValkeyMessage>.broadcast();
    }

    if (_ssubscribeReadyCompleter == null ||
        _ssubscribeReadyCompleter!.isCompleted) {
      _ssubscribeReadyCompleter = Completer<void>();
    }
    _expectedSsubscribeConfirmations = channels.length;

    execute(['SSUBSCRIBE', ...channels]).catchError((e, s) {
      if (_ssubscribeReadyCompleter != null &&
          !_ssubscribeReadyCompleter!.isCompleted) {
        _ssubscribeReadyCompleter!.completeError(e, s);
      }
      if (_pubSubController != null && !_pubSubController!.isClosed) {
        _pubSubController!.addError(e, s);
      }
      _resetPubSubState();
    });

    // Return the Subscription object with sunsubscribe callback
    return Subscription(
      _pubSubController!.stream,
      _ssubscribeReadyCompleter!.future,
      onUnsubscribe: () => sunsubscribe(channels), // callback added
    );
  }

  @override
  Future<void> sunsubscribe([List<String> channels = const []]) async {
    if (!_isInPubSubMode) return;

    if (_sunsubscribeCompleter != null &&
        !_sunsubscribeCompleter!.isCompleted) {
      throw ValkeyClientException(
          'Another sunsubscribe operation is in progress.');
    }
    _sunsubscribeCompleter = Completer<void>();

    await execute(['SUNSUBSCRIBE', ...channels]);
  }

  /// Resets the Pub/Sub state (e.g., after unsubscribe or error).
  void _resetPubSubState() {
    // Check if already reset
    if (!_isInPubSubMode && _pubSubController == null) {
      return; // Already clean or nothing to do
    }

    if (_isInPubSubMode) {
      _isInPubSubMode = false;
    }
    _subscribedChannels.clear();
    _subscribedPatterns.clear(); // Clear patterns too

    // Close ready completers if they exist and aren't done
    // Complete completers with error if they are still pending
    if (_subscribeReadyCompleter != null &&
        !_subscribeReadyCompleter!.isCompleted) {
      _subscribeReadyCompleter!.completeError(
          Exception("Subscription cancelled or failed before ready."));
    }
    if (_psubscribeReadyCompleter != null &&
        !_psubscribeReadyCompleter!.isCompleted) {
      _psubscribeReadyCompleter!.completeError(
          Exception("Subscription cancelled or failed before ready."));
    }
    _subscribeReadyCompleter = null;
    _psubscribeReadyCompleter = null;
    _expectedSubscribeConfirmations = 0;
    _expectedPSubscribeConfirmations = 0;

    // Clean up completers for Shared Pub/Sub
    if (_ssubscribeReadyCompleter != null &&
        !_ssubscribeReadyCompleter!.isCompleted) {
      _ssubscribeReadyCompleter!
          .completeError(Exception("Resetting PubSub state"));
    }
    _ssubscribeReadyCompleter = null;
    _expectedSsubscribeConfirmations = 0;

    // Safely close StreamController

    // if (_pubSubController != null && !_pubSubController!.isClosed) {
    //   _pubSubController!.close();
    // }
    // _pubSubController = null;

    // Use the local variable 'controller' for the check
    final controller = _pubSubController; // 1. Copy ref
    _pubSubController = null; // 2. Clear field

    // 3. Check the local variable 'controller', NOT the null field '_pubSubController'
    if (controller != null && !controller.isClosed) {
      // _log.info('Closing StreamController.');
      controller.close();
    } else {
      // _log.info('StreamController already null or closed.');
    }
  }

  // --- Advanced Pub/Sub (v0.10.0) ---

  @override
  Future<void> unsubscribe([List<String> channels = const []]) async {
    if (!_isInPubSubMode || (_subscribedChannels.isEmpty && channels.isEmpty)) {
      return;
    }
    // Send the command and return immediately once sent.
    // The Future completes when the command is sent, not confirmed.
    // Confirmation push messages will update internal state via _handlePubSubMessage.

    // Initialize completer before executing
    if (_unsubscribeCompleter != null && !_unsubscribeCompleter!.isCompleted) {
      throw ValkeyClientException(
          'Another unsubscribe operation is already in progress.');
    }
    _unsubscribeCompleter = Completer<void>();

    // execute() will now return _unsubscribeCompleter.future
    await execute(['UNSUBSCRIBE', ...channels]);

    // try {
    //   await execute(['UNSUBSCRIBE', ...channels]);
    // } catch (e) {
    //   // If sending fails, reset state and rethrow
    //   _resetPubSubState();
    //   rethrow;
    // }

    // State (_isInPubSubMode, _subscribedChannels) updated in _handlePubSubMessage
    // Note: State might not be fully updated (_isInPubSubMode = false)
    // immediately after this Future completes. State updates rely on push messages.
  }

  @override
  Subscription psubscribe(List<String> patterns) {
    if (_isInPubSubMode && _subscribedChannels.isNotEmpty) {
      // Mixing SUBSCRIBE and PSUBSCRIBE on the same connection can be complex.
      // For simplicity, let's restrict to one mode or the other for now,
      // or require PSUBSCRIBE only when not channel-subscribed.
      // Let's allow it but state management gets tricky.

      // _log.info('Warning: Mixing channel and pattern subscriptions might lead to unexpected behavior.');
      // throw Exception('Cannot mix PSUBSCRIBE with active channel subscriptions on the same client.');
      // throw ValkeyClientException('Mixing channel and pattern subscriptions is discouraged. Please use separate client instances.');

      throw ValkeyClientException(
          'Mixing channel and pattern subscriptions on the same client instance is discouraged due to complexity. Please use separate client instances for channel (subscribe) and pattern (psubscribe) subscriptions.');
    }
    if (patterns.isEmpty) {
      throw ArgumentError('Pattern list cannot be empty for PSUBSCRIBE.');
    }
    if (_pubSubController == null || _pubSubController!.isClosed) {
      _pubSubController = StreamController<ValkeyMessage>.broadcast();
    }

    // Initialize or reset ready completer for this command
    if (_psubscribeReadyCompleter == null ||
        _psubscribeReadyCompleter!.isCompleted) {
      _psubscribeReadyCompleter = Completer<void>();
    }
    _expectedPSubscribeConfirmations = patterns.length;

    // Send the command
    execute(['PSUBSCRIBE', ...patterns]).catchError((e, s) {
      if (_psubscribeReadyCompleter != null &&
          !_psubscribeReadyCompleter!.isCompleted) {
        _psubscribeReadyCompleter!.completeError(e, s);
      }
      if (_pubSubController != null && !_pubSubController!.isClosed) {
        _pubSubController!.addError(e, s);
      }
      // Reset state needed if the initial command send fails,
      // ensuring the client returns to a normal operational state.
      _resetPubSubState();
    });

    // Return the Subscription object (immediately) with punsubscribe callback
    return Subscription(
      _pubSubController!.stream,
      _psubscribeReadyCompleter!.future,
      onUnsubscribe: () => punsubscribe(patterns), // callback added
    );
  }

  @override
  Future<void> punsubscribe([List<String> patterns = const []]) async {
    if (!_isInPubSubMode || (_subscribedPatterns.isEmpty && patterns.isEmpty)) {
      return;
    }

    // Initialize completer before executing
    if (_punsubscribeCompleter != null &&
        !_punsubscribeCompleter!.isCompleted) {
      throw ValkeyClientException(
          'Another punsubscribe operation is already in progress.');
    }
    _punsubscribeCompleter = Completer<void>();

    // execute() will now return _punsubscribeCompleter.future
    await execute(['PUNSUBSCRIBE', ...patterns]);

    // try {
    //   await execute(['PUNSUBSCRIBE', ...patterns]);
    // } catch (e) {
    //   _resetPubSubState();
    //   rethrow;
    // }

    // State updated in _handlePubSubMessage
  }

  // --- TRANSACTION (v0.11.0) ---

  @override
  Future<String> multi() async {
    // MULTI itself shouldn't be queued if already in transaction
    if (_isInTransaction) {
      throw Exception('Cannot call MULTI inside an existing transaction.');
    }
    final response = await execute(['MULTI']);
    // Server should respond '+OK'
    return response as String;
  }

  @override
  Future<List<dynamic>?> exec() async {
    if (!_isInTransaction) {
      throw Exception('Cannot call EXEC without MULTI.');
    }
    final response = await execute(['EXEC']);
    // Server responds with an Array (*) of responses
    // or Null ($-1 or *-1) if transaction was aborted (e.g., WATCH)
    if (response == null) {
      return null;
    }
    return response as List<dynamic>;
  }

  @override
  Future<String> discard() async {
    if (!_isInTransaction) {
      throw Exception('Cannot call DISCARD without MULTI.');
    }
    final response = await execute(['DISCARD']);
    // Server responds '+OK'
    return response as String;
  }

  // --- PUBSUB INTROSPECTION (v0.12.0) ---

  @override
  Future<List<String?>> pubsubChannels([String? pattern]) async {
    final command = ['PUBSUB', 'CHANNELS'];
    if (pattern != null) {
      command.add(pattern);
    }
    // Returns an Array (*) of channel names (Bulk Strings)
    final response = await execute(command);
    return (response as List<dynamic>?)?.cast<String?>() ?? [];
  }

  @override
  Future<Map<String, int>> pubsubNumSub(List<String> channels) async {
    final command = ['PUBSUB', 'NUMSUB', ...channels];
    // Returns a flat Array: [channel1, count1, channel2, count2, ...]
    final response = await execute(command) as List<dynamic>?;
    if (response == null || response.isEmpty) return {};

    final map = <String, int>{};
    for (var i = 0; i < response.length; i += 2) {
      // Server returns channel as String, count as Integer
      map[response[i] as String] = response[i + 1] as int;
    }
    return map;
  }

  @override
  Future<int> pubsubNumPat() async {
    // Returns an Integer (:)
    final response = await execute(['PUBSUB', 'NUMPAT']);
    return response as int;
  }

  @override
  Future<int> spublish(String channel, String message) async {
    final response = await execute(['SPUBLISH', channel, message]);
    return response as int;
  }

  @override
  Future<List<ClusterSlotRange>> clusterSlots() async {
    try {
      // 1. Execute the command
      final dynamic response = await execute(['CLUSTER', 'SLOTS']);

      // 2. Parse the response using the dedicated parser (top-level function)
      return parseClusterSlotsResponse(response);
    } catch (e, s) {
      // 3. Use the v1.1.0 logger
      _log.severe('Error executing CLUSTER SLOTS: $e', e, s);
      // 4. Re-throw v1.1.0 exceptions
      // Re-throw as a ValkeyException if it's not one already
      if (e is ValkeyException) rethrow;
      // Wrap unknown errors
      throw ValkeyClientException('Failed to execute CLUSTER SLOTS: $e');
    }
  }

  // --- Socket Lifecycle Handlers ---

  void _handleSocketError(Object error, StackTrace stackTrace) {
    final connEx =
        ValkeyConnectionException('Socket error occurred: $error', error);
    // Call cleanup FIRST to release resources immediately
    _cleanup(); // Close socket etc. FIRST

    // Complete connection completer if it's still pending
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.completeError(connEx, stackTrace);
    }

    // Fail any pending commands in the queue
    _failAllPendingCommands(connEx, stackTrace);

    // Add error to Pub/Sub stream AFTER failing commands
    if (_pubSubController != null && !_pubSubController!.isClosed) {
      // --- Close PubSub stream on error ---
      _pubSubController!.addError(connEx, stackTrace);
    }

    _resetPubSubState(); // Reset Pub/Sub state AFTER handling errors
  }

  void _handleSocketDone() {
    _cleanup(); // Close socket etc. FIRST

    final connEx = ValkeyConnectionException(
        'Connection closed unexpectedly by the server.');
    final stackTrace = StackTrace.current; // Get current stack for context

    // Complete connection completer if it's still pending
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.completeError(
          connEx, stackTrace); // Connection closed prematurely before setup.
    }

    // Fail any pending commands
    _failAllPendingCommands(connEx, stackTrace);

    // Add error to Pub/Sub stream AFTER failing commands
    if (_pubSubController != null && !_pubSubController!.isClosed) {
      // Close PubSub stream on disconnect
      _pubSubController!.addError(connEx, stackTrace);
    }
    _resetPubSubState(); // Reset Pub/Sub state AFTER handling errors
  }

  void _failAllPendingCommands(Object error, [StackTrace? stackTrace]) {
    // _log.info('Failing all ${_responseQueue.length} pending commands due to error.');
    while (_responseQueue.isNotEmpty) {
      final completer = _responseQueue.removeFirst();
      if (!completer.isCompleted) {
        // Avoid completing already completed futures
        completer.completeError(error, stackTrace);
      }
    }
  }

  /// Sends the AUTH command in RESP Array format. Internal use only.
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
      if (_socket == null &&
          _connectionCompleter != null &&
          !_connectionCompleter!.isCompleted) {
        throw ValkeyConnectionException(
            'Socket closed before AUTH could be sent.');
      }
      // Send to socket
      _socket?.write(buffer.toString());
    } catch (e, s) {
      final authError =
          ValkeyConnectionException('Failed to send AUTH command: $e', e);
      // If sending AUTH fails, connection setup fails
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError(authError, s);
      }
      _cleanup();
    }
  }

  @override
  Future<void> close() async {
    // [v2.2.0] 1. Close all replicas first
    // We iterate backwards or just loop to close them.
    for (final replica in _replicas) {
      try {
        await replica.close();
      } catch (_) {
        // Ignore errors during replica closure
      }
    }
    _replicas.clear();

    // 2. Close Master connection and cleanup
    // await sub?.cancel().catchError((_) { /* Ignore errors on cancel */ });
    // try {
    await _subscription?.cancel(); // Cancel listening
    // } catch (_) {}

    // try {
    // await sock?.close().catchError((_) { /* Ignore errors on close */ });
    await _socket?.close(); // Graceful close socket if possible
    // } catch (_) {}

    _cleanup(); // Then cleanup resources. Ensure resources are released

    // Reset pub/sub state immediately
    _resetPubSubState(); // Reset pubsub state
  }

  /// Internal helper to clean up socket and subscription resources.
  /// Cleans up resources like socket and subscription. MUST be safe to call multiple times.
  void _cleanup() {
    // try {
    _subscription
        ?.cancel()
        .catchError((_) {}); // Errors are likely if already closed/cancelled
    // } catch (_) {}

    // try {
    _socket?.destroy(); // Force close // Ensure the socket is fully destroyed.
    // } catch (_) {}

    _socket = null; // Prevent further write attempts
    _subscription = null; // Prevent further listen events
    _buffer.clear();
    _isAuthenticating = false;

    // Do not reset _isInPubSubMode here, rely on _resetPubSubState if needed via handlers
    // Do not create a new completer here, let connect() handle it.
    // e.g., _isInPubSubMode = false; // Reset pubsub mode on cleanup
  }

  @override
  Future<String> echo(String message) async {
    final response = await execute(['ECHO', message]);
    return response as String;
  }
}
