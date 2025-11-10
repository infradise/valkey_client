/// A modern, production-ready Dart client for Valkey (9.0.0+).
/// Fully Redis 7.x compatible.
library;

// Export the public API interface and related classes
export 'valkey_client_base.dart';

// Export the connection pool (v1.1.0)
export 'valkey_pool.dart';

// Export cluster info data classes (v1.2.0)
export 'src/cluster_info.dart';

// Export the new cluster client interface (v1.3.0)
export 'valkey_cluster_client_base.dart';

// Export public exception classes (v1.0.0)
export 'src/exceptions.dart';

// Export the concrete implementation
export 'src/valkey_client.dart';

// Re-export shared data classes and enums for convenience
export 'valkey_client_base.dart' show ValkeyMessage, Subscription;
export 'src/logging.dart' show ValkeyLogLevel;
