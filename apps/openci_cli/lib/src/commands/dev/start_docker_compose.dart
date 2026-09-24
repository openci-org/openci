import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../../i18n/i18n.dart';

typedef DockerComposeProcessRunner =
    Future<int> Function(
      String executable,
      List<String> arguments, {
      required String workingDirectory,
      required Map<String, String> environment,
    });

enum DockerComposeStep {
  startAuthEmulator,
  startOrchardController,
  stopBuildJobWorker,
  startServices,
  down,
}

const _localComposeFiles = [
  '-f',
  'docker-compose.yml',
  '-f',
  'docker-compose.local.yml',
  '-f',
  'docker-compose.local-api.yml',
];

Future<bool> startDockerCompose(
  Logger logger,
  Directory projectRoot, {
  DockerComposeStep step = DockerComposeStep.startServices,
  @visibleForTesting
  DockerComposeProcessRunner processRunner = _runDockerComposeProcess,
  @visibleForTesting Map<String, String>? environment,
}) async {
  final (arguments, message, failureMessage) = switch (step) {
    DockerComposeStep.startAuthEmulator => (
      [
        'compose',
        ..._localComposeFiles,
        'up',
        '-d',
        '--build',
        '--wait',
        '--remove-orphans',
        'firebase-auth',
      ],
      t.dev.start.stepAuthEmulator,
      t.dev.start.stepAuthEmulatorFailed,
    ),
    DockerComposeStep.startOrchardController => (
      [
        'compose',
        ..._localComposeFiles,
        'up',
        '-d',
        '--no-recreate',
        '--remove-orphans',
        'orchard-controller',
      ],
      t.dev.start.stepOrchardController,
      t.dev.start.stepDockerComposeFailed,
    ),
    DockerComposeStep.stopBuildJobWorker => (
      ['compose', ..._localComposeFiles, 'stop', 'build-job-worker'],
      t.dev.start.stepBuildJobWorkerWaiting,
      t.dev.start.stepDockerComposeFailed,
    ),
    DockerComposeStep.startServices => (
      [
        'compose',
        ..._localComposeFiles,
        'up',
        '-d',
        '--build',
        '--remove-orphans',
        'server',
        'build-job-planner',
        'build-job-worker',
        'loki',
      ],
      t.dev.start.stepDockerCompose,
      t.dev.start.stepDockerComposeFailed,
    ),
    DockerComposeStep.down => (
      ['compose', ..._localComposeFiles, 'down', '--remove-orphans'],
      t.dev.start.stepDockerComposeDown,
      t.dev.start.stepDockerComposeDownFailed,
    ),
  };
  logger.stdout('\n$message');

  final composeEnvironment = {
    ...(environment ?? Platform.environment),
    'ENABLE_INTERNAL_API': 'true',
  };
  // Keep the server and seed request on the same project .env key.
  composeEnvironment.remove('INTERNAL_API_KEY');

  try {
    final exitCode = await processRunner(
      'docker',
      arguments,
      workingDirectory: projectRoot.path,
      environment: composeEnvironment,
    );
    if (exitCode != 0) {
      logger.stderr(failureMessage);
      return false;
    }
  } on ProcessException catch (error) {
    logger.stderr('$failureMessage\n${error.message}');
    return false;
  }

  if (step == DockerComposeStep.startServices) {
    logger.stdout(t.dev.start.stepDockerComposeStarted);
  }
  return true;
}

Future<int> _runDockerComposeProcess(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  required Map<String, String> environment,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: false,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}
