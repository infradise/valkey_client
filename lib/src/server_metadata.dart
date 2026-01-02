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
  String toString() => 'ServerMetadata(name: $serverName, version: $version, mode: $mode, maxDatabases: $maxDatabases)';
}