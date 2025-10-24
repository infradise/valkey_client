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

  // --- COMMANDS ---

  /// PINGs the server.
  Future<String> ping([String? message]);

  /// Gets the value of [key].
  /// Returns `null` if the key does not exist.
  Future<String?> get(String key);

  /// Sets [key] to [value].
  /// Returns a simple string reply (usually 'OK').
  Future<String> set(String key, String value);

  /// Gets the values of all specified [keys].
  /// Returns a list of strings, with `null` for keys that do not exist.
  Future<List<String?>> mget(List<String> keys);
}
