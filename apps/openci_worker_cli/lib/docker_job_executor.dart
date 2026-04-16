import 'dart:async';

import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_worker_cli/cloud_function_caller.dart';
import 'package:openci_worker_cli/docker_runner.dart';
import 'package:openci_worker_cli/job_executor.dart';
import 'package:openci_worker_cli/logger.dart';
import 'package:openci_worker_cli/run_manager.dart';

/// Processes a build job inside a Docker container on Linux.
/// Mirrors the flow in [processJob] (job_executor.dart) but uses
/// Docker instead of Lume VMs. No SSH, no VM boot wait, no IP lookup.
Future<bool> processDockerJob(
  Firestore firestore,
  String projectId,
  String serviceAccountPath,
  String workerId, {
  void Function()? onJobFound,
}) async {
  final buildJob = await claimBuildJob(firestore);
  if (buildJob == null) return false;

  onJobFound?.call();

  final buildJobId = buildJob.id;
  final token = buildJob.installationToken!;
  final owner = buildJob.owner;
  final repo = buildJob.repo;
  final commitSha = buildJob.commitSha!;

  final runId = await initializeRun(firestore, buildJobId);
  final name = containerName(workerId: workerId, buildJobId: buildJobId);

  await logInfo(
    firestore,
    buildJobId,
    runId,
    'Processing job: $buildJobId for $owner/$repo (Docker)',
  );

  await createContainer(name);
  await startContainer(name);

  Future<void> exec(String command) => execInContainer(
    name: name,
    command: command,
    firestore: firestore,
    buildJobId: buildJobId,
    runId: runId,
    token: token,
  );

  Future<bool> isCancelled() async {
    try {
      final doc = await firestore
          .collection(buildJobsCollection)
          .doc(buildJobId)
          .get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['status'] == 'cancelled';
    } catch (_) {
      return false;
    }
  }

  try {
    final workflowFileName = buildJob.workflowFileName;
    if (workflowFileName == null || workflowFileName.isEmpty) {
      await logError(
        firestore,
        buildJobId,
        runId,
        'workflowFileName is missing in build job data',
      );
      throw Exception('workflowFileName is missing');
    }

    await logInfo(firestore, buildJobId, runId, 'Workflow: $workflowFileName');

    // ── Clone repository ──
    await logInfo(
      firestore,
      buildJobId,
      runId,
      'Cloning repository $owner/$repo...',
    );
    final cloneUrl =
        'https://x-access-token:$token@github.com/$owner/$repo.git';

    await exec('git clone --depth 1 --no-checkout $cloneUrl');

    final pullRequestNumber = buildJob.pullRequestNumber;

    await logInfo(
      firestore,
      buildJobId,
      runId,
      'Fetching commit $commitSha...',
    );
    try {
      await exec('git -C $repo fetch --depth 1 origin $commitSha');
    } catch (_) {
      if (pullRequestNumber != null) {
        await logInfo(
          firestore,
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

    await logInfo(
      firestore,
      buildJobId,
      runId,
      'Checking out commit $commitSha...',
    );
    await exec('git -C $repo checkout $commitSha');

    await logInfo(
      firestore,
      buildJobId,
      runId,
      'Repository cloned successfully',
    );

    // ── Environment variables & secrets ──
    final envVars = await buildEnvVars(
      firestore: firestore,
      buildJob: buildJob,
      projectId: projectId,
      buildJobId: buildJobId,
      runId: runId,
    );

    final secretVars = await buildSecretVars(
      firestore: firestore,
      serviceAccountPath: serviceAccountPath,
      token: token,
      buildJobId: buildJobId,
      runId: runId,
      teamId: buildJob.teamId,
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
    await logInfo(
      firestore,
      buildJobId,
      runId,
      'Environment variables written',
    );

    // ── Run act ──
    await logInfo(firestore, buildJobId, runId, 'Running workflow with act...');

    final eventType = pullRequestNumber != null ? 'pull_request' : 'push';

    final jobKey = buildJob.jobKey;
    final jobFlag = jobKey != null ? '-j $jobKey ' : '';

    final actScript = [
      'set -e',
      'export PATH="/opt/dart-sdk/bin:/opt/flutter/bin:\$PATH"',
      'cd $repo',
      'act $eventType -W .openci/$workflowFileName '
          '$jobFlag'
          '-P macos-latest=-self-hosted '
          '-P macos-14=-self-hosted '
          '-P macos-15=-self-hosted '
          '-P ubuntu-latest=-self-hosted '
          '--env-file /tmp/openci-env '
          '--secret-file /tmp/openci-secrets',
    ].join('\n');

    await writeFileToContainer(name, '/tmp/openci-act.sh', actScript);
    await exec('chmod +x /tmp/openci-act.sh');

    await execStreamingInContainer(
      name,
      ['/bin/bash', '-l', '/tmp/openci-act.sh'],
      firestore,
      buildJobId,
      runId,
      token,
      isCancelled: isCancelled,
    );

    await Future.delayed(const Duration(seconds: 5));

    await logInfo(firestore, buildJobId, runId, 'Build completed successfully');
    await updateRunStatus(
      firestore,
      buildJobId,
      runId,
      'completed',
      conclusion: 'success',
    );

    await firestore.collection(buildJobsCollection).doc(buildJobId).update({
      'status': 'success',
      'completedAt': DateTime.now().toUtc().toIso8601String(),
    });

    // Notify cloud functions (replaces Firestore triggers)
    unawaited(
      notifyCheckRunUpdate(buildJobId, 'completed', conclusion: 'success'),
    );
    unawaited(notifyBuildJobStatusChange(buildJobId, 'success'));
  } catch (e, s) {
    await logError(
      firestore,
      buildJobId,
      runId,
      'Job failed: $e',
      stackTrace: s.toString(),
    );
    await updateRunStatus(
      firestore,
      buildJobId,
      runId,
      'completed',
      conclusion: 'failure',
    );

    await firestore.collection(buildJobsCollection).doc(buildJobId).update({
      'status': 'failure',
      'completedAt': DateTime.now().toUtc().toIso8601String(),
    });

    // Notify cloud functions (replaces Firestore triggers)
    unawaited(
      notifyCheckRunUpdate(buildJobId, 'completed', conclusion: 'failure'),
    );
    unawaited(notifyBuildJobStatusChange(buildJobId, 'failure'));
    rethrow;
  } finally {
    await flushRemainingLogs();
    try {
      await stopAndRemoveContainer(name);
    } catch (e) {
      await logWarning(
        firestore,
        buildJobId,
        runId,
        'Error removing container: $e',
      );
    }
    await flushRemainingLogs();
    await pruneStaleContainers(
      firestore,
      buildJobId,
      runId,
      workerId: workerId,
    );
  }

  return true;
}
