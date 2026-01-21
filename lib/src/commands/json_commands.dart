import 'dart:convert';

/// Mixin to support Valkey-JSON commands.
/// This mixin ensures compatibility with the existing `execute` method
/// by converting all parameters to Strings before sending.
mixin JsonCommands {
  // [Interface Definition]
  // The class using this mixin must implement these methods and getters.

  /// Sends a command to the server.
  /// The interface for sending commands to the Redis/Valkey server.
  Future<dynamic> execute(List<String> command);

  /// Checks if the connected server is Redis.
  Future<bool> isRedisServer();

  /// Checks if the connected server is Valkey.
  Future<bool> isValkeyServer();

  /// Configuration to determine if JSON.MERGE (Redis-only) is allowed.
  /// This getter must be implemented by the main client class.
  bool get allowRedisOnlyJsonMerge;

  /// JSON.SET key path value [NX | XX]
  ///
  /// Sets the JSON value at [path] in [key].
  ///
  /// [key] The key to modify.
  /// [path] The JSON path (e.g., `r'$'`, `r'$.score'`). Must be a String.
  /// [data] The data to store. It will be automatically serialized using
  /// [jsonEncode].
  /// [nx] If true, set the value only if it does not exist.
  /// [xx] If true, set the value only if it already exists.
  Future<void> jsonSet({
    required String key,
    required String
        path, // Changed from dynamic to String to prevent type errors
    dynamic data,
    bool? nx,
    bool? xx,
  }) async {
    // Convert data to JSON string
    final jsonData = jsonEncode(data);

    // Construct the command list as List<String> to maintain backward
    // compatibility
    final cmd = <String>['JSON.SET', key, path, jsonData];

    if (nx ?? false) cmd.add('NX');
    if (xx ?? false) cmd.add('XX');

    await execute(cmd);
  }

  /// JSON.GET key [path ...]
  ///
  /// Return the value at [path] in JSON format.
  /// The returned JSON string is automatically decoded into a Dart Object.
  Future<dynamic> jsonGet(String key, [String path = r'$']) async {
    // Send command
    final result = await execute(<String>['JSON.GET', key, path]);

    if (result == null) return null;

    // Decode the response string back to a Dart Object (Map, List, etc.)
    return jsonDecode(result.toString());
  }

  /// JSON.DEL key [path]
  ///
  /// Deletes a value.
  Future<int?> jsonDel(String key, [String path = r'$']) async {
    final result = await execute(<String>['JSON.DEL', key, path]);
    // Valkey returns the integer number of paths deleted (0 or 1 usually)
    if (result is int) return result;
    return int.tryParse(result.toString());
  }

  /// JSON.MERGE key path value
  ///
  /// Merges a given JSON value into the existing JSON value at path.
  ///
  /// Note: This command is available ONLY in Redis (due to RSAL license).
  /// Attempting to use this on a Valkey server will throw an error
  /// unless [allowRedisOnlyJsonMerge] is explicitly set to true (though Valkey
  /// server will still reject it).
  ///
  /// Note: JSON.MERGE is implemented for Redis compatibility only.
  /// It should not be called when connected to a Valkey server.
  Future<void> jsonMerge(String key, String path, dynamic data) async {
    // Check if the server is Redis
    final isRedis = await isRedisServer();

    // If it's not Redis (i.e., Valkey) and the override flag is off,
    // block the request.
    if (!isRedis) {
      if (!allowRedisOnlyJsonMerge) {
        throw UnsupportedError('jsonMerge is not supported on Valkey.'
            //  'JSON.MERGE is not supported in Valkey '
            //  'due to licensing issues (RSAL). '
            //  'It is strictly a Redis-only command until Valkey supports it.'
            );
      }
      // logger.warning('jsonMerge is Redis-only; skipped on Valkey.');
    }

    final jsonData = jsonEncode(data);
    await execute(<String>['JSON.MERGE', key, path, jsonData]);
  }
}
