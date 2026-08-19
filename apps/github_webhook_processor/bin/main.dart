import 'dart:async';

import 'package:github_webhook_processor/github_webhook_processor.dart';
import 'package:logging/logging.dart';
import 'package:openci_shared/initialize_logging.dart';
import 'package:openci_shared/initialize_sentry.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('GitHubWebhookProcessor');

Future<void> main() async => genuineCiRunZonedGuarded(() async {
  initLogging();

  final config = Config.fromEnvironment();

  await initializeSentry(config.sentryDsn);

  await processGitHubWebhook(config);
});

Future<void> processGitHubWebhook(Config config) async {
  final api = createOpenCiChopperClient(
    baseUrl: config.serverUrl,
    tokenProvider: () => config.internalApiKey,
    services: [OpenCiApiService.create()],
  ).getService<OpenCiApiService>();

  _log.info('Starting GitHub webhook processor loop...');

  while (true) {
    try {
      final task = await getWebhookTask(api, _log);
      if (task == null) {
        _log.fine('No pending webhook tasks found. Waiting 3s...');
        await Future<void>.delayed(const Duration(seconds: 3));
        continue;
      }

      final response = await api.processWebhookTask(task.id);
      if (!response.isSuccessful || response.body == null) {
        throw StateError(
          'Failed to process webhook task ${task.id}: HTTP ${response.statusCode} - ${response.error}',
        );
      }

      final jobsCreated = response.body!['jobs_created'] ?? 0;
      _log.info(
        'Completed webhook task: ${task.id} (Jobs created: $jobsCreated)',
      );
    } catch (e, s) {
      _log.severe('Error processing webhook task: $e', e, s);
      unawaited(Sentry.captureException(e, stackTrace: s));
      rethrow;
    }
  }
}
