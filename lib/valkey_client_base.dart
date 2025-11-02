import 'dart:async';

/// Represents a message received from a subscribed channel or pattern.
class ValkeyMessage {
  /// The channel the message was sent to.
  ///
  /// This is `null` if the message was received via a pattern subscription (`pmessage`).
  final String? channel;

  /// The message payload.
  final String message;

  /// The pattern that matched the channel (only for `pmessage`).
  ///
  /// This is `null` if the message was received via a channel subscription (`message`).
  final String? pattern;

  ValkeyMessage({this.channel, required this.message, this.pattern});

  @override
  String toString() {
    if (pattern != null) {
      return 'ValkeyMessage{pattern: $pattern, channel: $channel, message: $message}';
    } else {
      return 'Message{channel: $channel, message: $message}';
    }
  }
}

/// Represents an active subscription to channels or patterns.
///
/// Returned by `subscribe()` and `psubscribe()`.
class Subscription {
  /// A broadcast stream that emits messages received on the subscribed channels/patterns.
  ///
  /// Listen to this stream to receive `ValkeyMessage` objects.
  final Stream<ValkeyMessage> messages;

  /// A [Future] that completes when the initial subscription to all requested
  /// channels/patterns is confirmed by the server.
  ///
  /// You MUST `await` this future *before* publishing messages to ensure
  /// the subscription is active.
  ///
  /// ```dart
  /// final sub = client.subscribe(['my-channel']);
  /// await sub.ready; // Wait for confirmation
  /// await publisher.publish('my-channel', 'hello');
  /// ```
  final Future<void> ready;

  Subscription(this.messages, this.ready);
}


/// The abstract base class for a Valkey client.
///
/// This interface defines the public API for interacting with a Valkey/Redis server.
/// It covers core commands, key management, transactions, and Pub/Sub.
abstract class ValkeyClientBase {
  /// A [Future] that completes once the connection and authentication (if required)
  /// are successfully established.
  ///
  /// Use this to wait for the client to be ready after calling `connect()`:
  /// ```dart
  /// client.connect();
  /// await client.onConnected;
  /// print('Client is connected!');
  /// ```
  ///
  /// Throws a [ValkeyClientException] if accessed before `connect()` is called
  /// or if the connection attempt failed.
  Future<void> get onConnected;

  /// Connects to the Valkey server.
  ///
  /// If [host], [port], [username], or [password] are provided,
  /// they will override the default values set in the constructor.
  ///
  /// Throws a [ValkeyConnectionException] if the socket connection fails
  /// (e.g., connection refused) or if authentication fails (e.g., wrong password).
  Future<void> connect({
    String? host,
    int? port,
    String? username,
    String? password,
  });

  /// Closes the connection to the server.
  ///
  /// This cancels any active subscriptions and cleans up resources.
  Future<void> close();

  /// Executes a raw command.
  ///
  /// Note: This is a low-level method. Prefer using the specific command
  /// methods (e.g., `get`, `set`) when available.
  ///
  /// This method should NOT be used for Pub/Sub management commands
  /// (`SUBSCRIBE`, `UNSUBSCRIBE`, etc.), as they are handled differently.
  Future<dynamic> execute(List<String> command);

  /// PINGs the server.
  ///
  /// Returns 'PONG' if no [message] is provided, otherwise returns the [message].
  /// Throws a [ValkeyServerException] if an error occurs.
  Future<String> ping([String? message]);

  /// Gets the value of [key].
  ///
  /// Returns the string value if the key exists, or `null` if the key does not exist.
  /// Throws a [ValkeyServerException] if the key holds a non-string value.
  Future<String?> get(String key);

  /// Sets [key] to [value].
  ///
  /// Returns 'OK' if successful.
  /// Throws a [ValkeyServerException] if an error occurs.
  Future<String> set(String key, String value);

  /// Gets the values of all specified [keys].
  ///
  /// Returns a list of strings. For keys that do not exist, `null` is returned
  /// in the corresponding list position.
  Future<List<String?>> mget(List<String> keys);

  /// Gets the value of [field] in the hash stored at [key].
  ///
  /// Returns `null` if the field or key does not exist.
  /// Throws a [ValkeyServerException] if the key holds a non-hash value.
  Future<String?> hget(String key, String field);

  /// Sets [field] in the hash stored at [key] to [value].
  ///
  /// Returns `1` if [field] is a new field and was set,
  /// or `0` if [field] already existed and was updated.
  /// Throws a [ValkeyServerException] if the key holds a non-hash value.
  Future<int> hset(String key, String field, String value);

  /// Gets all fields and values of the hash stored at [key].
  ///
  /// Returns a `Map<String, String>`.
  /// Returns an empty map if the key does not exist.
  /// Throws a [ValkeyServerException] if the key holds a non-hash value.
  Future<Map<String, String>> hgetall(String key);

  /// Prepends [value] to the list stored at [key].
  ///
  /// Returns the length of the list after the push operation.
  /// Throws a [ValkeyServerException] if the key holds a non-list value.
  Future<int> lpush(String key, String value);

  /// Appends [value] to the list stored at [key].
  ///
  /// Returns the length of the list after the push operation.
  /// Throws a [ValkeyServerException] if the key holds a non-list value.
  Future<int> rpush(String key, String value);

  /// Removes and returns the first element of the list stored at [key].
  ///
  /// Returns `null` if the key does not exist or the list is empty.
  /// Throws a [ValkeyServerException] if the key holds a non-list value.
  Future<String?> lpop(String key);

