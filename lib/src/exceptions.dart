/// The base class for all exceptions thrown by the valkey_client package.
class ValkeyException implements Exception {
  final String message;

  ValkeyException(this.message);

  @override
  String toString() => 'ValkeyException: $message';
}

/// Thrown when the client fails to connect to the server (e.g., connection refused)
/// or if an established connection is lost.
/// Corresponds to socket-level or network errors.
class ValkeyConnectionException extends ValkeyException {
  /// The original socket exception (e.g., `SocketException`) or error, if available.
  final Object? originalException;

  ValkeyConnectionException(super.message, [this.originalException]);

  @override
  String toString() => 'ValkeyConnectionException: $message (Original: $originalException)';
}

/// Thrown when the Valkey server returns an error reply (e.g., -ERR, -WRONGPASS).
/// These are errors reported by the server itself, indicating a command
/// could not be processed.
class ValkeyServerException extends ValkeyException {
  /// The error code or type returned by the server (e.g., "ERR", "WRONGPASS", "EXECABORT").
  final String code;

  ValkeyServerException(super.message)
      : code = message.split(' ').first;

  @override
  String toString() => 'ValkeyServerException($code): $message';
}

/// Thrown when a command is issued in an invalid client state.
///
/// Examples:
/// * Calling `EXEC` without `MULTI`.
/// * Calling `PUBLISH` while the client is in Pub/Sub mode.
/// * Mixing `SUBSCRIBE` and `PSUBSCRIBE` on the same client.
class ValkeyClientException extends ValkeyException {
  ValkeyClientException(super.message);

  @override
  String toString() => 'ValkeyClientException: $message';
}

/// Thrown if the client cannot parse the server's response.
///
/// This may indicate corrupted data, a bug in the client,
/// or an unsupported RESP (Redis Serialization Protocol) version.
class ValkeyParsingException extends ValkeyException {
  ValkeyParsingException(super.message);

  @override
  String toString() => 'ValkeyParsingException: $message';
}