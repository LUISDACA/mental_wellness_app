import 'package:flutter/foundation.dart';

void logInfo(Object? message) {
  if (kDebugMode) debugPrint('[INFO] $message');
}

void logError(Object? message) {
  if (kDebugMode) debugPrint('[ERROR] $message');
}
