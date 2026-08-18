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

      final executor = BuildJobExecutor.create(
        apiService: apiService,
        config: config,
      );

      _log.info(
        'Orchard Config: name=${config.orchardServiceAccountName}, tokenLength=${config.orchardServiceAccountToken.length}, url=${config.orchardApiUrl}',
      );
      _log.info('Starting Job Processor listening on Stream for queued jobs');

      await for (final job in jobPoller.watchClaimedJobs()) {
        try {
          await executor.execute(job);
        } catch (e, s) {
          _log.severe('Error executing job ${job.id}: $e', e, s);
          unawaited(Sentry.captureException(e, stackTrace: s));
        }
      }
    },

    (error, stackTrace) async {
      stderr.writeln('FATAL UNCAUGHT ERROR: $error');
      stderr.writeln(stackTrace);
      await Sentry.captureException(error, stackTrace: stackTrace);
      exit(1);
    },
  );
}
