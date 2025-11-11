import 'dart:async';

/// The abstract base class for all common Valkey data commands.
///
/// Both the standalone client ([ValkeyClientBase]) and the cluster client
/// ([ValkeyClusterClientBase]) implement this interface.
abstract class ValkeyCommandsBase {
  // --- Strings ---

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

  // --- Hashes ---

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

  // --- Lists ---

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

  // --- Sets ---

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

  // --- Sorted Sets ---

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

  // --- Key Management ---

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
}
