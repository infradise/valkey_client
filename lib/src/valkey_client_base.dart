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

  // --- PUB/SUB (v0.9.0 / v0.9.1) ---

  /// Posts a [message] to the given [channel].
  /// Returns the number of clients that received the message.
  Future<int> publish(String channel, String message);

  /// IMPORTANT: Once subscribed, the client can only execute UNSUBSCRIBE,
  /// PSUBSCRIBE, PUNSUBSCRIBE, PING, and QUIT commands.

  /// Subscribes the client to the specified [channels].
  /// Returns a [Subscription] object containing the message stream
  /// and a future indicating when the subscription is ready.
  Subscription subscribe(List<String> channels);

  // --- ADVANCED PUB/SUB (v0.10.0) ---

  /// Unsubscribes the client from the given [channels], or all channels if none are given.
  /// The Future completes when the server confirms *all* relevant subscriptions are cancelled.
  Future<void> unsubscribe([List<String> channels = const []]);

  /// Subscribes the client to the given [patterns].
  Subscription psubscribe(List<String> patterns);

  /// Unsubscribes the client from the given [patterns], or all patterns if none are given.
  /// The Future completes when the server confirms *all* relevant subscriptions are cancelled.
  Future<void> punsubscribe([List<String> patterns = const []]);

  // --- TRANSACTION (v0.11.0) ---

  /// Marks the start of a transaction block.
  /// Subsequent commands will be queued until EXEC is called.
  /// Returns 'OK'.
  Future<String> multi();

  /// Executes all commands queued after MULTI.
  /// Returns a list of replies for each command in the transaction,
  /// or null if the transaction was aborted (e.g., due to WATCH).
  Future<List<dynamic>?> exec();

  /// Discards all commands queued after MULTI.
  /// Returns 'OK'.
  Future<String> discard();
}

/// Represents a message received from a subscribed channel or pattern.
class ValkeyMessage {
  /// The channel the message was sent to. Null for pattern messages.
  final String? channel;

  /// The message payload.
  final String message;

  /// The pattern that matched the channel (only for pmessage). Null otherwise.
  final String? pattern;

  ValkeyMessage({this.channel, required this.message, this.pattern});

  @override
  String toString() {
    if (pattern != null) {
      return 'Message{pattern: $pattern, channel: $channel, message: $message}';
    } else {
      return 'Message{channel: $channel, message: $message}';
    }
  }
}

/// Represents an active subscription to channels or patterns.
class Subscription {
  /// A stream that emits messages received on the subscribed channels/patterns.
  final Stream<ValkeyMessage> messages;

  /// A future that completes when the initial subscription to all requested
  /// channels/patterns is confirmed by the server.
  final Future<void> ready;
  // TODO: Add an unsubscribe() / punsubscribe() method here for convenience later.

  Subscription(this.messages, this.ready);
}
