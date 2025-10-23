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