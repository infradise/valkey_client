// ignore_for_file: constant_identifier_names

/// Defines logging severity levels.
///
/// Follows the levels from `package:logging`.
class ValkeyLogLevel {
  final String name;
  final int value;

  const ValkeyLogLevel(this.name, this.value);

  /// Serious failures
  static const ValkeyLogLevel severe = ValkeyLogLevel('SEVERE', 1000);

  /// Potential problems
  static const ValkeyLogLevel warning = ValkeyLogLevel('WARNING', 800);

  /// Informational messages
  static const ValkeyLogLevel info = ValkeyLogLevel('INFO', 700);

  /// Fine-grained tracing
  static const ValkeyLogLevel fine = ValkeyLogLevel('FINE', 500);

  /// Disables logging.
  static const ValkeyLogLevel off = ValkeyLogLevel('OFF', 2000);

  bool operator <(ValkeyLogLevel other) => value < other.value;
  bool operator <=(ValkeyLogLevel other) => value <= other.value;

  // Legacy identifiers kept for backward compatibility (deprecated)
  @Deprecated('Since 1.1.0: Use "severe" instead')
  static const ValkeyLogLevel SEVERE = severe;

  @Deprecated('Since 1.1.0: Use "warning" instead')
  static const ValkeyLogLevel WARNING = warning;

  @Deprecated('Since 1.1.0: Use "info" instead')
  static const ValkeyLogLevel INFO = info;

  @Deprecated('Since 1.1.0: Use "fine" instead')
  static const ValkeyLogLevel FINE = fine;

  @Deprecated('Since 1.1.0: Use "off" instead')
  static const ValkeyLogLevel OFF = off;
}

/// A simple internal logger for the valkey_client.
///
/// This avoids adding an external dependency on `package:logging`.
class ValkeyLogger {
  final String name;
  static ValkeyLogLevel level = ValkeyLogLevel.off; // Logging is off by default

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
    _log(ValkeyLogLevel.severe, message, error, stackTrace);
  }

  void warning(String message, [Object? error]) {
    _log(ValkeyLogLevel.warning, message, error);
  }

  void info(String message) {
    _log(ValkeyLogLevel.info, message);
  }

  void fine(String message) {
    _log(ValkeyLogLevel.fine, message);
  }
}
