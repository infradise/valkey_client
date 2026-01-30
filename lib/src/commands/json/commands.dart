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

export 'extensions.dart';

class Config {
  final bool allowRedisOnlyJsonMerge;
  const Config({this.allowRedisOnlyJsonMerge = false});

  Config copyWith({bool? allowRedisOnlyJsonMerge}) => Config(
        allowRedisOnlyJsonMerge:
            allowRedisOnlyJsonMerge ?? this.allowRedisOnlyJsonMerge,
      );
}

// class ConfigUI extends ChangeNotifier {
//   bool _allowRedisOnlyJsonMerge = false;
//   bool get allowRedisOnlyJsonMerge => _allowRedisOnlyJsonMerge;

//   set allowRedisOnlyJsonMerge(bool value) {
//     if (_allowRedisOnlyJsonMerge == value) return;
//     _allowRedisOnlyJsonMerge = value;
//     notifyListeners();
//   }
// }

// final config = Config();
// config.addListener(() =>
//   logger.info('Config changed: ${config.allowRedisOnlyJsonMerge}'));
// config.allowRedisOnlyJsonMerge = true;

/// A helper class for JSON.MSET command.
/// Represents a single triplet of (key, path, value).
class JsonMSetEntry {
  final String key;
  final String path;
  final dynamic value;

  const JsonMSetEntry({
    required this.key,
    required this.path,
    required this.value,
  });
}

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

  set setAllowRedisOnlyJsonMerge(bool value);

  // ===========================================================================
  // JSON Module Checker
  // ===========================================================================

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
  @Deprecated('Use [isJsonModuleLoaded] instead. '
      'This method will be removed in v3.0.0.')
  Future<bool> deprecatedIsJsonModuleLoaded() async {
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
}
