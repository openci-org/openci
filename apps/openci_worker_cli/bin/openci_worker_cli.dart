import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_worker_cli/docker_runner.dart';
import 'package:openci_worker_cli/firebase.dart';
import 'package:openci_worker_cli/log.dart';
import 'package:openci_worker_cli/poller.dart';
import 'package:openci_worker_cli/vm.dart';
import 'package:openci_worker_cli/worker_config.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('Main');

Future<void> main(List<String> arguments) async {
  setupLogging();

  try {
    final config = await parseWorkerConfig(arguments);
    if (config == null) return;

    final firestore = initFirestore(
      projectId: config.projectId,
      serviceAccountPath: config.serviceAccountPath,
    );

    _log.info('Worker started. Worker ID: ${config.workerId}');
    _log.info('Platform: ${Platform.isLinux ? 'Linux (Docker)' : 'macOS (Lume)'}');

    if (Platform.isLinux) {
      await cleanupOrphanedContainers(config.workerId);
    } else {
      await cleanupOrphanedVms(config.workerId);
    }

    await pollForJobs(
      firestore: firestore,
      workerId: config.workerId,
      projectId: config.projectId,
      serviceAccountPath: config.serviceAccountPath,
      rawArguments: arguments,
    );
  } on FormatException catch (e) {
    _log.severe(e.message);
  } catch (e, s) {
    _log.severe('Unexpected error: $e');
    await Sentry.captureException(e, stackTrace: s);
    exit(1);
  }
}

