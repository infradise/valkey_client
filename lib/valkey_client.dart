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

/// A modern, production-ready Dart client for Valkey (9.0.0+).
/// Fully Redis 7.x compatible.
library;

// Export cluster info data classes (v1.2.0)
export 'src/cluster_info.dart';
// Helpers for jsonMSet
export 'src/commands/json/json_commands.dart'
    show Config, JsonCommands, JsonMSetEntry;
export 'src/commands/json/json_extensions.dart';
// Export public exception classes (v1.0.0)
export 'src/exceptions.dart';
export 'src/logging.dart' show ValkeyLogLevel, ValkeyLogger;
// Export the concrete *standalone* implementation
export 'src/valkey_client.dart';
// Export the concrete *cluster* implementation
export 'src/valkey_cluster_client.dart';
// Export the public API interface and related classes
export 'valkey_client_base.dart';
// Re-export shared data classes and enums for convenience
export 'valkey_client_base.dart' show Subscription, ValkeyMessage;
// Export the new cluster client interface (v1.3.0)
export 'valkey_cluster_client_base.dart';
// Export the common command interface
export 'valkey_commands_base.dart';
// Export the connection pool (v1.1.0)
export 'valkey_pool.dart';
