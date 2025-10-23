/// Defines the base functionality for a Valkey client.
///
/// This abstract class represents the public API contract that users
/// can depend on or use for mocking.
abstract class ValkeyClientBase {
  /// A Future that completes once the connection and authentication are successful.
  Future<void> get onConnected;

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

  /// Executes a raw command.
  Future<dynamic> execute(List<String> command);

  /// PINGs the server.
  Future<String> ping([String? message]);
}
