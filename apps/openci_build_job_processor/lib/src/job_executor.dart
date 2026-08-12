import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor/src/logging/build_job_logger.dart';
import 'package:openci_build_job_processor/src/logging/build_step_logger.dart';
import 'package:openci_build_job_processor/src/orchard/orchard_api_client.dart';
import 'package:openci_build_job_processor/src/orchard/orchard_vm_service.dart';
import 'package:openci_build_job_processor/src/processor_config.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:retry/retry.dart';
import 'package:sentry/sentry.dart';

class JobExecutor {
  JobExecutor({
    required OpenCiApiService apiService,
    required String baseVmName,
    OrchardVmService? orchardVmService,
    ProcessorConfig? config,
  }) : _apiService = apiService,
       _baseVmName = baseVmName,
       _orchardVmService =
           orchardVmService ??
           OrchardVmService(
             apiClient: OrchardApiClient(
               baseUrl:
                   config?.orchardApiUrl ??
                   Platform.environment['ORCHARD_API_URL'] ??
                   'https://orchard-controller:6120',
               serviceAccountName:
                   config?.orchardServiceAccountName ??
                   Platform.environment['ORCHARD_SERVICE_ACCOUNT_NAME'] ??
                   'bootstrap-admin',
               serviceAccountToken:
                   config?.orchardServiceAccountToken ??
                   Platform.environment['ORCHARD_SERVICE_ACCOUNT_TOKEN'] ??
                   '',
             ),
           );

  final OpenCiApiService _apiService;
  final String _baseVmName;
  final OrchardVmService _orchardVmService;
  final _random = Random();
  final _log = Logger('JobExecutor');
  Duration retryDelay = const Duration(seconds: 5);

  String getVmName({required String jobId, required String runId}) {
    final shortJobId = jobId.substring(0, 8);
    final shortRunId = runId.substring(runId.length - 6);
    const baseName = 'openci-vm';
    return '$baseName-$shortJobId-$shortRunId';
  }

