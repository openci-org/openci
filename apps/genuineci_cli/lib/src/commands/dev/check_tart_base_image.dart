import 'dart:io';

import 'package:cli_util/cli_logging.dart';

import '../../i18n/i18n.dart';

Future<bool> checkTartBaseImage(Logger logger) async {
  logger.stdout('\n${t.dev.start.stepTart}');
  final tartListResult = await Process.run('tart', ['list'], runInShell: true);
  if (!tartListResult.stdout.toString().contains('base-macos')) {
    logger.stderr(t.dev.start.stepTartNotFound);
    return false;
  }
  logger.stdout(t.dev.start.stepTartExists);
  return true;
}
