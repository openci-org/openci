import 'dart:convert';

void logInfo(String message, [Map<String, dynamic>? data]) {
  _log('INFO', message, data);
}

void logWarning(String message, [Map<String, dynamic>? data, Object? error]) {
  _log('WARNING', message, data, error);
}

void logError(String message, [Map<String, dynamic>? data, Object? error]) {
  _log('ERROR', message, data, error);
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
  // ignore: avoid_print
  print(jsonEncode(entry));
}
