import 'dart:io';

import 'package:openci_worker_cli/firebase.dart';
import 'package:openci_worker_cli/poller.dart';
import 'package:openci_worker_cli/vm.dart';
import 'package:openci_worker_cli/worker_config.dart';
import 'package:sentry/sentry.dart';

Future<void> main(List<String> arguments) async {
  try {
    final config = await parseWorkerConfig(arguments);
    if (config == null) return;

    final firestore = initFirestore(
      projectId: config.projectId,
      serviceAccountPath: config.serviceAccountPath,
    );

    print('Worker started. Worker ID: ${config.workerId}');
    await cleanupOrphanedVms(config.workerId);

    await pollForJobs(
      firestore: firestore,
      workerId: config.workerId,
      projectId: config.projectId,
      serviceAccountPath: config.serviceAccountPath,
    );
  } on FormatException catch (e) {
    print(e.message);
  } catch (e, s) {
    print('Unexpected error: $e');
    await Sentry.captureException(e, stackTrace: s);
    exit(1);
  }
}
