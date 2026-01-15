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

/// Enum representing the running mode of the server.
enum RunningMode {
  standalone,
  cluster,
  sentinel,
  unknown,
}

/// Holds metadata about the connected Valkey/Redis server.
class ServerMetadata {
  /// The server version string (e.g., "7.2.4", "9.0.0").
  final String version;

  /// The server software name ('valkey' or 'redis').
  final String serverName;

  /// The running mode of the server.
  final RunningMode mode;

  /// The maximum number of databases available for selection.
  final int maxDatabases;

  ServerMetadata({
    required this.version,
    required this.serverName,
    required this.mode,
    required this.maxDatabases,
  });

  @override
  String toString() =>
      'ServerMetadata(name: $serverName, version: $version, mode: $mode, '
      'maxDatabases: $maxDatabases)';
}
