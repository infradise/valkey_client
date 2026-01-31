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

/// Hash Commands Mixin
///
/// This mixin defines the contract for Hash-related operations in Valkey/Redis.
/// It creates a modular structure where specific commands (e.g., HDEL, HGET)
/// are implemented as extensions on this mixin.

mixin HashCommands {
  /// Executes a raw command against the server.
  ///
  /// [command] is a list of strings representing the command and its arguments.
  /// Returns a dynamic result directly from the underlying protocol parser.
  Future<dynamic> execute(List<String> command);

  /// Checks if the connected server is a Redis server.
  Future<bool> isRedisServer();

  /// Checks if the connected server is a Valkey server.
  Future<bool> isValkeyServer();

  // ---------------------------------------------------------------------------
  // Utility Methods (Shared across Hash extensions)
  // ---------------------------------------------------------------------------

  /// Helper to execute a command that is expected to return an Integer.
  ///
  /// Useful for commands like HDEL, HLEN, HINCRBY, etc.
  /// Handles type casting and parsing safely.
  Future<int> executeInt(List<String> command) async {
    final result = await execute(command);

    if (result is int) return result;
    if (result == null) return 0; // or throw depending on strictness

    // Sometimes servers might return integer-like strings
    if (result is String) {
      return int.tryParse(result) ?? 0;
    }

    throw Exception('Expected integer response but got ${result.runtimeType}');
  }
}
