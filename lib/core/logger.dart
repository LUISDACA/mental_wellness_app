import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    final formattedMessage = 'ℹ️  $prefix$message';

    if (kDebugMode) {
      developer.log(
        formattedMessage,
        name: 'MentalWellness',
        level: 800,
      );
    }
  }

  static void warning(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    final formattedMessage = '⚠️  $prefix$message';

    if (kDebugMode) {
      developer.log(
        formattedMessage,
        name: 'MentalWellness',
        level: 900,
      );
    }
  }

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
        level: 1000,
      );
    }
  }

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      developer.log(
        '🔍 $prefix$message',
        name: 'MentalWellness',
        level: 700,
      );
    }
  }
}

@Deprecated('Use AppLogger.info() instead')
void logInfo(Object? message) {
  AppLogger.info(message?.toString() ?? 'null');
}

@Deprecated('Use AppLogger.error() instead')
void logError(Object? message) {
  AppLogger.error(message?.toString() ?? 'null');
}
