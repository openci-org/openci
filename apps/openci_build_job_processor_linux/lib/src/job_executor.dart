import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor_linux/src/incus/incus_service.dart';
import 'package:openci_build_job_processor_linux/src/logging/build_job_logger.dart';
import 'package:openci_build_job_processor_linux/src/logging/build_step_logger.dart';
import 'package:openci_build_job_processor_linux/src/vm/incus_vm_service.dart';
import 'package:openci_job_processor_shared/openci_job_processor_shared.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:retry/retry.dart';
import 'package:sentry/sentry.dart';

class JobExecutor {
  JobExecutor({
    required OpenCiApiService apiService,
    required IncusService incusService,
    required String baseInstanceName,
    VmService? vmService,
  }) : _apiService = apiService,
       _incusService = incusService,
       _baseInstanceName = baseInstanceName,
       _vmService = vmService ?? IncusVmService(incusService: incusService);

  final OpenCiApiService _apiService;
  final IncusService _incusService;
  final String _baseInstanceName;
  final VmService _vmService;
  final _random = Random();
  final _log = Logger('JobExecutor');
  Duration retryDelay = const Duration(seconds: 5);

  Future<void> execute(BuildJob job, String runId) async {
    final containerName = _vmService.generateVmName(job.id);
    bool containerCreated = false;

    try {
      _log.info(
        '[$containerName] Starting execute flow. Creating run record...',
      );
      await _createRun(job.id, runId);

      _log.info('[$containerName] Resolving GitHub installation token...');
      final token = await resolveGitHubInstallationToken(job.id);

      const retryOptions = RetryOptions(
        maxAttempts: 2,
        delayFactor: Duration(seconds: 5),
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
            _log.info(
              '[$containerName] Preparing container (cloning & starting)...',
            );
            await _vmService.prepare(
              baseInstanceName: _baseInstanceName,
              containerName: containerName,
              onCreated: () => containerCreated = true,
            );
          },
          onRetry: (e) async {
            await _logAndSend(
              jobId: job.id,
              runId: runId,
              containerName: containerName,
              message:
                  'Container preparation failed: $e. Cleaning up failed container before retry...',
              level: LogLevel.warning,
            );
            try {
              await _vmService.cleanup(containerName);
              containerCreated = false;
            } catch (cleanupErr, cleanupStack) {
              _log.warning(
                '[$containerName] Cleanup failed during retry prep: $cleanupErr',
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
        await _logAndSend(
          jobId: job.id,
          runId: runId,
          containerName: containerName,
          message:
              'Checking out repository ${job.owner}/${job.repo}@${job.commitSha}...',
        );
        await _checkoutRepository(
          containerName: containerName,
          buildJobId: job.id,
          runId: runId,
          owner: job.owner,
          repo: job.repo,
          commitSha: job.commitSha ?? '',
          token: token,
          githubBaseUrl: job.githubBaseUrl,
          pullRequestNumber: job.pullRequestNumber,
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

      final secretsStart = DateTime.now().toUtc();
      await sendStepStatusUpdate(
        buildJobId: job.id,
        runId: runId,
        stepId: 'configure_secrets',
        name: 'Configure secrets and script',
        status: BuildJobStatus.IN_PROGRESS.name,
        durationMs: 0,
        stepOrder: 3,
        createdAt: secretsStart.toIso8601String(),
        updatedAt: secretsStart.toIso8601String(),
      );

      try {
        await _logAndSend(
          jobId: job.id,
          runId: runId,
          containerName: containerName,
          message: 'Fetching secrets...',
        );
        final secretFileContent = await fetchReferencedSecrets(job.id);

        await _logAndSend(
          jobId: job.id,
          runId: runId,
          containerName: containerName,
          message: 'Writing secrets to container...',
        );
        await _incusService.writeFile(
          containerName,
          '/tmp/openci-secrets',
          secretFileContent,
        );

        await _logAndSend(
          jobId: job.id,
          runId: runId,
          containerName: containerName,
          message: 'Fetching event payload...',
        );
        final eventFileContent = await resolveEventPayload(job.id);

        await _logAndSend(
          jobId: job.id,
          runId: runId,
          containerName: containerName,
          message: 'Writing event payload to container...',
        );
        await _incusService.writeFile(
          containerName,
          '/tmp/openci-event.json',
          eventFileContent,
        );

        await _logAndSend(
          jobId: job.id,
          runId: runId,
          containerName: containerName,
          message: 'Fetching build script...',
        );
        final actScript = await fetchBuildScript(job.id);

        await _logAndSend(
          jobId: job.id,
          runId: runId,
          containerName: containerName,
          message: 'Writing build script to container...',
        );
        await _incusService.writeFile(
          containerName,
          '/tmp/openci-act.sh',
          actScript,
          mode: '0755',
        );

        final secretsEnd = DateTime.now().toUtc();
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'configure_secrets',
          name: 'Configure secrets and script',
          status: BuildJobStatus.SUCCESS.name,
          durationMs: secretsEnd.difference(secretsStart).inMilliseconds,
          stepOrder: 3,
          createdAt: secretsStart.toIso8601String(),
          updatedAt: secretsEnd.toIso8601String(),
        );
      } catch (e) {
        final secretsEnd = DateTime.now().toUtc();
        await sendStepStatusUpdate(
          buildJobId: job.id,
          runId: runId,
          stepId: 'configure_secrets',
          name: 'Configure secrets and script',
          status: BuildJobStatus.FAILURE.name,
          durationMs: secretsEnd.difference(secretsStart).inMilliseconds,
          stepOrder: 3,
          createdAt: secretsStart.toIso8601String(),
          updatedAt: secretsEnd.toIso8601String(),
        );
        rethrow;
      }

      await logInfo(job.id, runId, 'Running workflow with act...');

      BuildJobStatus finalStatus = BuildJobStatus.SUCCESS;

      final jobStates = <String, Map<String, dynamic>>{};
      final actJobPattern = RegExp(r'^\[([^\]]+)\]\s*(.*)$');
      final runPattern = RegExp(r'^⭐\s*Run (.*)$');

      Map<String, dynamic> getJobState(String jobName) {
        return jobStates.putIfAbsent(
          jobName,
          () => {
            'currentStepId': null,
            'currentStepName': null,
            'stepOrder': 10,
            'stepStartTime': DateTime.now().toUtc(),
          },
        );
      }

      Future<void> closeJobCurrentStep(
        String jobName, {
        required String status,
      }) async {
        final state = getJobState(jobName);
        final prevStepId = state['currentStepId'] as String?;
        final prevStepName = state['currentStepName'] as String?;
        final prevStepStartTime = state['stepStartTime'] as DateTime;
        final prevStepOrder = state['stepOrder'] as int;

        state['currentStepId'] = null;
        state['currentStepName'] = null;

        if (prevStepId != null && prevStepName != null) {
          final now = DateTime.now().toUtc();
          final duration = now.difference(prevStepStartTime).inMilliseconds;
          await sendStepStatusUpdate(
            buildJobId: job.id,
            runId: runId,
            stepId: prevStepId,
            name: '[$jobName] $prevStepName',
            status: status,
            durationMs: duration,
            stepOrder: prevStepOrder,
            createdAt: prevStepStartTime.toIso8601String(),
            updatedAt: now.toIso8601String(),
          );
        }
      }

      Future<void> closeAllJobs({required String status}) async {
        for (final jName in jobStates.keys) {
          await closeJobCurrentStep(jName, status: status);
        }
      }

      try {
        final exitCode = await _incusService.executeCommandStreaming(
          containerName: containerName,
          command: ['/bin/bash', '-l', '/tmp/openci-act.sh'],
          onLog: (line) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) return;

            final match = actJobPattern.firstMatch(trimmed);
            String jobName = 'global';
            String cleanLine = trimmed;

            if (match != null) {
              final prefixContent = match.group(1) ?? '';
              final msg = match.group(2) ?? '';

              final slashIndex = prefixContent.lastIndexOf('/');
              jobName = slashIndex != -1
                  ? prefixContent.substring(slashIndex + 1).trim()
                  : prefixContent.trim();

              cleanLine = msg.replaceFirst(RegExp(r'^\|\s*'), '').trim();
            }

            if (cleanLine.isEmpty) return;

            // ⭐ Run <Step Name> の検知 (act の出力パース)
            if (cleanLine.contains('⭐') && cleanLine.contains('Run ')) {
              final cleanRunLine = cleanLine
                  .replaceAll(RegExp(r'^\[[^\]]+\]\s*'), '')
                  .trim();
              final runMatch = runPattern.firstMatch(cleanRunLine);
              final stepName = runMatch?.group(1)?.trim() ?? 'Run Step';

              final state = getJobState(jobName);
              final prevStepId = state['currentStepId'] as String?;
              final prevStepName = state['currentStepName'] as String?;
              final prevStepStartTime = state['stepStartTime'] as DateTime;
              final prevStepOrder = state['stepOrder'] as int;

              state['currentStepName'] = stepName;
              final sanitizedJobName = jobName.toLowerCase().replaceAll(
                RegExp(r'[^a-z0-9]'),
                '_',
              );
              final sanitizedStepName = stepName.toLowerCase().replaceAll(
                RegExp(r'[^a-z0-9]'),
                '_',
              );
              final stepId = 'step_${sanitizedJobName}_$sanitizedStepName';
              state['currentStepId'] = stepId;
              final startTime = DateTime.now().toUtc();
              state['stepStartTime'] = startTime;
              final currentStepOrder = prevStepId != null
                  ? prevStepOrder + 1
                  : prevStepOrder;
              state['stepOrder'] = currentStepOrder + 1;

              unawaited(() async {
                if (prevStepId != null && prevStepName != null) {
                  final now = DateTime.now().toUtc();
                  final duration = now
                      .difference(prevStepStartTime)
                      .inMilliseconds;
                  await sendStepStatusUpdate(
                    buildJobId: job.id,
                    runId: runId,
                    stepId: prevStepId,
                    name: '[$jobName] $prevStepName',
                    status: 'SUCCESS',
                    durationMs: duration,
                    stepOrder: prevStepOrder,
                    createdAt: prevStepStartTime.toIso8601String(),
                    updatedAt: now.toIso8601String(),
                  );
                }
                await sendStepStatusUpdate(
                  buildJobId: job.id,
                  runId: runId,
                  stepId: stepId,
                  name: '[$jobName] $stepName',
                  status: 'IN_PROGRESS',
                  durationMs: 0,
                  stepOrder: currentStepOrder,
                  createdAt: startTime.toIso8601String(),
                  updatedAt: startTime.toIso8601String(),
                );
              }());
            } else if (cleanLine.contains('✅') &&
                cleanLine.contains('Success - ')) {
              unawaited(closeJobCurrentStep(jobName, status: 'SUCCESS'));
            } else if (cleanLine.contains('❌') &&
                cleanLine.contains('Failure - ')) {
              unawaited(closeJobCurrentStep(jobName, status: 'FAILURE'));
            }

            final state = getJobState(jobName);
            final currentStepId = state['currentStepId'] as String?;
            if (currentStepId != null) {
              writeBuildStepLog(job.id, runId, currentStepId, cleanLine);
            } else {
              writeBuildStepLog(job.id, runId, 'pre_build_setup', cleanLine);
            }

            writeBuildLog(
              job.id,
              runId,
              LogLevel.info,
              '[$jobName] $cleanLine',
            );
          },
          isCancelled: () => _isCancelled(job.id),
        );

        if (exitCode != 0) {
          throw Exception('Act build failed with exit code: $exitCode');
        }
        await logInfo(job.id, runId, 'Build completed successfully');
      } on TimeoutException catch (timeoutError) {
        await closeAllJobs(status: 'FAILURE');
        await flushRemainingStepLogs(runId: runId);
        await logError(job.id, runId, 'Job execution timed out: $timeoutError');
        finalStatus = BuildJobStatus.TIMED_OUT;
      } catch (actError) {
        await closeAllJobs(status: 'FAILURE');
        await flushRemainingStepLogs(runId: runId);
        if (await _isCancelled(job.id)) {
          await logInfo(job.id, runId, 'Build was cancelled by user');
          finalStatus = BuildJobStatus.CANCELLED;
        } else {
          await logWarning(job.id, runId, 'Act build failed: $actError');
          finalStatus = BuildJobStatus.FAILURE;
        }
      } finally {
        await closeAllJobs(
          status: finalStatus == BuildJobStatus.SUCCESS ? 'SUCCESS' : 'FAILURE',
        );
        await flushRemainingStepLogs(runId: runId);
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
      if (containerCreated) {
        _log.info('[$containerName] Triggering container cleanup...');
        try {
          await _vmService.cleanup(containerName);
          _log.info('[$containerName] Container cleanup completed.');
        } catch (e) {
          _log.warning('[$containerName] Failed to cleanup container: $e');
        }
      }
      _log.info('[$containerName] Flushing remaining logs...');
      await flushRemainingLogs(runId: runId);
      _log.info('[$containerName] Execute flow fully completed.');
    }
  }

  Future<void> _checkoutRepository({
    required String containerName,
    required String buildJobId,
    required String runId,
    required String owner,
    required String repo,
    required String commitSha,
    required String token,
    required String? githubBaseUrl,
    required int? pullRequestNumber,
  }) async {
    final githubHost = githubBaseUrl != null
        ? Uri.parse(githubBaseUrl).host
        : 'github.com';
    final cloneUrl =
        'https://x-access-token:$token@$githubHost/$owner/$repo.git';

    await retry(
      () async {
        final exitCode = await _incusService.executeCommandStreaming(
          containerName: containerName,
          command: ['git', 'clone', '--depth', '1', '--no-checkout', cloneUrl],
          onLog: (line) =>
              writeBuildLog(buildJobId, runId, LogLevel.info, line),
          isCancelled: () => _isCancelled(buildJobId),
        );
        if (exitCode != 0) {
          throw Exception('Failed to clone repository. Exit code: $exitCode');
        }
      },
      delayFactor: retryDelay,
      randomizationFactor: 0,
      maxAttempts: 3,
    );

    var exitCode = -1;
    var fetchCommand = [
      'git',
      '-C',
      repo,
      'fetch',
      '--depth',
      '1',
      'origin',
      commitSha,
    ];
    exitCode = await _incusService.executeCommandStreaming(
      containerName: containerName,
      command: fetchCommand,
      onLog: (line) => writeBuildLog(buildJobId, runId, LogLevel.info, line),
      isCancelled: () => _isCancelled(buildJobId),
    );

    if (exitCode != 0 && pullRequestNumber != null) {
      fetchCommand = [
        'git',
        '-C',
        repo,
        'fetch',
        '--depth',
        '1',
        'origin',
        'pull/$pullRequestNumber/head',
      ];
      exitCode = await _incusService.executeCommandStreaming(
        containerName: containerName,
        command: fetchCommand,
        onLog: (line) => writeBuildLog(buildJobId, runId, LogLevel.info, line),
        isCancelled: () => _isCancelled(buildJobId),
      );
    }
    if (exitCode != 0) {
      throw Exception('Failed to fetch commit. Exit code: $exitCode');
    }

    exitCode = await _incusService.executeCommandStreaming(
      containerName: containerName,
      command: ['git', '-C', repo, 'checkout', commitSha],
      onLog: (line) => writeBuildLog(buildJobId, runId, LogLevel.info, line),
      isCancelled: () => _isCancelled(buildJobId),
    );
    if (exitCode != 0) {
      throw Exception('Failed to checkout commit. Exit code: $exitCode');
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

  Future<String> fetchReferencedSecrets(String buildJobId) async {
    final response = await _apiService.getJobSecrets(buildJobId);
    if (!response.isSuccessful) {
      throw Exception(
        'Failed to get job secrets: ${response.statusCode} - ${response.error}',
      );
    }
    final body = response.body;
    if (body == null) return '';
    return body['secretsContent'] as String? ?? '';
  }

  Future<String> resolveEventPayload(String buildJobId) async {
    final response = await _apiService.getJobEventPayload(buildJobId);
    if (!response.isSuccessful) {
      throw Exception(
        'Failed to get job event payload: ${response.statusCode} - ${response.error}',
      );
    }
    final body = response.body;
    if (body == null) return '';
    return body['eventPayload'] as String? ?? '';
  }

  Future<String> fetchBuildScript(String buildJobId) async {
    final response = await _apiService.getJobBuildScript(buildJobId);
    if (!response.isSuccessful) {
      throw Exception(
        'Failed to get job build script: ${response.statusCode} - ${response.error}',
      );
    }
    final body = response.body;
    if (body == null) return '';
    return body['script'] as String? ?? '';
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

  Future<void> _logAndSend({
    required String jobId,
    required String runId,
    required String containerName,
    required String message,
    LogLevel level = LogLevel.info,
  }) async {
    switch (level) {
      case LogLevel.warning:
        _log.warning('[$containerName] $message');
      case LogLevel.error:
        _log.severe('[$containerName] $message');
      case LogLevel.info:
        _log.info('[$containerName] $message');
    }
    await writeBuildLog(jobId, runId, level, message);
  }
}
