import 'dart:async';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_build_job_processor/src/build_job_poller/claim_next_job.dart';
import 'package:openci_build_job_processor/src/logging/build_job_logger.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';
import 'package:web_socket/web_socket.dart';

final _log = Logger('JobPoller');

class JobPoller {
  JobPoller({required ProcessorConfig config, OpenCiApiService? apiService})
    : _serverUrl = config.serverUrl,
      _apiService =
          apiService ??
          createOpenCiChopperClient(
            baseUrl: config.serverUrl,
            tokenProvider: () => config.internalApiKey,
            services: [OpenCiApiService.create()],
          ).getService<OpenCiApiService>() {
    setupBuildJobLogger(
      serverUrl: config.serverUrl,
      internalApiKey: config.internalApiKey,
    );
    setupBuildStepLogger(
      serverUrl: config.serverUrl,
      internalApiKey: config.internalApiKey,
    );
  }

  final String _serverUrl;
  final OpenCiApiService _apiService;

  Stream<BuildJob> watchClaimedJobs() async* {
    _log.info('JobPoller watching jobs stream');

    final wsUri = buildWebSocketUri(_serverUrl, '/worker/jobs/stream');

    while (true) {
      try {
        _log.info('Connecting to openci-server WebSocket stream at $wsUri ...');
        final socket = await WebSocket.connect(wsUri);
        _log.info('✅ WebSocket stream connected to openci-server');

        yield* _drainAvailableJobsStream();

        await for (final event in socket.events) {
          if (event is TextDataReceived) {
            yield* _drainAvailableJobsStream();
          }
        }
      } catch (e, s) {
        _log.warning('WebSocket connection lost: $e. Reconnecting in 5s...');
        unawaited(Sentry.captureException(e, stackTrace: s));
      }

      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  Stream<BuildJob> _drainAvailableJobsStream() async* {
    while (true) {
      try {
        final job = await claimNextJob(
          apiService: _apiService,
          workerHost: 'orchard',
        );

        if (job == null) {
          break;
        }

        yield job;
      } catch (e, s) {
        _log.severe('Error claiming job: $e', e, s);
        unawaited(Sentry.captureException(e, stackTrace: s));
        break;
      }
    }
  }
}
