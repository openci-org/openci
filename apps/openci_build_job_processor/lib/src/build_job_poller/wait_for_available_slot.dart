import 'package:logging/logging.dart';

Future<void> waitForAvailableSlot({
  Duration delay = const Duration(seconds: 5),
  required int Function() getActiveJobsCount,
  required int maxConcurrentJobs,
  required Logger log,
}) async {
  while (getActiveJobsCount() >= maxConcurrentJobs) {
    log.info(
      'Active jobs ${getActiveJobsCount()} >= max $maxConcurrentJobs. Waiting...',
    );
    await Future<void>.delayed(delay);
  }
}
