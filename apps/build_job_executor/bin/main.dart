import 'dart:async';

import 'package:build_job_executor/build_job_executor.dart';
import 'package:logging/logging.dart';
import 'package:openci_shared/initialize_sentry.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('BuildJobExecutor');

Future<void> main() async => genuineCiRunZonedGuarded(() async {
  initLogging();

  final config = Config.fromEnvironment();

  await initializeSentry(config.sentryDsn);

  await _executeJob(config);
});

Future<void> _executeJob(Config config) async {
  _log.info('Starting BuildJobExecutor for job: ${config.buildJobId}');
  final api = createOpenCiChopperClient(
    baseUrl: config.serverUrl,
    tokenProvider: () => config.internalApiKey,
    services: [OpenCiApiService.create()],
  ).getService<OpenCiApiService>();

  final response = await api.getBuildJob(config.buildJobId);
  if (!response.isSuccessful || response.body == null) {
    throw StateError(
      'Failed to fetch build job ${config.buildJobId}: ${response.statusCode} - ${response.error}',
    );
  }

  final job = BuildJob.fromJson(response.body!);
  final executor = BuildJobExecutor.create(apiService: api, config: config);

  try {
    await executor.execute(job);
    _log.info('Finished executing build job ${job.id}');
  } catch (e, s) {
    _log.severe('Error executing job ${job.id}: $e', e, s);
    unawaited(Sentry.captureException(e, stackTrace: s));
    rethrow;
  }
}
