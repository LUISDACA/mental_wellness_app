import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

import 'logger.dart';

/// Configura manejo global de errores para registrar fallos no capturados.
class AppErrorHandler {
  AppErrorHandler._();

  /// Inicializa manejadores globales de error.
  static void init() {
    // Errores del framework Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      // Mantener el comportamiento por defecto en debug
      FlutterError.presentError(details);
      AppLogger.error(
        'FlutterError: ${details.exceptionAsString()}',
        error: details.exception,
        stack: details.stack,
        tag: 'FlutterError',
      );
    };

    // Errores no capturados en el dispatcher (plataforma)
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error(
        'Unhandled platform error',
        error: error,
        stack: stack,
        tag: 'Platform',
      );
      // Devolver true para indicar que fue manejado y evitar crash en debug
      return true;
    };
  }
}