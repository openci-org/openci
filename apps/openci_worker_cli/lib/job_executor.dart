import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_worker_cli/cloud_function_caller.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:openci_worker_cli/logger.dart';
import 'package:openci_worker_cli/vm.dart';
import 'package:avf_dart/avf_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

const _uuid = Uuid();

class RuntimeWorkflowRewriteResult {
  final String content;
  final bool rewritten;
  final String? reason;
  RuntimeWorkflowRewriteResult({required this.content, required this.rewritten, this.reason});
}

RuntimeWorkflowRewriteResult rewriteWorkflowForSingleOpenCiJob(
  String workflowContent,
  String? jobKey,
  List<String> needs,
  Map<String, dynamic>? matrix,
) {
  if (jobKey == null || jobKey.isEmpty) {
    return RuntimeWorkflowRewriteResult(content: workflowContent, rewritten: false, reason: 'missing-job-key');
  }
  final hasMatrix = matrix != null && matrix.isNotEmpty;
  if (needs.isEmpty && !hasMatrix) {
    return RuntimeWorkflowRewriteResult(content: workflowContent, rewritten: false, reason: 'no-needs-and-no-matrix');
  }

  try {
    final doc = loadYaml(workflowContent);
    if (doc is! YamlMap) {
      return RuntimeWorkflowRewriteResult(content: workflowContent, rewritten: false, reason: 'parse-error');
    }
    
    final jobs = doc['jobs'];
    if (jobs is! YamlMap) {
      return RuntimeWorkflowRewriteResult(content: workflowContent, rewritten: false, reason: 'jobs-not-map');
    }
    
    final job = jobs[jobKey];
    if (job is! YamlMap) {
      return RuntimeWorkflowRewriteResult(content: workflowContent, rewritten: false, reason: 'job-not-found');
    }

    final editor = YamlEditor(workflowContent);
    var rewritten = false;

    if (hasMatrix) {
      final strategy = job['strategy'];
      if (strategy is YamlMap) {
        editor.update(['jobs', jobKey, 'strategy', 'matrix'], {'include': [matrix]});
      } else {
        editor.update(['jobs', jobKey, 'strategy'], {
          'matrix': {
            'include': [matrix]
          }
        });
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

Future<String> fetchWorkflowContent({
  required String owner,
  required String repo,
  required String workflowFileName,
  required String token,
  String? githubApiBaseUrl,
  String? commitSha,
  String? branch,
}) async {
  final apiBase = githubApiBaseUrl != null && githubApiBaseUrl.isNotEmpty
      ? githubApiBaseUrl.replaceAll(RegExp(r'/+$'), '')
      : 'https://api.github.com';
      
  final ref = commitSha ?? branch;
  final query = ref != null && ref.isNotEmpty ? '?ref=${Uri.encodeComponent(ref)}' : '';
  final url = '$apiBase/repos/$owner/$repo/contents/.openci/$workflowFileName$query';

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'OpenCI-Worker',
    },
  );

  if (response.statusCode != 200) {
    throw HttpException('Failed to fetch workflow content: ${response.statusCode} ${response.body}');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final content = data['content'] as String?;
  if (content == null) {
    throw StateError('No content in GitHub response');
  }

  final encoding = data['encoding'] as String? ?? 'base64';
  if (encoding == 'base64') {
    final cleaned = content.replaceAll(RegExp(r'\s+'), '');
    return utf8.decode(base64.decode(cleaned));
  }

  return content;
}

Set<String> extractSecretNames(String content) {
  final secretNames = <String>{};
  final regex = RegExp(
    r'secrets(?:\.([a-zA-Z0-9_-]+)|\[\s*(?:"([^"]+)"|' "'" '([^' "'" ']+)' "'" ')\s*\])',
    caseSensitive: false,
  );
  
  for (final match in regex.allMatches(content)) {
    final name = match.group(1) ?? match.group(2) ?? match.group(3);
    if (name != null && name.isNotEmpty) {
      secretNames.add(name);
    }
  }
  return secretNames;
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
    await logError(buildJobId, runId, 'Failed to resolve GitHub App Installation Token: $e');
    await apiClient.updateRunStatus(
      buildJobId: buildJobId,
      runId: runId,
      status: 'completed',
      conclusion: 'failure',
    );
    await apiClient.completeJob(buildJobId, 'FAILURE');
    await apiClient.updateCheckRun(buildJob, 'completed', conclusion: 'failure');
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
    final cloneUrl = 'https://x-access-token:$token@$githubHost/$owner/$repo.git';

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

    final actScript = [
      'set -e',
      'export PATH="/Users/admin/flutter/bin:/opt/homebrew/bin:\$PATH"',
      'cd $repo',
      'act $eventType -W .openci/$workflowFileName '
          '$jobFlag'
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
    await apiClient.updateCheckRun(completedJob, 'completed', conclusion: 'success');
    await apiClient.handleBuildJobStatusChange(completedJob, 'SUCCESS');
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
    await apiClient.updateCheckRun(failedJob, 'completed', conclusion: 'failure');
    await apiClient.handleBuildJobStatusChange(failedJob, 'FAILURE');
    rethrow;
  } finally {
    await flushRemainingLogs();
    await stopVm(vm);
    await deleteVm(vmName);
    await flushRemainingLogs();
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
    if (tagName != null && tagName.isNotEmpty) 'OPENCI_TAG': tagName,
    if (tagVersion != null) 'OPENCI_TAG_VERSION': tagVersion,
    if (teamId != null) 'OPENCI_TEAM_ID': teamId,
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
          await apiClient.updateEnvironmentVariable(envVarData['id'] as String, nextVal);
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

Future<Map<String, String>> buildSecretVars({
  required ApiClient apiClient,
  required String token,
  required String buildJobId,
  required String runId,
  required BuildJob buildJob,
}) async {
  final secrets = <String, String>{
    'GITHUB_TOKEN': token,
  };

  final teamId = buildJob.teamId;
  if (teamId == null) return secrets;

  // Retrieve the metadata of all secrets for the team
  final secretMetadataList = await apiClient.getSecrets(teamId);
  if (secretMetadataList.isEmpty) return secrets;

  // Attempt to fetch the workflow file content from GitHub to analyze used secrets
  Set<String>? usedSecretNames;
  if (buildJob.workflowFileName != null) {
    try {
      await logInfo(
        buildJobId,
        runId,
        'Fetching workflow ${buildJob.workflowFileName} from GitHub to analyze referenced secrets...',
      );
      final workflowContent = await fetchWorkflowContent(
        owner: buildJob.owner,
        repo: buildJob.repo,
        workflowFileName: buildJob.workflowFileName!,
        token: token,
        githubApiBaseUrl: buildJob.githubApiBaseUrl,
        commitSha: buildJob.commitSha,
        branch: buildJob.branch,
      );
      usedSecretNames = extractSecretNames(workflowContent);
      await logInfo(
        buildJobId,
        runId,
        'Referenced secret(s) in workflow: ${usedSecretNames.isEmpty ? "(none)" : usedSecretNames.join(', ')}',
      );
    } catch (e) {
      await logWarning(
        buildJobId,
        runId,
        'Failed to fetch or analyze workflow file; falling back to loading all secrets: $e',
      );
    }
  }

  // Filter list by referenced secret names (or load all if analysis failed)
  final targetSecrets = secretMetadataList.where((meta) {
    if (usedSecretNames == null) return true;
    final name = meta['name'] as String?;
    return name != null && usedSecretNames.contains(name);
  }).toList();

  if (targetSecrets.isEmpty) {
    await logInfo(buildJobId, runId, 'No secrets need to be loaded');
    return secrets;
  }

  await logInfo(
    buildJobId,
    runId,
    'Loading ${targetSecrets.length} secret(s) from Secret Manager via Cloud Functions...',
  );

  for (final meta in targetSecrets) {
    final name = meta['name'] as String?;
    if (name == null) continue;

    try {
      final value = await apiClient.getSecretValue(teamId, name);
      if (value.isNotEmpty) {
        secrets[name] = value;
      }
    } catch (e) {
      await logWarning(
        buildJobId,
        runId,
        'Failed to load secret "$name": $e',
      );
    }
  }

  await logInfo(
    buildJobId,
    runId,
    'Loaded ${targetSecrets.length} secret(s)',
  );

  return secrets;
}
