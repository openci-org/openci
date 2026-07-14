import 'dart:async';
import 'dart:convert';

import 'package:openci_shared/openci_shared.dart';
import 'package:openci_worker_cli/build_job_logger.dart';
import 'package:openci_worker_cli/cloud_function_caller.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

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
    'OPENCI_SERVER_URL': apiClient.serverUrl,
    if (tagName != null && tagName.isNotEmpty) 'OPENCI_TAG': tagName,
    'OPENCI_TAG_VERSION': tagVersion ?? '',
    'OPENCI_TEAM_ID': teamId ?? '',
    'OPENCI_ID_TOKEN': await apiClient.authManager.getIdToken(
      forceRefresh: true,
    ),
  };

  if (teamId != null) {
    try {
      final secretMetadataList = await apiClient.getSecrets(teamId);

      final hasBuildNumber = secretMetadataList.any(
        (meta) => meta['name'] == 'OPENCI_BUILD_NUMBER',
      );
      if (hasBuildNumber) {
        try {
          final value = await apiClient.getSecretValue(
            teamId,
            'OPENCI_BUILD_NUMBER',
          );
          if (value.isNotEmpty) {
            final numValue = int.tryParse(value);
            if (numValue != null) {
              final nextVal = '${numValue + 1}';
              await apiClient.saveSecret(
                teamId: teamId,
                name: 'OPENCI_BUILD_NUMBER',
                value: nextVal,
              );
              await logInfo(
                buildJobId,
                runId,
                'Auto-incremented OPENCI_BUILD_NUMBER: $value → $nextVal',
              );
              envVars['OPENCI_BUILD_NUMBER'] = nextVal;
            } else {
              envVars['OPENCI_BUILD_NUMBER'] = value;
            }
          }
        } catch (e) {
          await logWarning(
            buildJobId,
            runId,
            'Failed to load or auto-increment OPENCI_BUILD_NUMBER: $e',
          );
        }
      }

      final hasRunNumber = secretMetadataList.any(
        (meta) => meta['name'] == 'OPENCI_RUN_NUMBER',
      );
      try {
        if (hasRunNumber) {
          final value = await apiClient.getSecretValue(
            teamId,
            'OPENCI_RUN_NUMBER',
          );
          final numValue = int.tryParse(value) ?? 0;
          final nextVal = '${numValue + 1}';
          await apiClient.saveSecret(
            teamId: teamId,
            name: 'OPENCI_RUN_NUMBER',
            value: nextVal,
          );
          await logInfo(
            buildJobId,
            runId,
            'Auto-incremented OPENCI_RUN_NUMBER: $value → $nextVal',
          );
          envVars['OPENCI_RUN_NUMBER'] = nextVal;
        } else {
          await apiClient.saveSecret(
            teamId: teamId,
            name: 'OPENCI_RUN_NUMBER',
            value: '1',
          );
          await logInfo(
            buildJobId,
            runId,
            'Initialized OPENCI_RUN_NUMBER to 1 in Secrets',
          );
          envVars['OPENCI_RUN_NUMBER'] = '1';
        }
      } catch (e) {
        await logWarning(
          buildJobId,
          runId,
          'Failed to load or auto-increment OPENCI_RUN_NUMBER: $e',
        );
      }
    } catch (e) {
      await logWarning(
        buildJobId,
        runId,
        'Failed to fetch secrets list for team $teamId: $e',
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

Future<void> updateJobFinalStatus({
  required ApiClient apiClient,
  required BuildJob buildJob,
  required String runId,
  required BuildJobStatus status,
  required String conclusion,
}) async {
  final buildJobId = buildJob.id;
  await apiClient.updateRunStatus(
    buildJobId: buildJobId,
    runId: runId,
    status: 'completed',
    conclusion: conclusion,
  );
  await apiClient.completeJob(buildJobId, status.name);

  final updatedJob = buildJob.copyWith(
    status: status,
    latestRunId: runId,
    completedAt: DateTime.now(),
  );
  await apiClient.updateCheckRun(
    updatedJob,
    'completed',
    conclusion: conclusion,
  );
  await apiClient.handleBuildJobStatusChange(updatedJob, status.name);
}
