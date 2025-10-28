/// A modern, production-ready Dart client for Valkey (9.0.0+).
/// Fully Redis 7.x compatible.
library;

// Export the public API interface and related classes
export 'src/valkey_client_base.dart';

// Export the main client class
// Export the concrete implementation
export 'src/valkey_client.dart';

// Re-export shared data classes for convenience
export 'src/valkey_client_base.dart' show ValkeyMessage, Subscription;

// We will add more exports here later (e.g., exceptions, commands)
