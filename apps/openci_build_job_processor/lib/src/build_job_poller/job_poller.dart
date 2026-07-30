import 'dart:async';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:openci_build_job_processor/src/build_job_poller/claim_next_job.dart';
import 'package:openci_build_job_processor/src/logging/build_job_logger.dart';
import 'package:openci_job_processor_shared/openci_job_processor_shared.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('JobPoller');

class JobPoller {
  JobPoller({
    required ProcessorConfig config,
    OpenCiApiService? apiService,
    VmService? orchardVmService,
  }) : _apiService =
           apiService ??
           createOpenCiChopperClient(
             baseUrl: config.serverUrl,
             tokenProvider: () => config.internalApiKey,
             services: [OpenCiApiService.create()],
           ).getService<OpenCiApiService>(),
       _baseVmName = config.baseVmName,
       _maxConcurrentJobs = config.maxConcurrentJobs,
       _orchardVmService =
           orchardVmService ??
           OrchardVmService(
             apiClient: OrchardApiClient(
               baseUrl: config.orchardApiUrl,
               serviceAccountName: config.orchardServiceAccountName,
               serviceAccountToken: config.orchardServiceAccountToken,
             ),
           ) {
    setupBuildJobLogger(
      serverUrl: config.serverUrl,
      internalApiKey: config.internalApiKey,
    );
    setupBuildStepLogger(
      serverUrl: config.serverUrl,
      internalApiKey: config.internalApiKey,
    );
  }

  final OpenCiApiService _apiService;
  final String _baseVmName;
  final VmService _orchardVmService;
  final int _maxConcurrentJobs;

  Future<void> startPolling(String runsOnPattern) async {
    _log.info(
      'JobPoller started polling for pattern: $runsOnPattern (Orchard Mode)',
    );

    while (true) {
      try {
        final job = await claimNextJob(
          apiService: _apiService,
          runsOnPattern: runsOnPattern,
          workerHost: 'orchard',
          maxConcurrentJobs: _maxConcurrentJobs,
        );
        if (job == null) {
          await Future<void>.delayed(const Duration(seconds: 10));
          continue;
        }

        final executor = JobExecutor(
          apiService: _apiService,
          baseVmName: _baseVmName,
          orchardVmService: _orchardVmService,
        );

        final runId = executor.generateRunId();

        await logInfo(
          job.id,
          runId,
          'Job claimed: ${job.id}. Starting build execution...',
          stepId: 'prepare_vm',
        );

        unawaited(() async {
          try {
            await executor.execute(job, 'orchard', runId);
          } catch (e, s) {
            _log.severe('Error executing job ${job.id}: $e', e, s);
            unawaited(Sentry.captureException(e, stackTrace: s));
          }
        }());
      } catch (e, s) {
        _log.severe('Error in polling loop: $e', e, s);
        unawaited(Sentry.captureException(e, stackTrace: s));
        await Future<void>.delayed(const Duration(seconds: 10));
      }
    }
  }
}
