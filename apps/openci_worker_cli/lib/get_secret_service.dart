import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import 'build_job_logger.dart';
import 'cloud_function_caller.dart';

Future<Map<String, String>> buildSecretVars({
  required String token,
  required String buildJobId,
  required String runId,
  required BuildJob buildJob,
  required ApiClient apiClient,
}) async {
  final secrets = <String, String>{'GITHUB_TOKEN': token};

  final teamId = buildJob.teamId;
  if (teamId == null) return secrets;

  final secretMetadataList = await apiClient.getSecrets(teamId);
  if (secretMetadataList.isEmpty) return secrets;

  final workflowFileName = buildJob.workflowFileName;
  if (workflowFileName == null || workflowFileName.isEmpty) {
    throw ArgumentError('workflowFileName is required to resolve secrets.');
  }

  Set<String>? usedSecretNames;
  try {
    await logInfo(
      buildJobId,
      runId,
      'Fetching workflow $workflowFileName from GitHub to analyze referenced secrets...',
    );
    final workflowContent = await fetchWorkflowContent(
      owner: buildJob.owner,
      repo: buildJob.repo,
      workflowFileName: workflowFileName,
      token: token,
      githubApiBaseUrl: buildJob.githubBaseUrl,
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
    'Loading ${targetSecrets.length} secret(s) from OpenCI Server...',
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
      await logWarning(buildJobId, runId, 'Failed to load secret "$name": $e');
    }
  }

  await logInfo(buildJobId, runId, 'Loaded ${targetSecrets.length} secret(s)');

  return secrets;
}

Set<String> extractSecretNames(String content) {
  final secretNames = <String>{};
  final regex = RegExp(
    r'secrets(?:\.([a-zA-Z0-9_-]+)|\[\s*(?:"([^"]+)"|'
    "'"
    '([^'
    "'"
    ']+)'
    "'"
    ')s*])',
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
  final query = ref != null && ref.isNotEmpty
      ? '?ref=${Uri.encodeComponent(ref)}'
      : '';
  final url =
      '$apiBase/repos/$owner/$repo/contents/.openci/$workflowFileName$query';

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
    throw HttpException(
      'Failed to fetch workflow content: ${response.statusCode} ${response.body}',
    );
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
