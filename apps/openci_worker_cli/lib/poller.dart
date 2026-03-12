import 'package:dart_firebase_admin/firestore.dart';
import 'package:logging/logging.dart';
import 'package:openci_worker_cli/cli_updater.dart';
import 'package:openci_worker_cli/job_executor.dart';
import 'package:openci_worker_cli/pubsub.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('Poller');

Future<void> pollForJobs({
  required Firestore firestore,
  required String workerId,
  required String projectId,
  required String serviceAccountPath,
}) async {
  final pubsub = await initPubSub(serviceAccountPath);
  final subscription = 'projects/$projectId/subscriptions/worker-jobs';

  _log.info('Listening on $subscription');

  while (true) {
    try {
      await checkForCLIUpdateIfNeeded(firestore);

      final msg = await pullMessage(pubsub, subscription);
      if (msg == null) {
        _log.fine('No messages, waiting...');
        await Future.delayed(const Duration(seconds: 5));
        continue;
      }

      _log.info('Received job: ${msg.buildJobId}');

      try {
        await processJob(
          firestore,
          projectId,
          serviceAccountPath,
          workerId,
          msg.buildJobId,
        );
      } catch (e, s) {
        _log.severe('Error processing job ${msg.buildJobId}: $e');
        await Sentry.captureException(e, stackTrace: s);
      }

      await acknowledge(pubsub, subscription, msg.ackId);
      _log.info('Job ${msg.buildJobId} acknowledged');
    } catch (e, s) {
      _log.severe('Pub/Sub pull error: $e');
      await Sentry.captureException(e, stackTrace: s);
      await Future.delayed(const Duration(seconds: 10));
    }
  }
}
