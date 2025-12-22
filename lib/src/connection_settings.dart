import 'dart:io';

/// Configuration for a Valkey connection.
/// Holds all configuration options for creating a new connection.
///
/// Used by [ValkeyPool] to create new client instances.
class ValkeyConnectionSettings {
  /// The host of the Valkey server.
  final String host;

  /// The port of the Valkey server.
  final int port;

  /// The username for ACL authentication (Valkey 6.0+).
  final String? username;

  /// The password for authentication.
  final String? password;

  /// The timeout for database commands.
  /// The maximum duration to wait for a response to any command.
  /// Defaults to 10 seconds.
  final Duration commandTimeout;

  /// The timeout for establishing a socket connection.
  final Duration connectTimeout;

  // --- v2.0.0 SSL/TLS Support ---

  /// Whether to use an encrypted SSL/TLS connection.
  /// Default is `false`.
  final bool useSsl;

  /// Custom SecurityContext for advanced SSL configurations
  /// (e.g., providing a client certificate or a custom CA).
  final SecurityContext? sslContext;

  /// Callback to handle bad certificates (e.g., self-signed certificates in dev).
  /// Returns `true` to allow the connection, `false` to abort.
  final bool Function(X509Certificate)? onBadCertificate;

  ValkeyConnectionSettings({
    required this.host, // '127.0.0.1'
    required this.port, // 6379
    // this.host = '127.0.0.1',
    // this.port = 6379,

    this.username,
    this.password,
    this.commandTimeout = const Duration(seconds: 10),
    this.connectTimeout = const Duration(seconds: 10),
    this.useSsl = false,
    this.sslContext,
    this.onBadCertificate,
  });

  /// Creates a copy of this settings object with the given fields replaced.
  ValkeyConnectionSettings copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    Duration? commandTimeout,
    Duration? connectTimeout,
    bool? useSsl,
    SecurityContext? sslContext,
    bool Function(X509Certificate)? onBadCertificate,
  }) => ValkeyConnectionSettings(
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      commandTimeout: commandTimeout ?? this.commandTimeout,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      useSsl: useSsl ?? this.useSsl,
      sslContext: sslContext ?? this.sslContext,
      onBadCertificate: onBadCertificate ?? this.onBadCertificate,
    );
}
