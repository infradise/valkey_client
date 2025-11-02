/// The base class for all exceptions thrown by the valkey_client package.
class ValkeyException implements Exception {
  final String message;

  ValkeyException(this.message);

  @override
  String toString() => 'ValkeyException: $message';
}

/// Thrown when the client fails to connect to the server (e.g., connection refused).
/// Corresponds to socket-level errors.
class ValkeyConnectionException extends ValkeyException {
  /// The original socket exception, if available.
  final Object? originalException;

  ValkeyConnectionException(super.message, [this.originalException]);

  @override
  String toString() => 'ValkeyConnectionException: $message (Original: $originalException)';
}

/// Thrown when the Valkey server returns an error reply (e.g., -ERR, -WRONGPASS).
/// These are errors reported by the server itself.
class ValkeyServerException extends ValkeyException {
  /// The error code or type returned by the server (e.g., "ERR", "WRONGPASS").
  final String code;

  ValkeyServerException(super.message)
      : code = message.split(' ').first; // Extract 'ERR' from 'ERR message'

  @override
  String toString() => 'ValkeyServerException($code): $message';
}

/// Thrown when the client is in a state that does not allow the command.
/// (e.g., calling EXEC without MULTI, calling PUBLISH while not subscribed).
class ValkeyClientException extends ValkeyException {
  ValkeyClientException(super.message);

  @override
  String toString() => 'ValkeyClientException: $message';
}

/// Thrown if the client cannot parse the server's response.
/// This may indicate corrupted data or a bug in the client.
class ValkeyParsingException extends ValkeyException {
  ValkeyParsingException(super.message);

  @override
  String toString() => 'ValkeyParsingException: $message';
}