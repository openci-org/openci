import 'dart:async';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor_linux/src/incus/incus_service.dart';
import 'package:openci_build_job_processor_linux/src/job_executor.dart';
import 'package:openci_build_job_processor_linux/src/logging/build_job_logger.dart';
import 'package:openci_build_job_processor_linux/src/processor_config.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('JobPoller');

class JobPoller {
  JobPoller({
    required ProcessorConfig config,
    OpenCiApiService? apiService,
    IncusService? incusService,
  }) : _apiService =
           apiService ??
           createOpenCiChopperClient(
             baseUrl: config.serverUrl,
             tokenProvider: () => config.internalApiKey,
             services: [OpenCiApiService.create()],
           ).getService<OpenCiApiService>(),
       _incusService = incusService ?? IncusService(apiUrl: config.incusApiUrl),
       _baseInstanceName = config.baseInstanceName,
       _maxConcurrentJobs = config.maxConcurrentJobs {
    setupBuildJobLogger(
      serverUrl: config.serverUrl,
      internalApiKey: config.internalApiKey,
    );
  }

  final OpenCiApiService _apiService;
  final IncusService _incusService;
  final String _baseInstanceName;
  int _activeJobsCount = 0;
  final int _maxConcurrentJobs;
  final _activeJobs = <String, DateTime>{};

  Future<void> startPolling(String runsOnPattern) async {
    _log.info('JobPoller started polling for pattern: $runsOnPattern');

    try {
      await pruneZombieVms();
    } catch (e) {
      _log.warning('Failed to complete container pruning initialization: $e');
    }

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

        _log.info('Checking running container count on Incus...');
        final runningCount = await _incusService.getRunningVmCount();
        if (runningCount >= _maxConcurrentJobs) {
          _log.info(
            'Incus cluster reports $runningCount active jobs. Waiting for capacity...',
          );
          await Future<void>.delayed(const Duration(seconds: 10));
          continue;
        }

        _log.info('Claiming next job for pattern: $runsOnPattern...');
        final job = await _claimNextJob(runsOnPattern);
        if (job == null) {
          _log.info(
            'No queued jobs found for pattern: $runsOnPattern. Retrying in 10 seconds...',
          );
          await Future<void>.delayed(const Duration(seconds: 10));
          continue;
        }

        _log.info('Job claimed: ${job.id}. Starting build execution...');

        final executor = JobExecutor(
          apiService: _apiService,
          incusService: _incusService,
          baseInstanceName: _baseInstanceName,
        );

        final runId = executor.generateRunId();
        final shortId = job.id.length > 8 ? job.id.substring(0, 8) : job.id;
        final containerName = 'openci-vm-$shortId';

        _activeJobs[containerName] = DateTime.now();
        _activeJobsCount++;

        unawaited(() async {
          try {
            await executor.execute(job, runId);
          } catch (e, s) {
            unawaited(Sentry.captureException(e, stackTrace: s));
          } finally {
            _activeJobs.remove(containerName);
            _activeJobsCount--;
          }
        }());

        await Future<void>.delayed(const Duration(seconds: 2));
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
    _activeJobs.forEach((containerName, startTime) {
      final diff = now.difference(startTime);
      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds % 60;
      final timeStr = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
      buffer.write('\n  - $containerName: Running for $timeStr');
    });
    buffer.write('\n===========================');
    _log.info(buffer.toString());
  }

  Future<void> pruneZombieVms() async {
    _log.info('Initializing: Pruning any zombie build containers on Incus...');
    try {
      final instances = await _incusService.getActiveBuildInstances();
      for (final containerName in instances) {
        if (containerName != _baseInstanceName) {
          _log.info('Pruning zombie container: $containerName');
          try {
            await _incusService.stopContainer(containerName);
            await _incusService.deleteContainer(containerName);
            _log.info('Successfully pruned zombie container: $containerName');
          } catch (e, s) {
            _log.warning(
              'Failed to prune zombie container $containerName',
              e,
              s,
            );
            unawaited(Sentry.captureException(e, stackTrace: s));
          }
        }
      }
    } catch (e, s) {
      _log.warning('Failed to prune containers', e, s);
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
    _log.info('Initialization complete: Zombie containers pruned.');
  }
}
