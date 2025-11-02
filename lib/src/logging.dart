// lib/src/logging.dart

/// Defines logging severity levels.
///
/// Follows the levels from `package:logging`.
class ValkeyLogLevel {
  final String name;
  final int value;

  const ValkeyLogLevel(this.name, this.value);

  /// Serious failures
  static const ValkeyLogLevel SEVERE = ValkeyLogLevel('SEVERE', 1000);

  /// Potential problems
  static const ValkeyLogLevel WARNING = ValkeyLogLevel('WARNING', 800);

  /// Informational messages
  static const ValkeyLogLevel INFO = ValkeyLogLevel('INFO', 700);

  /// Fine-grained tracing
  static const ValkeyLogLevel FINE = ValkeyLogLevel('FINE', 500);

  /// Disables logging.
  static const ValkeyLogLevel OFF = ValkeyLogLevel('OFF', 2000);

  bool operator <(ValkeyLogLevel other) => value < other.value;
  bool operator <=(ValkeyLogLevel other) => value <= other.value;
}

/// A simple internal logger for the valkey_client.
///
/// This avoids adding an external dependency on `package:logging`.
class ValkeyLogger {
  final String name;
  static ValkeyLogLevel level = ValkeyLogLevel.OFF; // Logging is OFF by default

  ValkeyLogger(this.name);

  /// Logs a message if [messageLevel] is at or above the current [level].
  void _log(ValkeyLogLevel messageLevel, String message,
      [Object? error, StackTrace? stackTrace]) {
    if (messageLevel.value < ValkeyLogger.level.value) {
      return; // Log level is too low, ignore.
    }

    // Simple print-based logging. Users can configure this later.
    print(
        '[${DateTime.now().toIso8601String()}] $name - ${messageLevel.name}: $message');
    if (error != null) {
      print('  Error: $error');
    }
    if (stackTrace != null) {
      print('  Stacktrace:\n$stackTrace');
    }
  }

  void severe(String message, [Object? error, StackTrace? stackTrace]) {
    _log(ValkeyLogLevel.SEVERE, message, error, stackTrace);
  }

  void warning(String message, [Object? error]) {
    _log(ValkeyLogLevel.WARNING, message, error);
  }

  void info(String message) {
    _log(ValkeyLogLevel.INFO, message);
  }

  void fine(String message) {
    _log(ValkeyLogLevel.FINE, message);
  }
}
