import 'dart:io';

import 'package:logging/logging.dart';

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    final emoji = switch (record.level) {
      Level.SEVERE => '❌',
      Level.WARNING => '⚠️',
      Level.INFO => 'ℹ️',
      Level.FINE => '🔍',
      _ => '',
    };
    final time =
        '${record.time.hour.toString().padLeft(2, '0')}:${record.time.minute.toString().padLeft(2, '0')}:${record.time.second.toString().padLeft(2, '0')}';
    stderr.writeln('$time $emoji [${record.loggerName}] ${record.message}');
  });
}
