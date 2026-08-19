import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_shared/openci_shared.dart';

final _log = Logger('LaunchExecutorContainer');

Future<void> launchExecutorContainer(
  BuildJob buildJob, {
  String serviceName = 'job-processor',
}) async {
  final containerName = 'openci-executor-${buildJob.id}';

  final args = <String>[
    'compose',
    'run',
    '-d',
    '--rm',
    '--name',
    containerName,
    '-e',
    'BUILD_JOB_ID=${buildJob.id}',
    serviceName,
  ];

  _log.info('Launching container via docker compose: ${args.join(' ')}');

  final result = await Process.run('docker', args);

  if (result.exitCode != 0) {
    _log.severe(
      'Failed to launch container $containerName (ExitCode: ${result.exitCode}): ${result.stderr}',
    );
    throw ProcessException(
      'docker',
      args,
      result.stderr.toString(),
      result.exitCode,
    );
  }

  _log.info('Launched container $containerName');
}
