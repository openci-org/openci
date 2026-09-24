import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../../i18n/i18n.dart';

const _baseImageName = 'base-macos';
const _listLocalImagesArguments = ['list', '--source', 'local', '--quiet'];

typedef ProcessRunner =
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      bool runInShell,
    });

Future<bool> checkTartBaseImage(
  Logger logger, {
  @visibleForTesting ProcessRunner processRunner = Process.run,
}) async {
  logger.stdout('\n${t.dev.start.stepTart}');

  late final ProcessResult tartListResult;
  try {
    tartListResult = await processRunner(
      'tart',
      _listLocalImagesArguments,
      runInShell: true,
    );
  } on ProcessException {
    logger.stderr(t.dev.start.stepTartNotFound);
    return false;
  }

  if (tartListResult.exitCode != 0 ||
      !hasExactVmName(tartListResult.stdout.toString(), _baseImageName)) {
    logger.stderr(t.dev.start.stepTartNotFound);
    return false;
  }
  logger.stdout(t.dev.start.stepTartExists);
  return true;
}

@visibleForTesting
bool hasExactVmName(String output, String targetName) {
  return output.split('\n').map((line) => line.trim()).contains(targetName);
}
