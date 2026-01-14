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

import 'dart:io';

/// Defines which node to select for read operations.
enum ReadPreference {
  /// Always read from the master node. (Default)
  master,

  /// Prefer reading from replicas. If no replica is available, fall back to master.
  preferReplica,

  /// Only read from replicas. Throw exception if no replica is available.
  replicaOnly,
}

/// Defines how to distribute read traffic among available replicas.
enum LoadBalancingStrategy {
  /// Distribute requests sequentially among replicas.
  roundRobin,

  /// Select a replica randomly for each request.
  random,
}

// [v2.2.0] IP/Port Mapping for NAT/Docker
typedef AddressMapper = ({String host, int port}) Function(
    String host, int port);

/// Configuration for a Valkey connection.
/// Holds all configuration options for creating a new connection.
///
/// Used by [ValkeyPool] to create new client instances.
class ValkeyConnectionSettings {
  /// The host of the Valkey server.
  final String host;

  /// The port of the Valkey server.
  final int port;

  /// The username for ACL authentication (Valkey 6.0+).
  final String? username;

  /// The password for authentication.
  final String? password;

  /// The timeout for database commands.
  /// The maximum duration to wait for a response to any command.
  /// Defaults to 10 seconds.
  final Duration commandTimeout;

  /// The timeout for establishing a socket connection.
  final Duration connectTimeout;

  // --- v2.0.0 SSL/TLS Support ---
  // SSL Options (v2.0.0)

  /// Whether to use an encrypted SSL/TLS connection.
  /// Default is `false`.
  final bool useSsl;

  /// Custom SecurityContext for advanced SSL configurations
  /// (e.g., providing a client certificate or a custom CA).
  final SecurityContext? sslContext;

  /// Callback to handle bad certificates (e.g., self-signed certificates in dev).
  /// Returns `true` to allow the connection, `false` to abort.
  final bool Function(X509Certificate)? onBadCertificate;

  // [v2.1.0] Database Selection
  /// The database index to select after connection. Default is 0.
  final int database;

  // [v2.2.0] Replica Read & Load Balancing
  final ReadPreference readPreference;
  final LoadBalancingStrategy loadBalancingStrategy;

  // [v2.2.0] Manual Replica Configuration
  final List<ValkeyConnectionSettings>? explicitReplicas;

  // [v2.2.0] Address Mapper for NAT/Docker
  // Discovered IP (e.g. 172.xxx) -> External IP (e.g. 127.0.0.1)
  final AddressMapper? addressMapper;

  ValkeyConnectionSettings({
    // required this.host, // '127.0.0.1'
    // required this.port, // 6379
    this.host = '127.0.0.1',
    this.port = 6379,
    this.username,
    this.password,
    this.commandTimeout = const Duration(seconds: 10),
    this.connectTimeout = const Duration(seconds: 10),
    this.useSsl = false,
    this.sslContext,
    this.onBadCertificate,
    this.database = 0, // Default to DB 0
    this.readPreference =
        ReadPreference.master, // master, preferReplica, replicaOnly
    this.loadBalancingStrategy = LoadBalancingStrategy.roundRobin,
    this.explicitReplicas,
    this.addressMapper,
  });

  /// Creates a copy of this settings object with the given fields replaced.
  ValkeyConnectionSettings copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    Duration? commandTimeout,
    Duration? connectTimeout,
    bool? useSsl,
    SecurityContext? sslContext,
    bool Function(X509Certificate)? onBadCertificate,
    int? database,
    ReadPreference? readPreference,
    LoadBalancingStrategy? loadBalancingStrategy,
    List<ValkeyConnectionSettings>? explicitReplicas,
    AddressMapper? addressMapper,
  }) =>
      ValkeyConnectionSettings(
        host: host ?? this.host,
        port: port ?? this.port,
        username: username ?? this.username,
        password: password ?? this.password,
        commandTimeout: commandTimeout ?? this.commandTimeout,
        connectTimeout: connectTimeout ?? this.connectTimeout,
        useSsl: useSsl ?? this.useSsl,
        sslContext: sslContext ?? this.sslContext,
        onBadCertificate: onBadCertificate ?? this.onBadCertificate,
        database: database ?? this.database,
        readPreference: readPreference ?? this.readPreference,
        loadBalancingStrategy:
            loadBalancingStrategy ?? this.loadBalancingStrategy,
        explicitReplicas: explicitReplicas ?? this.explicitReplicas,
        addressMapper: addressMapper ?? this.addressMapper,
      );
}
