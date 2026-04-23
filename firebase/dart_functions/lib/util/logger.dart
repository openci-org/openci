import 'dart:convert';

import 'package:sentry/sentry.dart';

void logInfo(String message, [Map<String, dynamic>? data]) {
  _log('INFO', message, data);
}

void logWarning(String message, [Map<String, dynamic>? data, Object? error]) {
  _log('WARNING', message, data, error);
}

Future<void> logError(
  String message, [
  Map<String, dynamic>? data,
  Object? error,
]) async {
  _log('ERROR', message, data, error);

  if (error != null && Sentry.isEnabled) {
    await Sentry.captureException(
      error,
      stackTrace: error is Error ? error.stackTrace : StackTrace.current,
    );
  }
}

void _log(
  String severity,
  String message,
  Map<String, dynamic>? data, [
  Object? error,
]) {
  final entry = {
    'severity': severity,
    'message': message,
    if (data != null) ...data,
    if (error != null) 'error': error.toString(),
  };
  print(jsonEncode(entry));
}
