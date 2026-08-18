import 'dart:io';

import 'package:logging/logging.dart';

void initLogging([Level level = Level.ALL]) {
  Logger.root.level = level;
  Logger.root.onRecord.listen((record) {
    final jstTime = record.time.toUtc().add(const Duration(hours: 9));
    final timeStr = jstTime.toString().length >= 23
        ? jstTime.toString().substring(5, 23)
        : jstTime.toString();
    stdout.writeln(
      '$timeStr [${record.loggerName}] ${record.level.name}: ${record.message}',
    );
    if (record.error != null) {
      stdout.writeln('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      stdout.writeln('StackTrace:\n${record.stackTrace}');
    }
  });
}
