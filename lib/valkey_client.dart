/// A modern, production-ready Dart client for Valkey (9.0.0+).
/// Fully Redis 7.x compatible.
library;

// Export the public API interface and related classes
export 'valkey_client_base.dart';

// Export the concrete implementation
export 'src/valkey_client.dart';

// Re-export shared data classes for convenience
export 'valkey_client_base.dart' show ValkeyMessage, Subscription;
