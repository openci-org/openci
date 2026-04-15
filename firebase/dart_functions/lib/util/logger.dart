import 'dart:convert';

void logInfo(String message, [Map<String, dynamic>? data]) {
  _log('INFO', message, data);
}

void logWarning(String message, [Map<String, dynamic>? data]) {
  _log('WARNING', message, data);
}

void logError(String message, [Map<String, dynamic>? data]) {
  _log('ERROR', message, data);
}

void _log(String severity, String message, Map<String, dynamic>? data) {
  final entry = {
    'severity': severity,
    'message': message,
    if (data != null) ...data,
  };
  // ignore: avoid_print
  print(jsonEncode(entry));
}
