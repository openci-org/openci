import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../../i18n/i18n.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  bool runInShell,
});

Future<bool> checkTartBaseImage(
  Logger logger, {
  @visibleForTesting ProcessRunner processRunner = Process.run,
}) async {
  logger.stdout('\n${t.dev.start.stepTart}');
  final tartListResult = await processRunner('tart', ['list'], runInShell: true);
  if (tartListResult.exitCode != 0 ||
      !hasExactVmName(tartListResult.stdout.toString(), 'base-macos')) {
    logger.stderr(t.dev.start.stepTartNotFound);
    return false;
  }
  logger.stdout(t.dev.start.stepTartExists);
  return true;
}

@visibleForTesting
bool hasExactVmName(String output, String targetName) {
  final lines = output.split('\n');
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isNotEmpty && parts.first == targetName) {
      return true;
    }
  }
  return false;
}
