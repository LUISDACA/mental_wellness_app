import 'dart:async';

import 'constants.dart';

/// Utilidades para transformar errores en mensajes amigables.
class AppErrors {
  AppErrors._();

  /// Devuelve un mensaje legible para mostrar al usuario.
  static String humanize(Object error) {
    if (error is TimeoutException) {
      return AppConstants.errorNetwork;
    }
    if (error is ArgumentError) {
      return error.message?.toString() ?? error.toString();
    }
    if (error is StateError) {
      return error.message;
    }
    // Para otros Exception/Object, usa toString o un fallback genérico
    final text = error.toString();
    if (text.isNotEmpty && text != 'Exception') {
      return text;
    }
    return AppConstants.errorUnexpected;
  }
}