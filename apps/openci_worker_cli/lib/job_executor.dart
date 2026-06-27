import 'dart:async';
import 'dart:convert';

import 'package:avf_dart/avf_dart.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_worker_cli/build_job_logger.dart';
import 'package:openci_worker_cli/cloud_function_caller.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:openci_worker_cli/get_secret_service.dart';
import 'package:openci_worker_cli/vm.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

const _uuid = Uuid();

class RuntimeWorkflowRewriteResult {
  final String content;
  final bool rewritten;
  final String? reason;
  RuntimeWorkflowRewriteResult({
    required this.content,
    required this.rewritten,
    this.reason,
  });
}

RuntimeWorkflowRewriteResult rewriteWorkflowForSingleOpenCiJob(
  String workflowContent,
  String? jobKey,
  List<String> needs,
  Map<String, dynamic>? matrix,
) {
  if (jobKey == null || jobKey.isEmpty) {
    return RuntimeWorkflowRewriteResult(
      content: workflowContent,
      rewritten: false,
      reason: 'missing-job-key',
    );
  }
  final hasMatrix = matrix != null && matrix.isNotEmpty;
  if (needs.isEmpty && !hasMatrix) {
    return RuntimeWorkflowRewriteResult(
      content: workflowContent,
      rewritten: false,
      reason: 'no-needs-and-no-matrix',
    );
  }

  try {
    final doc = loadYaml(workflowContent);
    if (doc is! YamlMap) {
      return RuntimeWorkflowRewriteResult(
        content: workflowContent,
        rewritten: false,
        reason: 'parse-error',
      );
    }

    final jobs = doc['jobs'];
    if (jobs is! YamlMap) {
      return RuntimeWorkflowRewriteResult(
        content: workflowContent,
        rewritten: false,
        reason: 'jobs-not-map',
      );
    }

    final job = jobs[jobKey];
    if (job is! YamlMap) {
      return RuntimeWorkflowRewriteResult(
        content: workflowContent,
        rewritten: false,
        reason: 'job-not-found',
      );
    }

    final editor = YamlEditor(workflowContent);
    var rewritten = false;

    if (hasMatrix) {
      final strategy = job['strategy'];
      if (strategy is YamlMap) {
        editor.update(
          ['jobs', jobKey, 'strategy', 'matrix'],
          {
            'include': [matrix],
          },
        );
      } else {
        editor.update(
          ['jobs', jobKey, 'strategy'],
          {
            'matrix': {
              'include': [matrix],
            },
          },
        );
      }
      rewritten = true;
    }

    if (needs.isNotEmpty) {
      if (job.containsKey('needs')) {
        editor.remove(['jobs', jobKey, 'needs']);
        rewritten = true;
      }
    }

    return RuntimeWorkflowRewriteResult(
      content: editor.toString(),
      rewritten: rewritten,
    );
  } catch (e) {
    return RuntimeWorkflowRewriteResult(
      content: workflowContent,
      rewritten: false,
      reason: 'exception: $e',
    );
  }
}

