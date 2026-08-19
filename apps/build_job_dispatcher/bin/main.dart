import 'dart:async';

import 'package:build_job_dispatcher/build_job_dispatcher.dart';
import 'package:logging/logging.dart';
import 'package:openci_shared/initialize_logging.dart';
import 'package:openci_shared/initialize_sentry.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('BuildJobDispatcher');

Future<void> main() async => genuineCiRunZonedGuarded(() async {
  initLogging();

  final config = Config.fromEnvironment();

  await initializeSentry(config.sentryDsn);

  await dispatchBuildJob(config);
});

Future<void> dispatchBuildJob(Config config) async {
  final api = createOpenCiChopperClient(
    baseUrl: config.serverUrl,
    tokenProvider: () => config.internalApiKey,
    services: [OpenCiApiService.create()],
  ).getService<OpenCiApiService>();

  _log.info('Starting build job dispatcher loop...');

  while (true) {
    try {
      final response = await api.claimNextJob({});
      if (!response.isSuccessful || response.body == null) {
        throw StateError(
          'Failed to claim job: HTTP ${response.statusCode} - ${response.error}',
        );
      }

      final jobData = response.body!['job'] as Map<String, dynamic>?;
      if (jobData == null) {
        _log.fine('No queued jobs found. Waiting 5s...');
        await Future<void>.delayed(const Duration(seconds: 5));
        continue;
      }

      final buildJob = BuildJob.fromJson(jobData);
      _log.info(
        'Claimed build job: ${buildJob.id} (Workflow: ${buildJob.workflowName})',
      );

      // TODO: ここで docker コンテナを起動・実行
      // await _launchExecutorContainer(buildJob, config);
    } catch (e, s) {
      _log.severe('Error claiming/dispatching job: $e', e, s);
      unawaited(Sentry.captureException(e, stackTrace: s));
      rethrow;
    }
  }
}
