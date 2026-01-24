/*
 * Copyright 2025-2026 Infradise Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';

/// Mixin to support Redis-JSON and Valkey-JSON commands.
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

  /// Returns a list of loaded modules and their details.
  ///
  /// This method parses the raw response from `MODULE LIST` into a structured
  /// `List<Map<String, dynamic>>` for easier usage in Dart.
  ///
  /// Example return:
  /// ```dart
  /// [
  ///   {'name': 'json', 'ver': '10002', 'path': '/usr/lib/valkey/libjson.so', 'args': []},
  ///   {'name': 'search', 'ver': '10000', 'path': '/usr/lib/valkey/libsearch.so', 'args': []}
  ///   {'name': 'ldap', 'ver': '16777471', 'path': '/usr/lib/valkey/libvalkey_ldap.so', 'args': []},
  ///   {'name': 'bf', 'ver': '10000', 'path': '/usr/lib/valkey/libvalkey_bloom.so', 'args': []}
  /// ]
  /// ```
  Future<List<Map<String, dynamic>>> getModuleList() async {
    try {
      final result = await execute(<String>['MODULE', 'LIST']);

      if (result is! List) return [];

      final parsedModules = <Map<String, dynamic>>[];

      for (final rawModule in result) {
        if (rawModule is List) {
          final moduleMap = <String, dynamic>{};

          // The raw module info is a flat list like [key, value, key, value...]
          // Iterate by 2 to construct a Map
          for (var i = 0; i < rawModule.length; i += 2) {
            final key = rawModule[i].toString();
            final value = rawModule[i + 1];
            moduleMap[key] = value;
          }
          parsedModules.add(moduleMap);
        }
      }

      return parsedModules;
    } catch (e) {
      // Return an empty list if the command fails (e.g., command not supported)
      return [];
    }
  }

  /// Checks if the JSON module is loaded on the server.
  ///
  /// This method internally uses [getModuleList] to check if
  /// `ReJSON`, `json`, or `valkey-json` is present in the module list.
  Future<bool> isJsonModuleLoaded() async {
    final modules = await getModuleList();

    for (final module in modules) {
      final name = module['name']?.toString() ?? '';

      // Check for common JSON module names
      if (name == 'json' || name == 'ReJSON' || name == 'valkey-json') {
        return true;
      }
    }
    return false;
  }

  /// Checks if the JSON module is loaded on the server.
  ///
  /// This command sends `MODULE LIST` and checks if `ReJSON`, `json`,
  /// or `valkey-json`
  /// exists in the loaded module list.
  ///
  /// Returns `true` if the JSON module is detected, `false` otherwise.
  @Deprecated('Will be removed in the future.')
  Future<bool> isJsonModuleLoadedOld() async {
    try {
      // Execute the MODULE LIST command
      final result = await execute(<String>['MODULE', 'LIST']);

      // Result is usually a List of Lists (List<dynamic>)
      // Example: [[name, ReJSON, ver, 20406], [name, search, ...]]
      if (result is List) {
        for (final moduleInfo in result) {
          if (moduleInfo is List) {
            // Convert list items to string for safer comparison
            final infoString = moduleInfo.join(' ');

            // Check for common JSON module names
            if (infoString.contains('ReJSON') ||
                infoString.contains('valkey-json') ||
                // Exact match check for generic 'json' to avoid false positives
                moduleInfo.contains('json')) {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      // If MODULE command fails (e.g., restricted environment or very old
      // Redis), assume false or handle error as needed.
      return false;
    }
  }

  // ===========================================================================
  // JSON Commands
  // ===========================================================================
  // jsonArrAppend              v2.5.1
  // jsonArrAppendEnhanced
  // jsonArrIndex               v2.5.1
  // jsonArrIndexEnhanced
  // jsonArrInsert              v2.5.1
  // jsonArrInsertEnhanced
  // jsonArrLen                 v2.5.1
  // jsonArrLenEnhanced
  // jsonArrPop                 v2.5.1
  // jsonArrPopEnhanced
  // jsonArrTrim                v2.5.1
  // jsonArrTrimEnhanced
  // jsonClear
  // jsonDel                    v2.5.0
  // jsonForget
  // jsonGet                    v2.5.0
  // jsonMerge                  v2.5.0
  // jsonMget
  // jsonMset
  // jsonNumincrby
  // jsonNummultby
  // jsonObjkeys
  // jsonObjkeysEnhanced
  // jsonSet                    v2.5.0
  // jsonStrappend
  // jsonStrappendEnhanced
  // jsonStrlen
  // jsonStrlenEnhanced

  // ===========================================================================
  // JSON Array Commands
  // ===========================================================================

  /// Helper to unwrap the result if it is a single-element list.
  /// RedisJSON often returns [result] for path commands.
  dynamic _unwrapOne(dynamic result) {
    if (result is List && result.length == 1) {
      return result.first;
    }
    return result;
  }

  /// JSON.ARRAPPEND key [path] value [value ...]
  ///
  /// Appends the [values] to the JSON array at [path].
  ///
  /// [key] The key to modify.
  /// [path] The JSON path. Defaults to root (`$`).
  /// [values] A list of values to append. Each item in the list will be
  /// encoded individually.
  ///
  /// Returns the integer length of the new array, or a list of lengths if
  /// path matches multiple arrays.
  Future<dynamic> jsonArrAppend({
    required String key,
    String path = r'$',
    required List<dynamic> values,
  }) async {
    final cmd = <String>['JSON.ARRAPPEND', key, path];

    // Encode each value in the list to a JSON string
    for (final val in values) {
      cmd.add(jsonEncode(val));
    }

    final result = await execute(cmd);
    return _unwrapOne(result); // Unwrap [int] -> int
  }

  /// JSON.ARRINDEX key path value [start [stop]]
  ///
  /// Searches for the first occurrence of [value] in the array.
  ///
  /// [key] The key to search.
  /// [path] The JSON path.
  /// [value] The value to search for. It will be encoded to JSON before
  ///         searching.
  /// [start] The start index (inclusive, optional).
  /// [stop] The stop index (exclusive, optional).
  ///
  /// Returns the integer index of the value, or -1 if not found.
  Future<dynamic> jsonArrIndex({
    required String key,
    required String path,
    required dynamic value,
    int? start,
    int? stop,
  }) async {
    final encodedValue = jsonEncode(value);
    final cmd = <String>['JSON.ARRINDEX', key, path, encodedValue];

    if (start != null) {
      cmd.add(start.toString());
      if (stop != null) {
        cmd.add(stop.toString());
      }
    }

    final result = await execute(cmd);
    return _unwrapOne(result); // Unwrap [int] -> int
  }

  /// JSON.ARRINSERT key path index value [value ...]
  ///
  /// Inserts the [values] into the array at [index].
  ///
  /// [key] The key to modify.
  /// [path] The JSON path.
  /// [index] The index to insert at.
  /// [values] A list of values to insert.
  ///
  /// Returns the integer length of the new array.
  Future<dynamic> jsonArrInsert({
    required String key,
    required String path,
    required int index,
    required List<dynamic> values,
  }) async {
    final cmd = <String>['JSON.ARRINSERT', key, path, index.toString()];

    for (final val in values) {
      cmd.add(jsonEncode(val));
    }

    final result = await execute(cmd);
    return _unwrapOne(result); // Unwrap [int] -> int
  }

  /// JSON.ARRLEN key [path]
  ///
  /// Returns the length of the JSON array at [path].
  ///
  /// [key] The key to check.
  /// [path] The JSON path. Defaults to root (`$`).
  ///
  /// Returns an integer (if path targets one array) or a list of integers.
  Future<dynamic> jsonArrLen({
    required String key,
    String path = r'$',
  }) async {
    final result = await execute(<String>['JSON.ARRLEN', key, path]);
    return _unwrapOne(result); // Unwrap [int] -> int
  }

  /// JSON.ARRPOP key [path [index]]
  ///
  /// Removes and returns the element at [index] in the array.
  ///
  /// [key] The key to modify.
  /// [path] The JSON path. Defaults to root (`$`).
  /// [index] The index to pop. Defaults to -1 (last element).
  ///
  /// Returns the popped element (automatically decoded to Dart Object).
  Future<dynamic> jsonArrPop({
    required String key,
    String path = r'$',
    int? index,
  }) async {
    final cmd = <String>['JSON.ARRPOP', key, path];

    if (index != null) {
      cmd.add(index.toString());
    }

    // 1. Execute command
    // Result is usually List<String> like ['"value"'] or ['123']
    var result = await execute(cmd);

    // Use smart decoding (similar to jsonGet)
    if (result == null) return null;

    // 2. Unwrap if it's a single-element list
    result = _unwrapOne(result);

    // Redis returns the popped value as a JSON string.
    // If it returns a List (path matched multiple arrays), we might need to
    // handle it,
    // but usually ARRPOP targets a specific path.
    // 3. Decode JSON string to Dart Object
    if (result is String) {
      try {
        return jsonDecode(result);
      } catch (e) {
        return result; // Fallback
      }
    }
    // If multiple paths matched, result might still be a List of strings.
    // In that case, we might want to map decode, but usually POP is specific.
    return result;
  }

  /// JSON.ARRTRIM key path start stop
  ///
  /// Trims the array so that it contains only the specified inclusive range of
  /// elements.
  ///
  /// [key] The key to modify.
  /// [path] The JSON path.
  /// [start] The start index (inclusive).
  /// [stop] The stop index (inclusive).
  ///
  /// Returns the integer length of the new array.
  Future<dynamic> jsonArrTrim({
    required String key,
    required String path,
    required int start,
    required int stop,
  }) async {
    final result = await execute(
        <String>['JSON.ARRTRIM', key, path, start.toString(), stop.toString()]);
    return _unwrapOne(result); // Unwrap [int] -> int
  }

  /// JSON.GET key [path ...]
  ///
  /// Return the value at [path] in JSON format.
  /// The returned JSON string is automatically decoded into a Dart Object.
  ///
  /// [key] The key to retrieve.
  /// [path] The JSON path. Defaults to root (`$`).
  @Deprecated('Will be removed in the future.')
  Future<dynamic> jsonGetOld({
    required String key,
    String path = r'$',
  }) async {
    // Send command
    final result = await execute(<String>['JSON.GET', key, path]);

    if (result == null) return null;

    // Decode the response string back to a Dart Object (Map, List, etc.)
    return jsonDecode(result.toString());
  }

  /// JSON.GET key [path ...]
  ///
  /// Return the value at [path] in JSON format.
  /// The returned JSON string is automatically decoded into a Dart Object.
  ///
  /// [key] The key to retrieve.
  /// [path] The JSON path. Defaults to root (`$`).
  ///
  /// Note on Path Behavior:
  /// - If [path] is `$` (default), the command is sent as `JSON.GET key`.
  ///   This returns the single raw value (e.g., Map or List).
  /// - If [path] is specific (e.g., `$.name`), the command is sent as
  ///     `JSON.GET key $.name`.
  ///   Standard JSONPath queries usually return a List of matches
  ///     (e.g., `[value]`).
  Future<dynamic> jsonGet({
    required String key,
    String path = r'$',
  }) async {
    final List<String> cmd;

    // [Optimization]
    // If the path is the root ('$'), we omit it in the command.
    // 'JSON.GET key' returns the object directly (e.g., {...}).
    // 'JSON.GET key $' returns a list containing the object (e.g., [{...}]).
    // To be user-friendly, we prefer the direct object for the root query.
    if (path == r'$') {
      cmd = <String>['JSON.GET', key];
    } else {
      cmd = <String>['JSON.GET', key, path];
    }

    // Send command
    final result = await execute(cmd);

    if (result == null) return null;

    // Decode the response string back to a Dart Object (Map, List, etc.)
    return jsonDecode(result.toString());
  }

  /// JSON.DEL key [path]
  ///
  /// Deletes a value.
  ///
  /// [key] The key to modify.
  /// [path] The JSON path to delete. Defaults to root (`$`).
  Future<int?> jsonDel({
    required String key,
    String path = r'$',
  }) async {
    final result = await execute(<String>['JSON.DEL', key, path]);

    // Valkey returns the integer number of paths deleted (0 or 1 usually)
    if (result is int) return result;
    return int.tryParse(result.toString());
  }

  /// JSON.MERGE key path value
  ///
  /// Merges a given JSON value into the existing JSON value at path.
  ///
  /// [key] The key to modify.
  /// [path] The JSON path.
  /// [data] The data to merge.
  ///
  /// Note1: This command is available ONLY in Redis (due to RSAL license).
  /// Attempting to use this on a Valkey server will throw an error
  /// unless [allowRedisOnlyJsonMerge] is explicitly set to true
  /// (though Valkey server will still reject it).
  ///
  /// Note2: JSON.MERGE is implemented for Redis compatibility only.
  /// It should not be called when connected to a Valkey server.
  Future<void> jsonMerge({
    required String key,
    required String path,
    required dynamic data,
  }) async {
    /// Check if the server is Redis
    ///
    /// Alternatively, isValkeyServer() can be used for DX improvements.
    /// ```dart
    /// final isValkey = await isValkeyServer();
    /// ```
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
  @Deprecated('Will be removed in the future.')
  Future<void> jsonSetOld({
    required String key,
    required String path,
    required dynamic data,
    bool nx = false, // Only set if path does not exist
    bool xx = false, // Only set if path already exists
  }) async {
    // Convert data to JSON string
    final jsonData = jsonEncode(data);

    // Construct the command list as List<String> to maintain backward
    // compatibility
    final cmd = <String>['JSON.SET', key, path, jsonData];

    if (nx) cmd.add('NX');
    if (xx) cmd.add('XX');

    await execute(cmd);
  }

  /// JSON.SET key path value [NX | XX]
  ///
  /// Sets the JSON value at [path] in [key].
  ///
  /// This method is smart enough to handle both Dart Objects (Map, List)
  /// and Raw JSON Strings.
  ///
  /// If [data] is a String that looks like JSON (e.g., '{"a":1}'),
  /// it will be automatically parsed and stored as a JSON Object,
  /// preventing double-encoding issues.
  ///
  /// [key] The key to modify.
  /// [path] The JSON path (e.g., `r'$'`, `r'$.score'`). Must be a String.
  /// [data] The data to store. Can be a Map, List, num, bool, String, etc.
  /// [nx] If true, set the value only if it does not exist.
  /// [xx] If true, set the value only if it already exists.
  Future<void> jsonSet({
    required String key,
    required String path,
    required dynamic data,
    bool nx = false, // Only set if path does not exist
    bool xx = false, // Only set if path already exists
  }) async {
    dynamic payload = data;

    // [Smart Parsing Logic]
    // If the user provided a String, try to decode it first.
    // This allows users to pass raw JSON strings like '{"a": 1}'
    // without double-encoding.
    if (data is String) {
      try {
        final trimmed = data.trim();
        // Check if it looks like a JSON Object or Array
        if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
            (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
          payload = jsonDecode(data);
        }
      } catch (e) {
        // If decoding fails, treat it as a regular string value.
        // e.g., data = "Hello World" -> stored as "Hello World"
      }
    }

    // Convert the final payload to a JSON string for the command
    final jsonData = jsonEncode(payload);

    // Construct the command list as List<String> to maintain backward
    // compatibility
    final cmd = <String>['JSON.SET', key, path, jsonData];

    if (nx) cmd.add('NX');
    if (xx) cmd.add('XX');

    await execute(cmd);
  }
}
