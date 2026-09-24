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
  startOrchardController,
  stopBuildJobWorker,
  startServices,
}

Future<bool> startDockerCompose(
  Logger logger,
  Directory projectRoot, {
  DockerComposeStep step = DockerComposeStep.startServices,
  @visibleForTesting
  DockerComposeProcessRunner processRunner = _runDockerComposeProcess,
  @visibleForTesting Map<String, String>? environment,
}) async {
  final (arguments, message) = switch (step) {
    DockerComposeStep.startOrchardController => (
      [
        'compose',
        'up',
        '-d',
        '--no-recreate',
        '--remove-orphans',
        'orchard-controller',
      ],
      t.dev.start.stepOrchardController,
    ),
    DockerComposeStep.stopBuildJobWorker => (
      ['compose', 'stop', 'build-job-worker'],
      t.dev.start.stepBuildJobWorkerWaiting,
    ),
    DockerComposeStep.startServices => (
      [
        'compose',
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
    ),
  };
  logger.stdout('\n$message');

  final composeEnvironment = {
    ...(environment ?? Platform.environment),
    'ENABLE_INTERNAL_API': 'true',
  };

  try {
    final exitCode = await processRunner(
      'docker',
      arguments,
      workingDirectory: projectRoot.path,
      environment: composeEnvironment,
    );
    if (exitCode != 0) {
      logger.stderr(t.dev.start.stepDockerComposeFailed);
      return false;
    }
  } on ProcessException catch (error) {
    logger.stderr('${t.dev.start.stepDockerComposeFailed}\n${error.message}');
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
