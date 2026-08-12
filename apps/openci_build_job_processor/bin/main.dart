import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('JobProcessorMain');

Future<void> main() async {
  await runZonedGuarded(
    () async {
      final config = ProcessorConfig.fromEnvironment();

      await initializeSentry(config.sentryDsn);

      final jobPoller = JobPoller(config: config);
      final apiService = createOpenCiChopperClient(
        baseUrl: config.serverUrl,
        tokenProvider: () => config.internalApiKey,
        services: [OpenCiApiService.create()],
      ).getService<OpenCiApiService>();

      final executor = JobExecutor(
        apiService: apiService,
        baseVmName: config.baseVmName,
        config: config,
      );

      _log.info('Starting Job Processor listening on Stream for queued jobs');

      jobPoller.watchClaimedJobs().listen(
        (job) {
          unawaited(() async {
            try {
              await executor.execute(job);
            } catch (e, s) {
              _log.severe('Error executing job ${job.id}: $e', e, s);
              unawaited(Sentry.captureException(e, stackTrace: s));
            }
          }());
        },
        onError: (Object error, StackTrace stackTrace) async {
          _log.severe('Error in job stream: $error', error, stackTrace);
          unawaited(Sentry.captureException(error, stackTrace: stackTrace));
        },
      );

      _log.info('Job Processor is running. Press Ctrl+C to terminate.');
      await ProcessSignal.sigint.watch().first;
    },

    (error, stackTrace) async {
      stderr.writeln('FATAL UNCAUGHT ERROR: $error');
      stderr.writeln(stackTrace);
      await Sentry.captureException(error, stackTrace: stackTrace);
      exit(1);
    },
  );
}
