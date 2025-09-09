import 'package:flutter/foundation.dart';

/// Log levels for structured logging
enum LogLevel { debug, info, warning, error }

/// Structured logger for the application
class AppLogger {
  static const String _tag = 'RAK_APP';

  /// Log debug messages
  void debug(String message, [dynamic data]) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, data);
    }
  }

  /// Log info messages
  void info(String message, [dynamic data]) {
    _log(LogLevel.info, message, data);
  }

  /// Log warning messages
  void warning(String message, [dynamic data]) {
    _log(LogLevel.warning, message, data);
  }

  /// Log error messages
  void error(String message, [dynamic data]) {
    _log(LogLevel.error, message, data);
  }

  /// Internal logging method
  void _log(LogLevel level, String message, [dynamic data]) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();
    final logMessage = '[$timestamp] $_tag [$levelStr] $message';

    // Print to console
    if (kDebugMode) {
      print(logMessage);
      if (data != null) {
        print('  Data: $data');
      }
    }

    // In production, you might want to send logs to a service
    // _sendToLoggingService(level, message, data);
  }

  /// Send logs to external logging service (placeholder)
  void _sendToLoggingService(LogLevel level, String message, dynamic data) {
    // Implementation for sending logs to external service
    // e.g., Firebase Crashlytics, Sentry, etc.
  }
}
