/*
 * Copyright 2026 Infradise Inc.
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

import 'dart:async';
import 'package:valkey_client/valkey_client.dart'; // Export exceptions
// import 'package:valkey_client/valkey_commands_base.dart';

export 'package:valkey_client/valkey_client.dart'
    show
        ValkeyConnectionException,
        ValkeyServerException,
        ValkeyClientException,
        ValkeyParsingException;

/// The abstract base class for a **cluster-aware** Valkey client.
///
/// This interface automatically routes commands to the correct node
/// based on the key's hash slot.
abstract class ValkeyClusterClientBase implements ValkeyCommandsBase {
  /// Connects to the cluster using the provided initial node(s).
  ///
  /// This method will perform the following steps:
  /// 1. Connect to one of the `initialNodes` provided in the constructor.
  /// 2. Call `CLUSTER SLOTS` to fetch the topology.
  /// 3. Create connection pools for each discovered master node.
  ///
  /// Throws [ValkeyConnectionException] if it fails to connect or
  /// fetch the cluster topology.
  Future<void> connect();

  /// Closes all pooled connections to all nodes in the cluster.
  Future<void> close();

  // ---
  // Key-based Commands (See `ValkeyCommandsBase`)
  // All commands like get, set, hget are now inherited
  // from the ValkeyCommandsBase interface.
  // NO DUPLICATION NEEDED.
  // ---

  // ---
  // Non-Key-based Commands (May run on any node, e.g., PING)
  // ---

  // --- Cluster-specific Admin Commands ---

  /// PINGs all master nodes in the cluster.
  ///
  /// Returns a Map of node identifiers to their "PONG" reply.
  Future<Map<String, String>> pingAll([String? message]);

  // (Note: Pub/Sub and Transactions are more complex and will be
  // defined later, e.g., v1.5.0 Sharded Pub/Sub)
}
