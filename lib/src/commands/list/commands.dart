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

mixin ListCommands {
  /// Sends a command to the server.
  /// The interface for sending commands to the Redis/Valkey server.
  Future<dynamic> execute(List<String> command);

  /// Checks if the connected server is Redis.
  Future<bool> isRedisServer();

  /// Checks if the connected server is Valkey.
  Future<bool> isValkeyServer();
}
