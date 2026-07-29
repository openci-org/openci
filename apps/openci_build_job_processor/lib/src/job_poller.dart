import 'dart:async';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';
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
  int _activeJobsCount = 0;
  final int _maxConcurrentJobs;
  final _activeJobs = <String, ({DateTime startTime, String host})>{};

  Future<void> startPolling(String runsOnPattern) async {
    _log.info(
      'JobPoller started polling for pattern: $runsOnPattern (Orchard Mode)',
    );

    Timer.periodic(const Duration(seconds: 30), (_) => _logActiveJobs());

    while (true) {
      try {
        if (_activeJobsCount >= _maxConcurrentJobs) {
          _log.info(
            'Active jobs $_activeJobsCount >= max $_maxConcurrentJobs. Waiting...',
          );
          await Future<void>.delayed(const Duration(seconds: 5));
          continue;
        }

        final job = await _claimNextJob(runsOnPattern);
        if (job == null) {
          await Future<void>.delayed(const Duration(seconds: 10));
          continue;
        }

        _log.info('Job claimed: ${job.id}. Starting build execution...');

        final executor = JobExecutor(
          apiService: _apiService,
          baseVmName: _baseVmName,
          orchardVmService: _orchardVmService,
        );

        final runId = executor.generateRunId();
        final shortId = job.id.length > 8 ? job.id.substring(0, 8) : job.id;
        final vmName = 'openci-vm-$shortId';

        _activeJobs[vmName] = (startTime: DateTime.now(), host: 'orchard');
        _activeJobsCount++;

        unawaited(() async {
          try {
            await executor.execute(job, 'orchard', runId);
          } catch (e, s) {
            _log.severe('Error executing job ${job.id}: $e', e, s);
            unawaited(Sentry.captureException(e, stackTrace: s));
          } finally {
            _activeJobs.remove(vmName);
            _activeJobsCount--;
          }
        }());
      } catch (e, s) {
        _log.severe('Error in polling loop: $e', e, s);
        unawaited(Sentry.captureException(e, stackTrace: s));
        await Future<void>.delayed(const Duration(seconds: 10));
      }
    }
  }

  Future<BuildJob?> _claimNextJob(String runsOnPattern) async {
    final response = await _apiService.claimNextJob({
      'runsOnPattern': runsOnPattern,
    });

    if (!response.isSuccessful) {
      throw Exception(
        'Failed to claim next job: ${response.statusCode} - ${response.error}',
      );
    }

    final body = response.body;
    if (body == null) {
      throw Exception('Failed to claim next job: Response body is null');
    }

    final jobMap = body['job'] as Map<String, dynamic>?;
    if (jobMap == null) {
      return null;
    }

    return BuildJob.fromJson(jobMap);
  }

  void _logActiveJobs() {
    if (_activeJobs.isEmpty) {
      _log.info('Active jobs: 0 / $_maxConcurrentJobs');
      return;
    }
    final buffer = StringBuffer(
      '\n=== Active Jobs Running: ${_activeJobs.length} / $_maxConcurrentJobs ===',
    );
    final now = DateTime.now();
    _activeJobs.forEach((vmName, info) {
      final diff = now.difference(info.startTime);
      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds % 60;
      final timeStr = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
      buffer.write('\n  - $vmName (on ${info.host}): Running for $timeStr');
    });
    buffer.write('\n===========================');
    _log.info(buffer.toString());
  }
}
