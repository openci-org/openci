import 'package:dart_firebase_admin/firestore.dart';
import 'package:logging/logging.dart';
import 'package:openci_worker_cli/cli_updater.dart';
import 'package:openci_worker_cli/job_executor.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('Poller');

Future<void> pollForJobs({
  required Firestore firestore,
  required String workerId,
  required String projectId,
  required String serviceAccountPath,
}) async {
  _log.info('Starting job poller...');

  while (true) {
    try {
      await checkForCLIUpdateIfNeeded(firestore);

      final jobFound = await processJob(
        firestore,
        projectId,
        serviceAccountPath,
        workerId,
      );

      if (jobFound) {
        _log.info('Job completed, checking for next...');
      } else {
        _log.fine('No jobs, waiting...');
        await Future.delayed(const Duration(seconds: 10));
      }
    } catch (e, s) {
      _log.severe('Error in poll loop: $e');
      await Sentry.captureException(e, stackTrace: s);
      await Future.delayed(const Duration(seconds: 10));
    }
  }
}
