import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_worker_cli/args.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:openci_worker_cli/docker_runner.dart';
import 'package:openci_worker_cli/firebase.dart';
import 'package:openci_worker_cli/log.dart';
import 'package:openci_worker_cli/poller.dart';
import 'package:openci_worker_cli/supervisor.dart';
import 'package:openci_worker_cli/vm.dart';
import 'package:openci_worker_cli/worker_config.dart';
import 'package:openci_worker_cli/cloud_function_caller.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('Main');

Future<void> main(List<String> arguments) async {
  setupLogging();

  // Check for --supervised flag before anything else
  final results = argParser.parse(arguments);
  if (results.flag('supervised')) {
    await runSupervised(arguments);
    return;
  }

  try {
    final config = await parseWorkerConfig(arguments);
    if (config == null) return;

    final authManager = AuthManager(email: config.email, password: config.password);
    final apiClient = ApiClient(authManager: authManager, projectId: config.projectId);

    final localPart = config.email.split('@').first;
    final workerId = localPart.contains('+') ? localPart.split('+').last : localPart;
    _log.info('Worker started. Worker ID: $workerId (v$version)');
    _log.info(
      'Platform: ${Platform.isLinux ? 'Linux (Docker)' : 'macOS (AVF)'}',
    );
    _log.info(
      'Host: ${Platform.localHostname} | '
      '${Platform.operatingSystemVersion} | '
      '${Platform.numberOfProcessors} cores',
    );

    if (Platform.isLinux) {
      await cleanupOrphanedContainers(workerId);
    } else {
      await cleanupOrphanedVms(workerId);
    }

    await pollForJobs(
      apiClient: apiClient,
      workerId: workerId,
    );
  } on FormatException catch (e) {
    _log.severe(e.message);
  } catch (e, s) {
    _log.severe('Unexpected error: $e');
    await Sentry.captureException(e, stackTrace: s);
    exit(1);
  }
}