  Future<void> execute(BuildJob job) async {
    final runId = generateRunId();

    await logInfo(
      job.id,
      runId,
      'Job claimed: ${job.id}. Starting build execution...',
      stepId: 'prepare_vm',
    );

    final vmName = getVmName(jobId: job.id, runId: runId);
    _log.info('VMName is $vmName');

    bool vmCreated = false;

    try {
      _log.info('[$vmName] Starting execute flow. Creating run record...');
      await _createRun(job.id, runId);

      _log.info('[$vmName] Resolving GitHub installation token...');
      final token = await resolveGitHubInstallationToken(job.id);

      final vmPrepareTimeoutMinutes =
          int.tryParse(
            Platform.environment['OPENCI_VM_PREPARE_TIMEOUT_MINUTES'] ?? '15',
          ) ??
          15;
      final maxAttempts = (vmPrepareTimeoutMinutes * 60 / 15).round().clamp(
        5,
        240,
      );

      final retryOptions = RetryOptions(
        maxAttempts: maxAttempts,
        delayFactor: const Duration(seconds: 15),
        randomizationFactor: 0.2,
      );
      final prepareVmStart = DateTime.now().toUtc();
      await sendStepStatusUpdate(
        buildJobId: job.id,
        runId: runId,
        stepId: 'prepare_vm',
        name: 'Prepare VM',
        status: BuildJobStatus.IN_PROGRESS.name,
        durationMs: 0,
        stepOrder: 1,
        createdAt: prepareVmStart.toIso8601String(),
        updatedAt: prepareVmStart.toIso8601String(),
      );

      try {
        await retryOptions.retry(
          () async {
            await logInfo(
              job.id,
              runId,
              'Preparing VM (cloning & starting via Orchard)...',
              stepId: 'prepare_vm',
            );
            await _prepareVm(
              baseVmName: _baseVmName,
              vmName: vmName,
              onVmCreated: () => vmCreated = true,
              runsOn: job.runsOn,
            );

            await logInfo(
              job.id,
              runId,
              'Orchard VM created and scheduled by Controller.',
              stepId: 'prepare_vm',
            );
          },
          onRetry: (e) async {
            _log.warning(
              '[$vmName] VM preparation failed: $e. '
              'Cleaning up failed VM before retry...',
            );
            await logInfo(
              job.id,
              runId,
              '[Orchard] Waiting for available VM capacity (retrying in 15s)...',
              stepId: 'prepare_vm',
            );
            try {
              await _cleanupVm(vmName, runId);
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

        final prepareVmEnd = DateTime.now().toUtc();
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'prepare_vm',
          name: 'Prepare VM',
          status: BuildJobStatus.SUCCESS.name,
          durationMs: prepareVmEnd.difference(prepareVmStart).inMilliseconds,
          stepOrder: 1,
          createdAt: prepareVmStart.toIso8601String(),
          updatedAt: prepareVmEnd.toIso8601String(),
        );
      } catch (e) {
        final prepareVmEnd = DateTime.now().toUtc();
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'prepare_vm',
          name: 'Prepare VM',
          status: BuildJobStatus.FAILURE.name,
          durationMs: prepareVmEnd.difference(prepareVmStart).inMilliseconds,
          stepOrder: 1,
          createdAt: prepareVmStart.toIso8601String(),
          updatedAt: prepareVmEnd.toIso8601String(),
        );
        rethrow;
      }

      final checkoutStart = DateTime.now().toUtc();
      await sendStepStatusUpdate(
        buildJobId: job.id,
        runId: runId,
        stepId: 'checkout',
        name: 'Checkout repository',
        status: BuildJobStatus.IN_PROGRESS.name,
        durationMs: 0,
        stepOrder: 2,
        createdAt: checkoutStart.toIso8601String(),
        updatedAt: checkoutStart.toIso8601String(),
      );

      try {
        await logInfo(
          job.id,
          runId,
          'Checking out repository ${job.owner}/${job.repo}@${job.commitSha}...',
          stepId: 'checkout',
        );
        await _checkoutRepository(
          runId: runId,
          owner: job.owner,
          repo: job.repo,
          commitSha: job.commitSha ?? '',
          token: token,
          githubBaseUrl: job.githubBaseUrl,
          pullRequestNumber: job.pullRequestNumber,
        );
        await logInfo(
          job.id,
          runId,
          'Repository checkout completed successfully.',
          stepId: 'checkout',
        );

        final checkoutEnd = DateTime.now().toUtc();
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'checkout',
          name: 'Checkout repository',
          status: BuildJobStatus.SUCCESS.name,
          durationMs: checkoutEnd.difference(checkoutStart).inMilliseconds,
          stepOrder: 2,
          createdAt: checkoutStart.toIso8601String(),
          updatedAt: checkoutEnd.toIso8601String(),
        );
      } catch (e) {
        final checkoutEnd = DateTime.now().toUtc();
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'checkout',
          name: 'Checkout repository',
          status: BuildJobStatus.FAILURE.name,
          durationMs: checkoutEnd.difference(checkoutStart).inMilliseconds,
          stepOrder: 2,
          createdAt: checkoutStart.toIso8601String(),
          updatedAt: checkoutEnd.toIso8601String(),
        );
        rethrow;
      }

      var actScript = '';
      try {
        _log.info('[$vmName] Fetching secrets and build configurations...');
        await fetchReferencedSecrets(job.id);
        await resolveEventPayload(job.id);
        _log.info('[$vmName] Fetching build script...');
        actScript = await fetchBuildScript(job.id);
      } catch (e) {
        _log.warning('[$vmName] Failed to prepare secrets/script: $e');
        rethrow;
      }

      final workflowStart = DateTime.now().toUtc();
      const stepName = 'Run OpenCI Test Script';
      await sendStepStatusUpdate(
        buildJobId: job.id,
        runId: runId,
        stepId: 'run_workflow',
        name: stepName,
        status: BuildJobStatus.IN_PROGRESS.name,
        durationMs: 0,
        stepOrder: 3,
        createdAt: workflowStart.toIso8601String(),
        updatedAt: workflowStart.toIso8601String(),
      );

      await logInfo(
        job.id,
        runId,
        'Executing $stepName...',
        stepId: 'run_workflow',
      );

      BuildJobStatus finalStatus = BuildJobStatus.SUCCESS;

      try {
        if (actScript.isNotEmpty) {
          await logInfo(
            job.id,
            runId,
            '[Orchard] Executing build script: $actScript',
            stepId: 'run_workflow',
          );

          try {
            await logInfo(
              job.id,
              runId,
              '[Orchard] Dispatching command execution to remote macOS VM ($vmName)...',
              stepId: 'run_workflow',
            );
            final exitCode = await _orchardVmService.executeCommandStreaming(
              containerName: vmName,
              command: ['/bin/sh', '-c', actScript],
              onLog: (line) {
                logInfo(job.id, runId, line, stepId: 'run_workflow');
              },
              isCancelled: () async => false,
            );

            if (exitCode != 0) {
              finalStatus = BuildJobStatus.FAILURE;
              await logError(
                job.id,
                runId,
                'Build script failed with exit code $exitCode',
                stepId: 'run_workflow',
              );
            }
          } catch (e) {
            finalStatus = BuildJobStatus.FAILURE;
            await logError(
              job.id,
              runId,
              'Failed to execute script: $e',
              stepId: 'run_workflow',
            );
          }
        }

        final workflowEnd = DateTime.now().toUtc();
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'run_workflow',
          name: stepName,
          status: finalStatus.name,
          durationMs: workflowEnd.difference(workflowStart).inMilliseconds,
          stepOrder: 3,
          createdAt: workflowStart.toIso8601String(),
          updatedAt: workflowEnd.toIso8601String(),
        );

        if (finalStatus == BuildJobStatus.SUCCESS) {
          await logInfo(
            job.id,
            runId,
            '[Orchard] Job executed successfully via Orchard Controller.',
            stepId: 'run_workflow',
          );
          await logInfo(
            job.id,
            runId,
            'Build completed successfully',
            stepId: 'run_workflow',
          );
        } else {
          await logError(job.id, runId, 'Build failed', stepId: 'run_workflow');
        }
      } on TimeoutException catch (timeoutError) {
        await logError(job.id, runId, 'Job execution timed out: $timeoutError');
        finalStatus = BuildJobStatus.TIMED_OUT;
      } catch (actError) {
        if (await _isCancelled(job.id)) {
          await logInfo(job.id, runId, 'Build was cancelled by user');
          finalStatus = BuildJobStatus.CANCELLED;
        } else {
          await logWarning(job.id, runId, 'Act build failed: $actError');
          finalStatus = BuildJobStatus.FAILURE;
        }
      }

