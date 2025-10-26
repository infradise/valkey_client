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

  // --- SET (v0.7.0) ---

  /// Adds [member] to the set stored at [key].
  /// Returns `1` if the member was added, `0` if it already existed.
  Future<int> sadd(String key, String member);

  /// Removes [member] from the set stored at [key].
  /// Returns `1` if the member was removed, `0` if it did not exist.
  Future<int> srem(String key, String member);

  /// Returns all members of the set stored at [key].
  Future<List<String?>> smembers(String key);

  // --- SORTED SET (v0.7.0) ---

  /// Adds [member] with the specified [score] to the sorted set stored at [key].
  /// Returns `1` if the member was added, `0` if it was updated.
  Future<int> zadd(String key, double score, String member);

  /// Removes [member] from the sorted set stored at [key].
  /// Returns `1` if the member was removed, `0` if it did not exist.
  Future<int> zrem(String key, String member);

  /// Returns the specified range of members in the sorted set stored at [key],
  /// ordered from lowest to highest score.
  Future<List<String?>> zrange(String key, int start, int stop);

  // --- KEY MANAGEMENT (v0.8.0) ---

  /// Deletes the specified [key].
  /// Returns the number of keys that were removed (0 or 1).
  Future<int> del(String key);

  /// Checks if [key] exists.
  /// Returns `1` if the key exists, `0` otherwise.
  Future<int> exists(String key);

  /// Sets a timeout on [key] in seconds.
  /// Returns `1` if the timeout was set, `0` if the key doesn't exist.
  Future<int> expire(String key, int seconds);

  /// Gets the remaining time to live of a [key] in seconds.
  /// Returns `-1` if the key exists but has no associated expire.
  /// Returns `-2` if the key does not exist.
  Future<int> ttl(String key);

  // --- PUB/SUB (v0.9.0) ---

  /// Posts a [message] to the given [channel].
  /// Returns the number of clients that received the message.
  Future<int> publish(String channel, String message);

  /// Subscribes the client to the specified [channels].
  /// Returns a Stream that emits messages received on the subscribed channels.
  ///
  /// IMPORTANT: Once subscribed, the client can only execute UNSUBSCRIBE,
  /// PSUBSCRIBE, PUNSUBSCRIBE, PING, and QUIT commands.
  Stream<ValkeyMessage> subscribe(List<String> channels);

  // TODO: Add unsubscribe, psubscribe, punsubscribe later
}

/// Represents a message received from a subscribed channel.
class ValkeyMessage {
  final String channel;
  final String message;

  ValkeyMessage(this.channel, this.message);

  @override
  String toString() => 'Message{channel: $channel, message: $message}';
}