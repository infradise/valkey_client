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

// ignore_for_file: constant_identifier_names

/// Defines logging severity levels.
///
/// Follows the levels from `package:logging`.
class ValkeyLogLevel {
  final String name;
  final int value;

  const ValkeyLogLevel(this.name, this.value);

  /// Fine-grained tracing
  static const ValkeyLogLevel fine = ValkeyLogLevel('FINE', 500);

  /// Informational messages
  static const ValkeyLogLevel info = ValkeyLogLevel('INFO', 700);

  /// Potential problems
  static const ValkeyLogLevel warning = ValkeyLogLevel('WARNING', 800);

  /// Serious failures
  static const ValkeyLogLevel severe = ValkeyLogLevel('SEVERE', 1000);

  /// Error messages
  static const ValkeyLogLevel error = ValkeyLogLevel('ERROR', 1400);

  /// Disables logging.
  static const ValkeyLogLevel off = ValkeyLogLevel('OFF', 2000);

  /// Enables logging.
  static const EnableValkeyLog = false;

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
  bool _enableValkeyLog = ValkeyLogLevel.EnableValkeyLog;
  void setEnableValkeyLog(bool status) => _enableValkeyLog = status;

  ValkeyLogger(this.name);

  void setLogLevelFine() {
    level = ValkeyLogLevel.fine;
  }

  void setLogLevelInfo() {
    level = ValkeyLogLevel.info;
  }

  void setLogLevelWarning() {
    level = ValkeyLogLevel.warning;
  }

  void setLogLevelSevere() {
    level = ValkeyLogLevel.severe;
  }

  void setLogLevelError() {
    level = ValkeyLogLevel.error;
  }

  void setLogLevelOff() {
    level = ValkeyLogLevel.off;
  }

  /// Logs a message if [messageLevel] is at or above the current [level].
  void _log(ValkeyLogLevel messageLevel, String message,
      [Object? error, StackTrace? stackTrace]) {
    if (!_enableValkeyLog) {
      if (messageLevel.value < ValkeyLogger.level.value) {
        return; // Log level is too low, ignore.
      }
    }

    // Simple print-based logging. Users can configure this later.
    print('[${DateTime.now().toIso8601String()}] $name - '
        '${messageLevel.name}: $message');
    if (error != null) {
      print('  Error: $error');
    }
    if (stackTrace != null) {
      print('  Stacktrace:\n$stackTrace');
    }
  }

  void fine(String message) {
    _log(ValkeyLogLevel.fine, message);
  }

  void info(String message) {
    _log(ValkeyLogLevel.info, message);
  }

  void warning(String message, [Object? error]) {
    _log(ValkeyLogLevel.warning, message, error);
  }

  void severe(String message, [Object? error, StackTrace? stackTrace]) {
    _log(ValkeyLogLevel.severe, message, error, stackTrace);
  }

  void error(String message) {
    _log(ValkeyLogLevel.error, message);
  }
}
