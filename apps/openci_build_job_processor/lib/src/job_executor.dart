import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor/src/orchard/orchard_api_client.dart';
import 'package:openci_build_job_processor/src/orchard/orchard_vm_service.dart';
import 'package:openci_build_job_processor/src/processor_config.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:retry/retry.dart';
import 'package:sentry/sentry.dart';

class JobExecutor {
  JobExecutor({
    required OpenCiApiService apiService,
    required ProcessorConfig config,
    OrchardVmService? orchardVmService,
  }) : _apiService = apiService,
       _config = config,
       _orchardVmService =
           orchardVmService ??
           OrchardVmService(
             apiClient: OrchardApiClient(
               baseUrl: config.orchardApiUrl,
               serviceAccountName: config.orchardServiceAccountName,
               serviceAccountToken: config.orchardServiceAccountToken,
             ),
           );

  final OpenCiApiService _apiService;
  final ProcessorConfig _config;
  final OrchardVmService _orchardVmService;
  final _random = Random();
  final _log = Logger('JobExecutor');

  String getVmName({required String jobId, required String runId}) {
    final shortJobId = jobId.substring(0, 8);
    final shortRunId = runId.substring(runId.length - 6);
    const baseName = 'openci-vm';
    return '$baseName-$shortJobId-$shortRunId';
  }

  Future<void> execute(BuildJob job) async {
    final runId = generateRunId();
    final vmName = getVmName(jobId: job.id, runId: runId);
    _log.info('[$vmName] Starting execution for job ${job.id} (run: $runId)');

    bool vmCreated = false;

    try {
      _log.info('[$vmName] Creating run record...');
      await _createRun(job.id, runId);

      final maxAttempts = (_config.vmPrepareTimeoutMinutes * 60 / 15)
          .round()
          .clamp(5, 240);
      final retryOptions = RetryOptions(
        maxAttempts: maxAttempts,
        delayFactor: const Duration(seconds: 15),
        randomizationFactor: 0.2,
      );

      _log.info('[$vmName] Preparing VM via Orchard...');
      await retryOptions.retry(
        () async {
          await _prepareVm(
            baseVmName: _config.baseVmName,
            vmName: vmName,
            onVmCreated: () => vmCreated = true,
            runsOn: job.runsOn,
          );
        },
        onRetry: (e) async {
          _log.warning(
            '[$vmName] VM preparation failed: $e. Retrying in 15s...',
          );
          try {
            await _cleanupVm(vmName);
            vmCreated = false;
          } catch (cleanupErr, cleanupStack) {
            _log.warning(
              '[$vmName] Cleanup failed during retry prep: $cleanupErr',
            );
            unawaited(
              Sentry.captureException(cleanupErr, stackTrace: cleanupStack),
            );
          }
        },
      );

      final buildScript = await fetchBuildScript(job.id);
      BuildJobStatus finalStatus = BuildJobStatus.SUCCESS;

      if (buildScript.isNotEmpty) {
        _log.info('[$vmName] Dispatching command execution to VM...');
        try {
          final exitCode = await _orchardVmService.executeCommandStreaming(
            containerName: vmName,
            command: ['/bin/sh', '-c', buildScript],
            onLog: (line) => _log.fine('[$vmName] $line'),
            isCancelled: () async => _isCancelled(job.id),
          );

          if (exitCode != 0) {
            _log.warning('[$vmName] Build script exited with code $exitCode');
            finalStatus = BuildJobStatus.FAILURE;
          }
        } catch (e) {
          _log.severe('[$vmName] Failed to execute script: $e');
          finalStatus = BuildJobStatus.FAILURE;
        }
      }

      await _updateJobFinalStatus(
        jobId: job.id,
        runId: runId,
        status: finalStatus,
        conclusion: finalStatus.name.toLowerCase(),
      );
    } catch (e, s) {
      _log.severe('[$vmName] Critical exception in JobExecutor: $e', e, s);
      unawaited(Sentry.captureException(e, stackTrace: s));
      await _updateJobFinalStatus(
        jobId: job.id,
        runId: runId,
        status: BuildJobStatus.FAILURE,
        conclusion: BuildJobStatus.FAILURE.name.toLowerCase(),
      );
    } finally {
      if (vmCreated) {
        _log.info('[$vmName] Cleaning up VM...');
        await _cleanupVm(vmName);
        _log.info('[$vmName] VM cleanup completed.');
      }
    }
  }

  Future<void> _cleanupVm(String vmName) async {
    try {
      await _orchardVmService.cleanup(vmName);
    } catch (e, s) {
      _log.warning('[$vmName] Failed to delete Orchard VM: $e');
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
  }

  Future<void> _updateJobFinalStatus({
    required String jobId,
    required String runId,
    required BuildJobStatus status,
    required String conclusion,
  }) async {
    try {
      await _apiService
          .updateRunStatus(jobId, runId, {
            'status': 'completed',
            'conclusion': conclusion,
          })
          .timeout(const Duration(seconds: 10));
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    try {
      await _apiService
          .completeJob(jobId, {
            'status': status.name,
            'completedAt': DateTime.now().toUtc().toIso8601String(),
          })
          .timeout(const Duration(seconds: 10));
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    try {
      await _apiService
          .updateCheckRun(jobId, {
            'status': 'completed',
            'conclusion': conclusion,
            'completedAt': DateTime.now().toUtc().toIso8601String(),
          })
          .timeout(const Duration(seconds: 10));
      await _apiService
          .handleBuildJobStatusChange(jobId, {'status': status.name})
          .timeout(const Duration(seconds: 10));
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
  }

  Future<void> _prepareVm({
    required String baseVmName,
    required String vmName,
    required void Function() onVmCreated,
    String? runsOn,
  }) async {
    final os =
        (runsOn != null &&
            (runsOn.toLowerCase().contains('ubuntu') ||
                runsOn.toLowerCase().contains('linux')))
        ? 'linux'
        : 'darwin';

    await _orchardVmService.prepare(
      baseInstanceName: baseVmName,
      containerName: vmName,
      onCreated: onVmCreated,
      os: os,
    );
  }

  Future<void> _createRun(String jobId, String runId) async {
    final createRunRes = await _apiService
        .createRun(jobId, {'id': runId})
        .timeout(const Duration(seconds: 10));
    if (!createRunRes.isSuccessful) {
      throw Exception(
        'Failed to create run: ${createRunRes.statusCode} - ${createRunRes.error}',
      );
    }
  }

  String generateRunId() {
    final part1 = DateTime.now().millisecondsSinceEpoch;
    final part2 = _random.nextInt(1000000);
    return 'run-$part1-$part2';
  }

  Future<String> fetchBuildScript(String buildJobId) async {
    try {
      final response = await _apiService.getJobBuildScript(buildJobId);
      if (!response.isSuccessful) {
        return 'echo "OpenCI Orchard Build Job Succeeded"';
      }
      final body = response.body;
      if (body == null) return 'echo "OpenCI Orchard Build Job Succeeded"';
      return body['script'] as String? ??
          'echo "OpenCI Orchard Build Job Succeeded"';
    } catch (e) {
      return 'echo "OpenCI Orchard Build Job Succeeded"';
    }
  }

  Future<bool> _isCancelled(String jobId) async {
    try {
      final res = await _apiService
          .getBuildJob(jobId)
          .timeout(const Duration(seconds: 10));
      if (res.isSuccessful) {
        final updatedJob = res.body;
        return updatedJob?['status'] == BuildJobStatus.CANCELLED.name ||
            updatedJob?['status'] == 'CANCELLING';
      }
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
    return false;
  }
}
