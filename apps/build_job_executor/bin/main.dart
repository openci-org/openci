import 'dart:async';

import 'package:build_job_executor/build_job_executor.dart';
import 'package:logging/logging.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('BuildJobExecutor');

Future<void> main() async => genuineCiRunZonedGuarded(() async {
  final config = Config.fromEnvironment();

  await initializeSentry(config.sentryDsn);

  await _executeJob(config);
});

Future<void> _executeJob(Config config) async {
  _log.info('Starting Job Processor listening on Stream for queued jobs');
  final api = createOpenCiChopperClient(
    baseUrl: config.serverUrl,
    tokenProvider: () => config.internalApiKey,
    services: [OpenCiApiService.create()],
  ).getService<OpenCiApiService>();

  final executor = BuildJobExecutor.create(apiService: api, config: config);

  await for (final job in JobPoller(config: config).watchClaimedJobs()) {
    try {
      await executor.execute(job);
    } catch (e, s) {
      _log.severe('Error executing job ${job.id}: $e', e, s);
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
  }
}
