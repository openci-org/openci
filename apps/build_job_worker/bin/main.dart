import 'dart:async';
import 'dart:io';

import 'package:build_job_worker/build_job_worker.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/initialize_sentry.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

final _pendingErrorReports = <Future<void>>{};

Future<void> main() async {
  final Config config;
  try {
    config = Config.fromEnvironment();
  } on StateError catch (error) {
    stderr.writeln('Build job worker configuration error: ${error.message}');
    exitCode = 1;
    return;
  }

  try {
    await initializeSentry(config.sentryDsn);
    await _runWorker(config);
    stdout.writeln('Build job worker stopped.');
  } catch (error, stackTrace) {
    _reportError(error, stackTrace);
    exitCode = 1;
  } finally {
    try {
      await Future.wait(
        _pendingErrorReports,
      ).timeout(const Duration(seconds: 5));
    } on TimeoutException {
      stderr.writeln('Timed out sending worker errors to Sentry.');
    } finally {
      await Sentry.close();
    }
  }
}

Future<void> _runWorker(Config config) async {
  final apiClient = createOpenCiChopperClient(
    baseUrl: config.serverUrl,
    tokenProvider: () => config.internalApiKey,
    services: [OpenCiApiService.create()],
  );
  OrchardApiClient? orchardApi;
  http.Client? lokiClient;
  final signals = <StreamSubscription<ProcessSignal>>[];

  try {
    orchardApi = OrchardApiClient(config: config);
    lokiClient = http.Client();
    final api = apiClient.getService<OpenCiApiService>();
    var stopRequested = false;

    void requestStop(ProcessSignal signal) {
      if (stopRequested) return;
      stopRequested = true;
      stdout.writeln(
        'Received $signal. Waiting for all running jobs to finish.',
      );
    }

    signals.add(ProcessSignal.sigint.watch().listen(requestStop));
    if (!Platform.isWindows) {
      signals.add(ProcessSignal.sigterm.watch().listen(requestStop));
    }

    stdout.writeln('Starting build job worker...');
    await runBuildJobWorker(
      api: api,
      getMaxConcurrentJobs: orchardApi.getMaxConcurrentJobs,
      executeJob: (job) => executeBuildJob(
        api: api,
        orchardApi: orchardApi!,
        lokiClient: lokiClient!,
        config: config,
        job: job,
        onError: _reportError,
      ),
      shouldStop: () => stopRequested,
      onError: _reportError,
    );
  } finally {
    lokiClient?.close();
    orchardApi?.close();
    apiClient.dispose();
    for (final subscription in signals) {
      await subscription.cancel();
    }
  }
}

void _reportError(Object error, StackTrace stackTrace) {
  stderr.writeln('Build job worker error: $error');
  stderr.writeln(stackTrace);
  if (!Sentry.isEnabled) return;

  final report = Sentry.captureException(error, stackTrace: stackTrace)
      .then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {
          stderr.writeln('Failed to send worker error to Sentry.');
        },
      );
  _pendingErrorReports.add(report);
  unawaited(report.whenComplete(() => _pendingErrorReports.remove(report)));
}