  /// Removes and returns the last element of the list stored at [key].
  ///
  /// Returns `null` if the key does not exist or the list is empty.
  /// Throws a [ValkeyServerException] if the key holds a non-list value.
  Future<String?> rpop(String key);

  /// Returns the specified elements of the list stored at [key].
  ///
  /// [start] and [stop] are zero-based indexes.
  /// Use `0` and `-1` to get all elements.
  /// Returns an empty list if the key does not exist.
  /// Throws a [ValkeyServerException] if the key holds a non-list value.
  Future<List<String?>> lrange(String key, int start, int stop);

  /// Adds [member] to the set stored at [key].
  ///
  /// Returns `1` if the member was added, `0` if it already existed.
  /// Throws a [ValkeyServerException] if the key holds a non-set value.
  Future<int> sadd(String key, String member);

  /// Removes [member] from the set stored at [key].
  ///
  /// Returns `1` if the member was removed, `0` if it did not exist.
  /// Throws a [ValkeyServerException] if the key holds a non-set value.
  Future<int> srem(String key, String member);

  /// Returns all members of the set stored at [key].
  ///
  /// Returns an empty list if the key does not exist.
  /// Throws a [ValkeyServerException] if the key holds a non-set value.
  Future<List<String?>> smembers(String key);

  /// Adds [member] with the specified [score] to the sorted set stored at [key].
  ///
  /// Returns `1` if the member was added, `0` if it was updated.
  /// Throws a [ValkeyServerException] if the key holds a non-sorted-set value.
  Future<int> zadd(String key, double score, String member);

  /// Removes [member] from the sorted set stored at [key].
  ///
  /// Returns `1` if the member was removed, `0` if it did not exist.
  /// Throws a [ValkeyServerException] if the key holds a non-sorted-set value.
  Future<int> zrem(String key, String member);

  /// Returns the specified range of members in the sorted set stored at [key],
  /// ordered from lowest to highest score.
  ///
  /// [start] and [stop] are zero-based indexes. Use `0` and `-1` for all.
  /// Returns an empty list if the key does not exist.
  /// Throws a [ValkeyServerException] if the key holds a non-sorted-set value.
  Future<List<String?>> zrange(String key, int start, int stop);

  /// Deletes the specified [key].
  ///
  /// Returns the number of keys that were removed (0 or 1).
  Future<int> del(String key);

  /// Checks if [key] exists.
  ///
  /// Returns `1` if the key exists, `0` otherwise.
  Future<int> exists(String key);

  /// Sets a timeout on [key] in seconds.
  ///
  /// Returns `1` if the timeout was set, `0` if the key doesn't exist.
  Future<int> expire(String key, int seconds);


  /// Gets the remaining time to live of a [key] in seconds.
  ///
  /// Returns:
  /// * `-1` if the key exists but has no associated expire.
  /// * `-2` if the key does not exist.
  /// * A positive integer representing the remaining TTL.
  Future<int> ttl(String key);

  /// Posts a [message] to the given [channel].
  ///
  /// Returns the number of clients that received the message.
  Future<int> publish(String channel, String message);

  /// Subscribes the client to the specified [channels].
  ///
  /// Returns a [Subscription] object containing:
  /// 1. `messages`: A `Stream<ValkeyMessage>` to listen for incoming messages.
  /// 2. `ready`: A `Future<void>` that completes when the server confirms
  ///    subscription to all requested channels.
  ///
  /// You MUST `await subscription.ready` before assuming the subscription is active.
  ///
  /// Throws a [ValkeyClientException] if mixing channel and pattern subscriptions.
  Subscription subscribe(List<String> channels);

  /// Unsubscribes the client from the given [channels], or all channels if none are given.
  ///
  /// The [Future] completes when the server confirms the unsubscription.
  Future<void> unsubscribe([List<String> channels = const []]);

  /// Subscribes the client to the given [patterns] (e.g., "log:*").
  ///
  /// Returns a [Subscription] object (see `subscribe` for details).
  /// You MUST `await subscription.ready` before assuming the subscription is active.
  ///
  /// Throws a [ValkeyClientException] if mixing channel and pattern subscriptions.
  Subscription psubscribe(List<String> patterns);

  /// Unsubscribes the client from the given [patterns], or all patterns if none are given.
  ///
  /// The [Future] completes when the server confirms the unsubscription.
  Future<void> punsubscribe([List<String> patterns = const []]);

  /// Lists the currently active channels.
  ///
  /// [pattern] is an optional glob-style pattern.
  /// Returns an empty list if no channels are active.
  Future<List<String?>> pubsubChannels([String? pattern]);

  /// Returns the number of subscribers for the specified [channels].
  ///
  /// Returns a `Map` where keys are the channel names
  /// and values are the number of subscribers.
  Future<Map<String, int>> pubsubNumSub(List<String> channels);

  /// Returns the number of subscriptions to patterns.
  Future<int> pubsubNumPat();

  /// Marks the start of a transaction block.
  ///
  /// Subsequent commands will be queued by the server until `exec()` is called.
  /// Returns 'OK'.
  Future<String> multi();

  /// Executes all commands queued after `multi()`.
  ///
  /// Returns a `List<dynamic>` of replies for each command in the transaction.
  /// Returns `null` if the transaction was aborted (e.g., due to a `WATCH` failure).
  /// Throws a [ValkeyServerException] (e.g., `EXECABORT`) if the transaction
  /// was discarded due to a command syntax error within the `MULTI` block.
  Future<List<dynamic>?> exec();

  /// Discards all commands queued after `multi()`.
  ///
  /// Returns 'OK'.
  Future<String> discard();
}