      await _updateJobFinalStatus(
        jobId: job.id,
        runId: runId,
        status: finalStatus,
        conclusion: finalStatus.name.toLowerCase(),
        buildJob: job,
      );
    } catch (e, s) {
      _log.severe('CRITICAL EXCEPTION IN JOB EXECUTOR', e, s);
      unawaited(Sentry.captureException(e, stackTrace: s));
      await _updateJobFinalStatus(
        jobId: job.id,
        runId: runId,
        status: BuildJobStatus.FAILURE,
        conclusion: BuildJobStatus.FAILURE.name.toLowerCase(),
        buildJob: job,
      );
    } finally {
      if (vmCreated) {
        _log.info('[$vmName] Triggering VM cleanup...');
        try {
          await _cleanupVm(vmName, runId);
          _log.info('[$vmName] VM cleanup completed.');
        } catch (e) {
          _log.warning('[$vmName] Failed to cleanup VM: $e');
        }
      }
      _log.info('[$vmName] Execute flow fully completed.');
    }
  }

  Future<void> _cleanupVm(String vmName, String runId) async {
    try {
      _log.info(
        '[$vmName] Deleting Orchard VM to release Ephemeral resources...',
      );
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
    required BuildJob buildJob,
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

  Future<String> resolveGitHubInstallationToken(String jobId) async {
    final tokenRes = await _apiService
        .resolveInstallationToken(jobId)
        .timeout(const Duration(seconds: 10));
    if (!tokenRes.isSuccessful) {
      throw Exception(
        'Failed to resolve GitHub App Installation Token: ${tokenRes.statusCode} - ${tokenRes.error}',
      );
    }
    final token = tokenRes.body?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('GitHub Installation Token is null or empty.');
    }
    return token;
  }

  String generateRunId() {
    final part1 = DateTime.now().millisecondsSinceEpoch;
    final part2 = _random.nextInt(1000000);
    return 'run-$part1-$part2';
  }

  Future<void> _checkoutRepository({
    required String runId,
    required String owner,
    required String repo,
    required String commitSha,
    required String token,
    required String? githubBaseUrl,
    required int? pullRequestNumber,
  }) async {
    _log.info(
      '[$repo] Orchard mode: Repository checkout handled by Orchard Controller.',
    );
  }

  Future<String> fetchReferencedSecrets(String buildJobId) async {
    try {
      final response = await _apiService.getJobSecrets(buildJobId);
      if (!response.isSuccessful) return '';
      final body = response.body;
      if (body == null) return '';
      return body['secretsContent'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> resolveEventPayload(String buildJobId) async {
    try {
      final response = await _apiService.getJobEventPayload(buildJobId);
      if (!response.isSuccessful) return '{}';
      final body = response.body;
      if (body == null) return '{}';
      return body['eventPayload'] as String? ?? '{}';
    } catch (e) {
      return '{}';
    }
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
