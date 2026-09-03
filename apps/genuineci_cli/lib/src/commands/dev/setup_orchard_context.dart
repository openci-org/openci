import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../../i18n/i18n.dart';

const _bootstrapServiceAccountName = 'bootstrap-admin';
const _controllerContainerName = 'openci-orchard-controller';
const _controllerUrl = 'https://127.0.0.1:6120';
const _defaultContextName = 'default';
const _defaultMaxAttempts = 30;
const _defaultRetryInterval = Duration(seconds: 1);

const _getBootstrapTokenArguments = [
  'exec',
  _controllerContainerName,
  'orchard',
  'get',
  'bootstrap-token',
  _bootstrapServiceAccountName,
];

typedef OrchardProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);
typedef OrchardDelay = Future<void> Function(Duration duration);

Future<bool> setupOrchardContext(
  Logger logger, {
  @visibleForTesting OrchardProcessRunner processRunner = Process.run,
  @visibleForTesting OrchardDelay delay = _delay,
  @visibleForTesting int maxAttempts = _defaultMaxAttempts,
  @visibleForTesting Duration retryInterval = _defaultRetryInterval,
}) async {
  logger.stdout('\n${t.dev.start.stepOrchardWaiting}');

  String? bootstrapToken;
  try {
    bootstrapToken = await _waitForBootstrapToken(
      processRunner,
      delay,
      maxAttempts,
      retryInterval,
    );
  } on ProcessException catch (error) {
    logger.stderr('${t.dev.start.stepOrchardNotReady}\n${error.message}');
    return false;
  }

  if (bootstrapToken == null) {
    logger.stderr(t.dev.start.stepOrchardNotReady);
    return false;
  }

  logger.stdout('\n${t.dev.start.stepOrchardContext}');

  try {
    final createContextResult = await processRunner('orchard', [
      'context',
      'create',
      _controllerUrl,
      '--service-account-name',
      _bootstrapServiceAccountName,
      '--service-account-token',
      bootstrapToken,
      '--no-pki',
      '--force',
    ]);
    if (createContextResult.exitCode != 0) {
      logger.stderr(t.dev.start.stepOrchardContextFailed);
      return false;
    }

    final selectContextResult = await processRunner('orchard', [
      'context',
      'default',
      _defaultContextName,
    ]);
    if (selectContextResult.exitCode != 0) {
      logger.stderr(t.dev.start.stepOrchardContextFailed);
      return false;
    }
  } on ProcessException catch (error) {
    logger.stderr('${t.dev.start.stepOrchardContextFailed}\n${error.message}');
    return false;
  }

  logger.stdout(t.dev.start.stepOrchardContextRegistered);
  return true;
}

Future<String?> _waitForBootstrapToken(
  OrchardProcessRunner processRunner,
  OrchardDelay delay,
  int maxAttempts,
  Duration retryInterval,
) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final result = await processRunner('docker', _getBootstrapTokenArguments);
    final bootstrapToken = result.stdout.toString().trim();
    if (result.exitCode == 0 && bootstrapToken.isNotEmpty) {
      return bootstrapToken;
    }

    if (attempt + 1 < maxAttempts) {
      await delay(retryInterval);
    }
  }

  return null;
}

Future<void> _delay(Duration duration) => Future<void>.delayed(duration);