Future<bool> processJob(
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

  // Clean up orphaned VMs and zombie processes from previous runs to free memory/locks
  try {
    await cleanupOrphanedVms(workerId);
  } catch (e) {
    await logWarning(
      buildJobId,
      runId,
      'Failed to run VM cleanup before job: $e',
    );
  }

  await logInfo(
    buildJobId,
    runId,
    'Processing job: $buildJobId for ${buildJob.owner}/${buildJob.repo} [v$version]',
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

  final vmName = currentVmName(workerId: workerId, buildJobId: buildJobId);
  VirtualMachine? vm;

  Future<void> execCommand(String command) => execVmCommand(
    vmName: vmName,
    command: command,
    buildJobId: buildJobId,
    runId: runId,
    token: token,
    ipAddress: vm?.ipAddress,
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

    await cloneVm(
      baseVmName: baseVmName,
      vmName: vmName,
      buildJobId: buildJobId,
      runId: runId,
      workerId: workerId,
    );

    await logInfo(buildJobId, runId, 'Booting macOS VM via avf_dart...');
    vm = await runVm(vmName);
    await logInfo(buildJobId, runId, 'VM booted successfully!');

    await setupDirectSsh(vm);
    final vmIp = vm.ipAddress;
    await logInfo(buildJobId, runId, 'VM IP: $vmIp. VM is ready!');

    await logInfo(buildJobId, runId, 'Cloning repository $owner/$repo...');
    final githubHost = buildJob.githubBaseUrl != null
        ? Uri.parse(buildJob.githubBaseUrl!).host
        : 'github.com';
    final cloneUrl =
        'https://x-access-token:$token@$githubHost/$owner/$repo.git';

    await execCommand('git clone --depth 1 --no-checkout $cloneUrl');

    final pullRequestNumber = buildJob.pullRequestNumber;

    await logInfo(buildJobId, runId, 'Fetching commit $commitSha...');
    try {
      await execCommand('git -C $repo fetch --depth 1 origin $commitSha');
    } catch (_) {
      if (pullRequestNumber != null) {
        await logInfo(
          buildJobId,
          runId,
          'Direct fetch failed, trying PR ref pull/$pullRequestNumber/head...',
        );
        await execCommand(
          'git -C $repo fetch --depth 1 origin pull/$pullRequestNumber/head',
        );
      } else {
        rethrow;
      }
    }

    await logInfo(buildJobId, runId, 'Checking out commit $commitSha...');
    await execCommand('git -C $repo checkout $commitSha');
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

    final envFileContent = envFileLines.join('\n');
    final secretFileContent = secretFileLines.join('\n');

    await writeFileToVm(vmIp, '/tmp/openci-env', envFileContent);
    await writeFileToVm(vmIp, '/tmp/openci-secrets', secretFileContent);
    await writeFileToVm(
      vmIp,
      '/tmp/openci-event.json',
      buildEventPayload(buildJob),
    );
    await logInfo(buildJobId, runId, 'Environment variables written');

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

    // Use the VM's real home. Each build runs in its own fresh VM, so a unique
    // per-run HOME is unnecessary for isolation. Critically, macOS 26 (Tahoe)
    // will NOT treat a code-signing keychain stored outside the user's real
    // home (e.g. under /tmp) as a valid signing identity, so build keychains
    // must live under /Users/admin/Library/Keychains for `find-identity -v`.
    final actScript = [
      'set -e',
      'export HOME=/Users/admin',
      'export PATH="/Users/admin/flutter/bin:/opt/homebrew/bin:\$PATH"',
      'cd $repo',
      'act $eventType -W .openci/$workflowFileName '
          '$jobFlag'
          '$matrixFlag'
          '-P macos-latest=-self-hosted '
          '-P macos-14=-self-hosted '
          '-P macos-15=-self-hosted '
          '-P ubuntu-latest=-self-hosted '
          '-e /tmp/openci-event.json '
          '--env-file /tmp/openci-env '
          '--secret-file /tmp/openci-secrets',
    ].join('\n');

    await writeFileToVm(vmIp, '/tmp/openci-act.sh', actScript);
    await execCommand('chmod +x /tmp/openci-act.sh');

    try {
      await execCommandStreaming(
        ['/bin/zsh', '-l', '/tmp/openci-act.sh'],
        vmIp,
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
    await stopVm(vm);
    await deleteVm(vmName);
    await pruneStaleVms(buildJobId, runId, workerId: workerId);
  }

  return true;
}

Future<Map<String, String>> buildEnvVars({
  required ApiClient apiClient,
  required BuildJob buildJob,
  required String projectId,
  required String buildJobId,
  required String runId,
}) async {
  final tagName = buildJob.tagName;
  final tagVersion = tagName != null && tagName.isNotEmpty
      ? (tagName.startsWith('v') || tagName.startsWith('V')
            ? tagName.substring(1)
            : tagName)
      : null;

  final teamId = buildJob.teamId;

  final envVars = <String, String>{
    'LANG': 'en_US.UTF-8',
    'OPENCI_PROJECT_ID': projectId,
    'OPENCI_BUILD_JOB_ID': buildJobId,
    if (apiClient.serverUrl != null) 'OPENCI_SERVER_URL': apiClient.serverUrl!,
    if (tagName != null && tagName.isNotEmpty) 'OPENCI_TAG': tagName,
    'OPENCI_TAG_VERSION': tagVersion ?? '',
    'OPENCI_TEAM_ID': teamId ?? '',
    'OPENCI_ID_TOKEN': await apiClient.authManager.getIdToken(
      forceRefresh: true,
    ),
  };

  if (teamId != null) {
    final variables = await apiClient.getEnvironmentVariables(teamId);

    for (final envVarData in variables) {
      final key = envVarData['key'] as String;
      var value = envVarData['value'] as String;
      final autoIncrement = envVarData['autoIncrement'] as bool? ?? false;

      if (autoIncrement) {
        final numValue = int.tryParse(value);
        if (numValue != null) {
          final nextVal = '${numValue + 1}';
          await apiClient.updateEnvironmentVariable(
            envVarData['id'] as String,
            nextVal,
          );
          await logInfo(
            buildJobId,
            runId,
            'Auto-incremented $key: $value → $nextVal',
          );
          value = nextVal;
        }
      }

      envVars[key] = value;
    }

    if (variables.isNotEmpty) {
      await logInfo(
        buildJobId,
        runId,
        'Loaded ${variables.length} environment variable(s)',
      );
    }
  }

  if (tagName != null && tagName.isNotEmpty) {
    await logInfo(
      buildJobId,
      runId,
      'Tag: $tagName (available as \$OPENCI_TAG)',
    );
  }

  return envVars;
}

String buildEventPayload(BuildJob buildJob) {
  final owner = buildJob.owner;
  final repo = buildJob.repo;
  final fullName = '$owner/$repo';
  final commitSha = buildJob.commitSha ?? '';
  final branch = buildJob.branch ?? '';
  final pullRequestNumber = buildJob.pullRequestNumber;

  final repository = <String, dynamic>{
    'name': repo,
    'full_name': fullName,
    'owner': {'login': owner, 'name': owner},
    'default_branch': branch,
  };

  if (pullRequestNumber != null) {
    return jsonEncode({
      'action': 'opened',
      'number': pullRequestNumber,
      'pull_request': {
        'number': pullRequestNumber,
        'head': {
          'ref': branch,
          'sha': commitSha,
          'repo': {'full_name': fullName, 'name': repo},
        },
        'base': {
          'ref': '',
          'sha': '',
          'repo': {'full_name': fullName, 'name': repo},
        },
      },
      'repository': repository,
      'sender': {'login': owner},
    });
  }

  return jsonEncode({
    'ref': branch.isEmpty ? '' : 'refs/heads/$branch',
    'before': '',
    'after': commitSha,
    'head_commit': {'id': commitSha},
    'repository': repository,
    'pusher': {'name': owner},
    'sender': {'login': owner},
  });
}
