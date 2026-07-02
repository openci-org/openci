import 'dart:async';

import 'package:openci_shared/openci_shared.dart';
import 'package:openci_worker_cli/build_job_logger.dart';
import 'package:openci_worker_cli/cloud_function_caller.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:openci_worker_cli/docker_runner.dart';
import 'package:openci_worker_cli/get_secret_service.dart';
import 'package:openci_worker_cli/job_executor.dart';
import 'package:retry/retry.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Processes a build job inside a Docker container on Linux.
/// Mirrors the flow in [processJob] (job_executor.dart) but uses
/// Docker instead of Lume VMs. No SSH, no VM boot wait, no IP lookup.
Future<bool> processDockerJob(
  ApiClient apiClient,
  String workerId, {
  void Function()? onJobFound,
}) async {
  final buildJob = await apiClient.claimNextJob(null);
  if (buildJob == null) return false;

  onJobFound?.call();

  final buildJobId = buildJob.id;
  final runId = _uuid.v4();

  // Initialize Logger
  setLoggerApiClient(apiClient);

  await apiClient.createRun(buildJobId, runId);
  await apiClient.updateCheckRun(buildJob, 'in_progress');

  await logInfo(
    buildJobId,
    runId,
    'Processing job: $buildJobId for ${buildJob.owner}/${buildJob.repo} (Docker) [v$version]',
  );

  // Resolve Installation Token
  String token;
  try {
    final tokenResp = await apiClient.resolveInstallationToken(buildJobId);
    token = tokenResp['token'] as String;
  } catch (e) {
    await logError(
      buildJobId,
      runId,
      'Failed to resolve GitHub App Installation Token: $e',
    );
    await apiClient.updateRunStatus(
      buildJobId: buildJobId,
      runId: runId,
      status: 'completed',
      conclusion: 'failure',
    );
    await apiClient.completeJob(buildJobId, 'FAILURE');
    await apiClient.updateCheckRun(
      buildJob,
      'completed',
      conclusion: 'failure',
    );
    await apiClient.handleBuildJobStatusChange(buildJob, 'FAILURE');
    return true;
  }

  final owner = buildJob.owner;
  final repo = buildJob.repo;
  final commitSha = buildJob.commitSha ?? '';
  final name = containerName(workerId: workerId, buildJobId: buildJobId);

  Future<void> exec(String command) => execInContainer(
    name: name,
    command: command,
    buildJobId: buildJobId,
    runId: runId,
    token: token,
  );

  Future<bool> isCancelled() async {
    try {
      return await apiClient.isJobCancelled(buildJobId);
    } catch (_) {
      return false;
    }
  }

  try {
    final workflowFileName = buildJob.workflowFileName;
    if (workflowFileName == null || workflowFileName.isEmpty) {
      throw Exception('workflowFileName is missing');
    }

    await logInfo(buildJobId, runId, 'Workflow: $workflowFileName');

    await createContainer(name);
    await startContainer(name);

    // ── Clone repository ──
    await logInfo(buildJobId, runId, 'Cloning repository $owner/$repo...');
    final githubHost = buildJob.githubBaseUrl != null
        ? Uri.parse(buildJob.githubBaseUrl!).host
        : 'github.com';
    final cloneUrl =
        'https://x-access-token:$token@$githubHost/$owner/$repo.git';

    var cloneAttempt = 0;
    await retry(
      () => exec('git clone --depth 1 --no-checkout $cloneUrl'),
      delayFactor: const Duration(seconds: 5),
      randomizationFactor: 0,
      maxAttempts: 3,
      onRetry: (e) {
        cloneAttempt++;
        logInfo(
          buildJobId,
          runId,
          'git clone failed (attempt $cloneAttempt/3). Retrying...',
        );
      },
    );

    final pullRequestNumber = buildJob.pullRequestNumber;

    await logInfo(buildJobId, runId, 'Fetching commit $commitSha...');
    var fetchAttempt = 0;
    await retry(
      () async {
        try {
          await exec('git -C $repo fetch --depth 1 origin $commitSha');
        } catch (_) {
          if (pullRequestNumber != null) {
            await logInfo(
              buildJobId,
              runId,
              'Direct fetch failed, trying PR ref pull/$pullRequestNumber/head...',
            );
            await exec(
              'git -C $repo fetch --depth 1 origin pull/$pullRequestNumber/head',
            );
          } else {
            rethrow;
          }
        }
      },
      delayFactor: const Duration(seconds: 5),
      randomizationFactor: 0,
      maxAttempts: 3,
      onRetry: (e) {
        fetchAttempt++;
        logInfo(
          buildJobId,
          runId,
          'git fetch failed (attempt $fetchAttempt/3). Retrying...',
        );
      },
    );

    await logInfo(buildJobId, runId, 'Checking out commit $commitSha...');
    await exec('git -C $repo checkout $commitSha');
    await logInfo(buildJobId, runId, 'Repository cloned successfully');

    // Build Environment variables
    final envVars = await buildEnvVars(
      apiClient: apiClient,
      buildJob: buildJob,
      projectId: apiClient.projectId,
      buildJobId: buildJobId,
      runId: runId,
    );

    // Build Secrets (filtered by workflow references)
    final secretVars = await buildSecretVars(
      apiClient: apiClient,
      token: token,
      buildJobId: buildJobId,
      runId: runId,
      buildJob: buildJob,
    );

    final envFileLines = <String>[];
    final secretFileLines = <String>[];

    for (final entry in envVars.entries) {
      final escaped = entry.value.replaceAll('\n', '\\n');
      envFileLines.add('${entry.key}=$escaped');
    }
    for (final entry in secretVars.entries) {
      final escaped = entry.value.replaceAll('\n', '\\n');
      secretFileLines.add('${entry.key}=$escaped');
    }

    await writeFileToContainer(
      name,
      '/tmp/openci-env',
      envFileLines.join('\n'),
    );
    await writeFileToContainer(
      name,
      '/tmp/openci-secrets',
      secretFileLines.join('\n'),
    );
    await writeFileToContainer(
      name,
      '/tmp/openci-event.json',
      buildEventPayload(buildJob),
    );
    await logInfo(buildJobId, runId, 'Environment variables written');

    // ── Run act ──
    await logInfo(buildJobId, runId, 'Running workflow with act...');

    final eventType = pullRequestNumber != null ? 'pull_request' : 'push';
    final jobKey = buildJob.workflowJobKey ?? buildJob.jobKey;
    final jobFlag = jobKey != null ? '-j $jobKey ' : '';

    final matrixArgs = <String>[];
    final buildJobMatrix = buildJob.matrix;
    if (buildJobMatrix != null && buildJobMatrix.isNotEmpty) {
      for (final entry in buildJobMatrix.entries) {
        matrixArgs.add('--matrix "${entry.key}:${entry.value}"');
      }
    }
    final matrixFlag = matrixArgs.isNotEmpty ? '${matrixArgs.join(' ')} ' : '';

    final uniqueHome = '/tmp/openci-home-${_uuid.v4()}';

    final actScript = [
      'set -e',
      'mkdir -p $uniqueHome',
      'export HOME=$uniqueHome',
      'export PATH="/opt/dart-sdk/bin:/opt/flutter/bin:\$PATH"',
      'cd $repo',
      'act $eventType -W .openci/$workflowFileName '
          '$jobFlag'
          '$matrixFlag'
          '--pull=false '
          '-P macos-latest=-self-hosted '
          '-P macos-14=-self-hosted '
          '-P macos-15=-self-hosted '
          '-P ubuntu-latest=$dockerImage '
          '-e /tmp/openci-event.json '
          '--env-file /tmp/openci-env '
          '--secret-file /tmp/openci-secrets',
    ].join('\n');

    await writeFileToContainer(name, '/tmp/openci-act.sh', actScript);
    await exec('chmod +x /tmp/openci-act.sh');

    try {
      await execStreamingInContainer(
        name,
        ['/bin/bash', '-l', '/tmp/openci-act.sh'],
        buildJobId,
        runId,
        token,
        isCancelled: isCancelled,
      );

      await Future.delayed(const Duration(seconds: 5));

      await logInfo(buildJobId, runId, 'Build completed successfully');
      await apiClient.updateRunStatus(
        buildJobId: buildJobId,
        runId: runId,
        status: 'completed',
        conclusion: 'success',
      );
      await apiClient.completeJob(buildJobId, 'SUCCESS');

      final completedJob = buildJob.copyWith(
        status: BuildJobStatus.SUCCESS,
        latestRunId: runId,
        completedAt: DateTime.now(),
      );
      await apiClient.updateCheckRun(
        completedJob,
        'completed',
        conclusion: 'success',
      );
      await apiClient.handleBuildJobStatusChange(completedJob, 'SUCCESS');
    } on TimeoutException catch (timeoutError) {
      await logError(
        buildJobId,
        runId,
        'Job execution timed out: $timeoutError',
      );
      await apiClient.updateRunStatus(
        buildJobId: buildJobId,
        runId: runId,
        status: 'completed',
        conclusion: 'timed_out',
      );
      await apiClient.completeJob(buildJobId, 'TIMED_OUT');

      final timedOutJob = buildJob.copyWith(
        status: BuildJobStatus.TIMED_OUT,
        latestRunId: runId,
        completedAt: DateTime.now(),
      );
      await apiClient.updateCheckRun(
        timedOutJob,
        'completed',
        conclusion: 'timed_out',
      );
      await apiClient.handleBuildJobStatusChange(timedOutJob, 'TIMED_OUT');
      return true;
    } catch (actError) {
      await logWarning(buildJobId, runId, 'Act build failed: $actError');
      await apiClient.updateRunStatus(
        buildJobId: buildJobId,
        runId: runId,
        status: 'completed',
        conclusion: 'failure',
      );
      await apiClient.completeJob(buildJobId, 'FAILURE');

      final failedJob = buildJob.copyWith(
        status: BuildJobStatus.FAILURE,
        latestRunId: runId,
        completedAt: DateTime.now(),
      );
      await apiClient.updateCheckRun(
        failedJob,
        'completed',
        conclusion: 'failure',
      );
      await apiClient.handleBuildJobStatusChange(failedJob, 'FAILURE');
      return true;
    }
  } on TimeoutException catch (e, s) {
    await logError(
      buildJobId,
      runId,
      'Job timed out: $e',
      stackTrace: s.toString(),
    );
    await apiClient.updateRunStatus(
      buildJobId: buildJobId,
      runId: runId,
      status: 'completed',
      conclusion: 'timed_out',
    );
    await apiClient.completeJob(buildJobId, 'TIMED_OUT');

    final timedOutJob = buildJob.copyWith(
      status: BuildJobStatus.TIMED_OUT,
      latestRunId: runId,
      completedAt: DateTime.now(),
    );
    await apiClient.updateCheckRun(
      timedOutJob,
      'completed',
      conclusion: 'timed_out',
    );
    await apiClient.handleBuildJobStatusChange(timedOutJob, 'TIMED_OUT');
    return true;
  } catch (e, s) {
    await logError(
      buildJobId,
      runId,
      'Job failed: $e',
      stackTrace: s.toString(),
    );
    await apiClient.updateRunStatus(
      buildJobId: buildJobId,
      runId: runId,
      status: 'completed',
      conclusion: 'failure',
    );
    await apiClient.completeJob(buildJobId, 'FAILURE');

    final failedJob = buildJob.copyWith(
      status: BuildJobStatus.FAILURE,
      latestRunId: runId,
      completedAt: DateTime.now(),
    );
    await apiClient.updateCheckRun(
      failedJob,
      'completed',
      conclusion: 'failure',
    );
    await apiClient.handleBuildJobStatusChange(failedJob, 'FAILURE');
    rethrow;
  } finally {
    await flushRemainingLogs(runId: runId);
    try {
      await stopAndRemoveContainer(name);
    } catch (e) {
      await logWarning(buildJobId, runId, 'Error removing container: $e');
    }
    await pruneStaleContainers(buildJobId, runId, workerId: workerId);
  }

  return true;
}
