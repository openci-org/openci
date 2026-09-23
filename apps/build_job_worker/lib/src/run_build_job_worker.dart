import 'package:openci_shared/openci_shared.dart';

import 'claim_next_build_job.dart';

Future<void> runBuildJobWorker({
  required OpenCIApiService api,
  required Future<int> Function() getMaxConcurrentJobs,
  required Future<BuildJobStatus> Function(BuildJob job) executeJob,
  required bool Function() shouldStop,
  required void Function(Object error, StackTrace stackTrace) onError,
  Duration pollInterval = const Duration(seconds: 3),
}) async {
  if (pollInterval <= Duration.zero) {
    throw ArgumentError.value(
      pollInterval,
      'pollInterval',
      'Must be positive.',
    );
  }

  final running = <Future<void>>{};
  try {
    while (!shouldStop()) {
      try {
        final capacity = await getMaxConcurrentJobs();
        final availableSlots = capacity - running.length;
        for (var slot = 0; slot < availableSlots && !shouldStop(); slot++) {
          final job = await claimNextBuildJob(api);
          if (job == null) break;

          late final Future<void> execution;
          execution = Future.sync(() => executeJob(job))
              .then<void>((_) {}, onError: onError)
              .whenComplete(() => running.remove(execution));
          running.add(execution);
        }
      } catch (error, stackTrace) {
        onError(error, stackTrace);
      }

      if (!shouldStop()) {
        await Future<void>.delayed(pollInterval);
      }
    }
  } finally {
    await Future.wait(running);
  }
}
