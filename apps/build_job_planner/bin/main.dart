import 'dart:async';

import 'package:build_job_planner/build_job_planner.dart';
import 'package:logging/logging.dart';
import 'package:openci_shared/initialize_logging.dart';
import 'package:openci_shared/initialize_sentry.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('BuildJobPlanner');

Future<void> main() async => genuineCiRunZonedGuarded(() async {
  initLogging();

  final config = Config.fromEnvironment();

  await initializeSentry(config.sentryDsn);

  await planBuildJobs(config);
});

Future<void> planBuildJobs(Config config) async {
  final api = createOpenCiChopperClient(
    baseUrl: config.serverUrl,
    tokenProvider: () => config.internalApiKey,
    services: [OpenCiApiService.create()],
  ).getService<OpenCiApiService>();

  _log.info('Starting build job planner loop...');

  while (true) {
    try {
      final task = await getWebhookTask(api, _log);
      if (task == null) {
        _log.fine('No pending webhook tasks found. Waiting 3s...');
        await Future<void>.delayed(const Duration(seconds: 3));
        continue;
      }

      final jobsCreated = await handleWebhookTask(task: task, api: api);
      _log.info(
        'Completed webhook task: ${task.id} (Jobs created: $jobsCreated)',
      );
    } catch (e, s) {
      _log.severe('Error processing webhook task: $e', e, s);
      unawaited(Sentry.captureException(e, stackTrace: s));
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }
}
