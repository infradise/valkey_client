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

  // --- PING (v0.2.0) ---

  /// PINGs the server.
  Future<String> ping([String? message]);

  // --- SET/GET (v0.3.0) ---

  /// Gets the value of [key].
  /// Returns `null` if the key does not exist.
  Future<String?> get(String key);

  /// Sets [key] to [value].
  /// Returns a simple string reply (usually 'OK').
  Future<String> set(String key, String value);

  // --- MGET (v0.4.0) ---

  /// Gets the values of all specified [keys].
  /// Returns a list of strings, with `null` for keys that do not exist.
  Future<List<String?>> mget(List<String> keys);

  // --- HASH (v0.5.0) ---

  /// Gets the value of [field] in the hash stored at [key].
  /// Returns `null` if the field or key does not exist.
  Future<String?> hget(String key, String field);

  /// Sets [field] in the hash stored at [key] to [value].
  /// Returns `1` if [field] is a new field, `0` if [field] was updated.
  Future<int> hset(String key, String field, String value);

  /// Gets all fields and values of the hash stored at [key].
  /// Returns an empty map if the key does not exist.
  Future<Map<String, String>> hgetall(String key);

  // --- LIST (v0.6.0) ---

  /// Prepends [value] to the list stored at [key].
  /// Returns the length of the list after the push.
  Future<int> lpush(String key, String value);

  /// Appends [value] to the list stored at [key].
  /// Returns the length of the list after the push.
  Future<int> rpush(String key, String value);

  /// Removes and returns the first element of the list stored at [key].
  /// Returns `null` if the key does not exist or the list is empty.
  Future<String?> lpop(String key);

  /// Removes and returns the last element of the list stored at [key].
  /// Returns `null` if the key does not exist or the list is empty.
  Future<String?> rpop(String key);

  /// Returns the specified elements of the list stored at [key].
  /// [start] and [stop] are zero-based indexes. (e.g., 0, -1 for all)
  Future<List<String?>> lrange(String key, int start, int stop);
}
