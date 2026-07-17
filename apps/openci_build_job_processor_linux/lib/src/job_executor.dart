import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:openci_build_job_processor_linux/src/incus/incus_service.dart';
import 'package:openci_build_job_processor_linux/src/logging/build_job_logger.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:retry/retry.dart';
import 'package:sentry/sentry.dart';

class JobExecutor {
  JobExecutor({
    required OpenCiApiService apiService,
    required IncusService incusService,
    required String baseInstanceName,
  }) : _apiService = apiService,
       _incusService = incusService,
       _baseInstanceName = baseInstanceName;

  final OpenCiApiService _apiService;
  final IncusService _incusService;
  final String _baseInstanceName;
  final _random = Random();
  final _log = Logger('JobExecutor');
  Duration retryDelay = const Duration(seconds: 5);

  Future<void> execute(BuildJob job, String runId) async {
    final shortId = job.id.length > 8 ? job.id.substring(0, 8) : job.id;
    final containerName = 'openci-vm-$shortId';
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

      await retryOptions.retry(
        () async {
          _log.info(
            '[$containerName] Preparing container (cloning & starting)...',
          );
          await _prepareContainer(
            baseInstanceName: _baseInstanceName,
            containerName: containerName,
            onCreated: () => containerCreated = true,
          );
        },
        onRetry: (e) async {
          _log.warning(
            '[$containerName] Container preparation failed: $e. '
            'Cleaning up failed container before retry...',
          );
          try {
            await _cleanupContainer(containerName);
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

      _log.info(
        '[$containerName] Checking out repository ${job.owner}/${job.repo}@${job.commitSha}...',
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

      _log.info('[$containerName] Fetching secrets...');
      final secretFileContent = await fetchReferencedSecrets(job.id);

      _log.info('[$containerName] Writing secrets to container...');
      await _incusService.writeFile(
        containerName,
        '/tmp/openci-secrets',
        secretFileContent,
      );

      _log.info('[$containerName] Fetching event payload...');
      final eventFileContent = await resolveEventPayload(job.id);

      _log.info('[$containerName] Writing event payload to container...');
      await _incusService.writeFile(
        containerName,
        '/tmp/openci-event.json',
        eventFileContent,
      );

      _log.info('[$containerName] Fetching build script...');
      final actScript = await fetchBuildScript(job.id);

      _log.info('[$containerName] Writing build script to container...');
      await _incusService.writeFile(
        containerName,
        '/tmp/openci-act.sh',
        actScript,
        mode: '0755',
      );

      await logInfo(job.id, runId, 'Running workflow with act...');

      BuildJobStatus finalStatus = BuildJobStatus.SUCCESS;

      try {
        final exitCode = await _incusService.executeCommandStreaming(
          containerName: containerName,
          command: ['/bin/bash', '-l', '/tmp/openci-act.sh'],
          onLog: (line) {
            final stripped = stripActPrefix(line);
            writeBuildLog(job.id, runId, LogLevel.info, stripped);
          },
          isCancelled: () => _isCancelled(job.id),
        );

        if (exitCode != 0) {
          throw Exception('Act build failed with exit code: $exitCode');
        }
        await logInfo(job.id, runId, 'Build completed successfully');
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
      if (containerCreated) {
        _log.info('[$containerName] Triggering container cleanup...');
        try {
          await _cleanupContainer(containerName);
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

  Future<void> _prepareContainer({
    required String baseInstanceName,
    required String containerName,
    required void Function() onCreated,
  }) async {
    try {
      await _incusService.stopContainer(containerName);
    } catch (_) {}
    try {
      await _incusService.deleteContainer(containerName);
    } catch (_) {}

    await _incusService.cloneContainer(baseInstanceName, containerName);
    onCreated();

    await _incusService.startContainer(containerName);
  }

  Future<void> _cleanupContainer(String containerName) async {
    try {
      await _incusService.stopContainer(containerName);
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    try {
      await _incusService.deleteContainer(containerName);
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
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
}
