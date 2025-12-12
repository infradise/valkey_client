/// This library provides a Redis-compatible interface.
///
/// It allows users to use the client with familiar class names (e.g., [RedisClient], [RedisException]).
/// This is a wrapper around `valkey_client` to provide a seamless developer experience (DX)
/// for those migrating from Redis or preferring Redis terminology.
library;

import 'package:valkey_client/valkey_client.dart';

// --- Clients ---

/// Alias for [ValkeyClient]. Use this for Standalone/Sentinel connections.
typedef RedisClient = ValkeyClient;

/// Alias for [ValkeyClusterClient]. Use this for Cluster connections.
typedef RedisClusterClient = ValkeyClusterClient;

/// Alias for [ValkeyPool]. Use this for connection pooling.
typedef RedisPool = ValkeyPool;

// --- Configuration ---

/// Alias for [ValkeyConnectionSettings].
typedef RedisConnectionSettings = ValkeyConnectionSettings;

/// Alias for [ValkeyLogLevel].
typedef RedisLogLevel = ValkeyLogLevel;

// --- Data Models ---

/// Alias for [ValkeyMessage]. Represents a Pub/Sub message.
typedef RedisMessage = ValkeyMessage;

// --- Exceptions (Crucial for try-catch blocks) ---

/// Alias for [ValkeyException]. The base class for all exceptions.
typedef RedisException = ValkeyException;

/// Alias for [ValkeyConnectionException]. Thrown on network/socket errors.
typedef RedisConnectionException = ValkeyConnectionException;

/// Alias for [ValkeyServerException]. Thrown when the server responds with an error.
typedef RedisServerException = ValkeyServerException;

/// Alias for [ValkeyClientException]. Thrown on invalid API usage.
typedef RedisClientException = ValkeyClientException;

/// Alias for [ValkeyParsingException]. Thrown on protocol parsing errors.
typedef RedisParsingException = ValkeyParsingException;
