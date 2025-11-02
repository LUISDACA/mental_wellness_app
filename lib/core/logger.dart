import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Structured logging utility for the Mental Wellness App
///
/// Provides different log levels (info, warning, error) with optional tags
/// and stack trace support. In debug mode, logs to console. In production,
/// logs can be sent to crash reporting services (e.g., Firebase Crashlytics).
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  /// Log an informational message
  ///
  /// Use for general app flow information, state changes, etc.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.info('User logged in successfully', tag: 'Auth');
  /// ```
  static void info(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    final formattedMessage = 'ℹ️  $prefix$message';

    if (kDebugMode) {
      developer.log(
        formattedMessage,
        name: 'MentalWellness',
        level: 800, // INFO level
      );
    }

    // TODO: Add production logging when Firebase is configured
    // if (!kDebugMode) {
    //   FirebaseCrashlytics.instance.log('INFO: $prefix$message');
    // }
  }

  /// Log a warning message
  ///
  /// Use for recoverable errors, deprecated API usage, or unexpected but
  /// non-critical situations.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.warning('API fallback used', tag: 'Gemini');
  /// ```
  static void warning(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    final formattedMessage = '⚠️  $prefix$message';

    if (kDebugMode) {
      developer.log(
        formattedMessage,
        name: 'MentalWellness',
        level: 900, // WARNING level
      );
    }

    // TODO: Add production logging when Firebase is configured
    // if (!kDebugMode) {
    //   FirebaseCrashlytics.instance.log('WARNING: $prefix$message');
    // }
  }

  /// Log an error with optional exception and stack trace
  ///
  /// Use for exceptions, critical failures, or data corruption issues.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await riskyOperation();
  /// } catch (e, stack) {
  ///   AppLogger.error('Operation failed', error: e, stack: stack, tag: 'Service');
  /// }
  /// ```
  static void error(
    String message, {
    Object? error,
    StackTrace? stack,
    String? tag,
  }) {
    final prefix = tag != null ? '[$tag] ' : '';
    final formattedMessage = '❌ $prefix$message';

    if (kDebugMode) {
      developer.log(
        formattedMessage,
        name: 'MentalWellness',
        error: error,
        stackTrace: stack,
        level: 1000, // ERROR level
      );
    }

    // TODO: Add production crash reporting when Firebase is configured
    // if (!kDebugMode && error != null) {
    //   FirebaseCrashlytics.instance.recordError(
    //     error,
    //     stack,
    //     reason: message,
    //     fatal: false,
    //   );
    // }
  }

  /// Log a debug message (only in debug mode)
  ///
  /// Use for verbose debugging information that should never appear in production.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.debug('Processing 150 items', tag: 'DataProcessor');
  /// ```
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      developer.log(
        '🔍 $prefix$message',
        name: 'MentalWellness',
        level: 700, // DEBUG level
      );
    }
  }
}

// Legacy function wrappers for backward compatibility
// These can be removed once all code is migrated to AppLogger

@Deprecated('Use AppLogger.info() instead')
void logInfo(Object? message) {
  AppLogger.info(message?.toString() ?? 'null');
}

@Deprecated('Use AppLogger.error() instead')
void logError(Object? message) {
  AppLogger.error(message?.toString() ?? 'null');
}
