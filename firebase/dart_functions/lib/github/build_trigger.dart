import 'package:dio/dio.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/firestore_paths.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

import '../firebase.dart';
import '../util/github_urls.dart';
import '../util/logger.dart';
import 'dashboard_url.dart';
import 'graphql_queries.dart';
import 'installation_token.dart';
import 'webhook_event.dart';
import 'workflow_parser.dart';

const _uuid = Uuid();

Future<void> handleBuildTrigger(WebhookEvent event) async {
  final installationId = event.installation?.id;
  if (installationId == null) {
    throw ArgumentError('No installation ID in webhook event');
  }

  final triggerInfo = _extractTriggerInfo(event);
  if (triggerInfo == null) {
    logInfo('Unable to determine trigger info, skipping');
    return;
  }

  // Resolve team to get API base URL for GHE support
  final teamId = await _findTeamIdForInstallation(installationId);
  final apiBaseUrl = await getGitHubApiBaseUrl(teamId);
  final githubBaseUrl = await getGitHubBaseUrl(teamId);

  final (:token, :expiresAt) = await getInstallationToken(
    installationId,
    apiBaseUrl: apiBaseUrl,
  );
  final dio = createGitHubDio(token, apiBaseUrl: apiBaseUrl);

  try {
    final result = await _createBuildJobs(
      event: event,
      triggerInfo: triggerInfo,
      installationId: installationId,
      installationToken: token,
      tokenExpiresAt: expiresAt,
      dio: dio,
      teamId: teamId,
      apiBaseUrl: apiBaseUrl,
      githubBaseUrl: githubBaseUrl,
    );

    if (result.createdJobs == 0) {
      logInfo('No workflows matched', {
        'repo': event.repository?.fullName,
        'triggerType': triggerInfo.triggerType,
      });
    } else {
      logInfo('Created ${result.createdJobs} build jobs', {
        'repo': event.repository?.fullName,
        'errors': result.errors,
      });
    }
  } finally {
    dio.close();
  }
}

class _TriggerInfo {
  final String triggerType;
  final String? branch;
  final String? triggerBranch;
  final String? tagName;
  final String? releaseName;

  _TriggerInfo({
    required this.triggerType,
    this.branch,
    this.triggerBranch,
    this.tagName,
    this.releaseName,
  });
}

_TriggerInfo? _extractTriggerInfo(WebhookEvent event) {
  switch (event.event) {
    case GitHubEventType.pullRequest:
      final pr = event.pullRequest;
      if (pr == null) return null;
      return _TriggerInfo(
        triggerType: 'pullRequest',
        branch: pr.headRef,
        triggerBranch: pr.baseRef,
      );

    case GitHubEventType.push:
      final ref = event.ref ?? '';
      final branch = ref.replaceFirst('refs/heads/', '');
      return _TriggerInfo(
        triggerType: 'push',
        branch: branch,
        triggerBranch: branch,
      );

    case GitHubEventType.create:
      if (event.refType != 'tag') return null;
      return _TriggerInfo(triggerType: 'tag', tagName: event.ref);

    case GitHubEventType.release:
      return _TriggerInfo(
        triggerType: 'release',
        tagName: event.release?.tagName,
        releaseName: event.raw['release']?['name'] as String?,
      );

    default:
      return null;
  }
}

Future<String?> _resolveCommitSha({
  required WebhookEvent event,
  required _TriggerInfo triggerInfo,
  required Dio dio,
}) async {
  // PR: use head SHA
  if (event.event == GitHubEventType.pullRequest) {
    return event.pullRequest?.headSha;
  }

  // Push: use head_commit.id or after
  if (event.event == GitHubEventType.push) {
    return (event.raw['head_commit']?['id'] as String?) ??
        (event.raw['after'] as String?);
  }

  // Tag / Release: resolve via API
  final tagName = triggerInfo.tagName;
  final repo = event.repository;
  if (tagName != null && repo != null) {
    try {
      final response = await dio.get(
        '/repos/${repo.fullName}/commits/$tagName',
      );
      return response.data['sha'] as String?;
    } catch (e) {
      logError('Failed to resolve commit SHA for tag', {'tag': tagName}, e);
    }
  }

  return null;
}

Future<List<OpenciDirEntry>> _fetchOpenciDir({
  required Dio dio,
  required String owner,
  required String repo,
  required String expression,
  required String apiBaseUrl,
}) async {
  try {
    final response = await dio.post(
      graphqlEndpoint(apiBaseUrl),
      data: {
        'query': openciDirQuery,
        'variables': {'owner': owner, 'repo': repo, 'expression': expression},
      },
    );

    final entries =
        (response.data['data']?['repository']?['object']?['entries']
            as List<dynamic>?) ??
        [];

    return entries
        .map((e) => OpenciDirEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    final message = e.toString();
    if (!message.contains('Could not resolve to an object')) {
      logError('Failed to list .openci/ directory', {}, e);
    }
    return [];
  }
}

Future<String?> _findTeamIdForInstallation(int installationId) async {
  try {
    final snapshot = await firestore
        .collection(teamsCollection)
        .where('installationIds', WhereFilter.arrayContains, installationId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
  } catch (e) {
    logError('Failed to find team for installation', {}, e);
    return null;
  }
}

class _BuildJobsResult {
  final int createdJobs;
  final int errors;

  _BuildJobsResult({required this.createdJobs, required this.errors});
}

Future<_BuildJobsResult> _createBuildJobs({
  required WebhookEvent event,
  required _TriggerInfo triggerInfo,
  required int installationId,
  required String installationToken,
  required String tokenExpiresAt,
  required Dio dio,
  required String? teamId,
  required String apiBaseUrl,
  required String githubBaseUrl,
}) async {
  final repo = event.repository;
  if (repo == null) return _BuildJobsResult(createdJobs: 0, errors: 0);

  final owner = repo.owner;
  final repoName = repo.name;

  final commitSha = await _resolveCommitSha(
    event: event,
    triggerInfo: triggerInfo,
    dio: dio,
  );

  // Determine the Git ref for the GraphQL query
  final queryRef =
      commitSha ??
      (triggerInfo.triggerBranch != null
          ? 'heads/${triggerInfo.triggerBranch}'
          : null);

  if (queryRef == null) {
    logInfo('No ref to query .openci/ directory');
    return _BuildJobsResult(createdJobs: 0, errors: 0);
  }

  // Fetch .openci/ YAML files via GraphQL
  final entries = await _fetchOpenciDir(
    dio: dio,
    owner: owner,
    repo: repoName,
    expression: '$queryRef:.openci',
    apiBaseUrl: apiBaseUrl,
  );

  final yamlEntries = entries.where(
    (e) =>
        e.type == 'blob' &&
        (e.name.endsWith('.yaml') || e.name.endsWith('.yml')) &&
        e.text != null,
  );

  var createdJobCount = 0;
  var errorCount = 0;
  final pullRequestNumber = event.pullRequest?.number;

  for (final entry in yamlEntries) {
    try {
      final parsed = _parseYaml(entry.text!);
      if (parsed == null) continue;

      final workflowName =
          parsed['name'] as String? ??
          entry.name.replaceAll(RegExp(r'\.(yaml|yml)$'), '');

      if (!matchesTrigger(
        parsed,
        triggerInfo.triggerType,
        triggerInfo.triggerBranch,
      )) {
        logInfo('Workflow ${entry.name} does not match trigger', {
          'triggerType': triggerInfo.triggerType,
          'triggerBranch': triggerInfo.triggerBranch,
        });
        continue;
      }

      final jobInfos = extractJobs(parsed);
      if (jobInfos.isEmpty) {
        logInfo('Workflow ${entry.name} has no jobs, skipping');
        continue;
      }

      // teamId is already resolved at the top of handleBuildTrigger

      // Check if workflow is disabled in Firestore
      if (teamId != null) {
        final wfBranch = triggerInfo.triggerBranch ?? 'HEAD';
        final docId = workflowFileDocId(
          teamId,
          repo.fullName,
          wfBranch,
          entry.name,
        );
        final wfDoc = await firestore
            .collection(workflowFilesCollection)
            .doc(docId)
            .get();
        if (wfDoc.exists && wfDoc.data()?['enabled'] == false) {
          logInfo('Workflow ${entry.name} is disabled, skipping');
          continue;
        }
      }

      final totalSteps = jobInfos.fold<int>(
        0,
        (acc, j) => acc + j.steps.length,
      );
      logInfo('Matched .openci/${entry.name}', {
        'jobs': jobInfos.length,
        'steps': totalSteps,
      });

      final workflowRunId = _uuid.v4();

      // First pass: assign document IDs
      final jobDocIds = <String, String>{};
      for (final jobInfo in jobInfos) {
        jobDocIds[jobInfo.jobKey] = _uuid.v4();
      }

      // Second pass: create build_jobs documents
      for (final jobInfo in jobInfos) {
        final documentId = jobDocIds[jobInfo.jobKey]!;
        final hasNeeds = jobInfo.needs.isNotEmpty;

        // Build resolvedNeeds mapping
        Map<String, String>? resolvedNeeds;
        if (hasNeeds) {
          resolvedNeeds = {};
          for (final needKey in jobInfo.needs) {
            final needId = jobDocIds[needKey];
            if (needId != null) {
              resolvedNeeds[needKey] = needId;
            } else {
              logWarning(
                'Job "${jobInfo.jobKey}" needs "$needKey" which does not exist',
              );
            }
          }
        }

        // Create GitHub Check Run
        int? checkRunId;
        if (commitSha != null) {
          checkRunId = await _createCheckRun(
            dio: dio,
            owner: owner,
            repo: repoName,
            name: jobInfos.length > 1
                ? '$workflowName / ${jobInfo.jobKey}'
                : workflowName,
            headSha: commitSha,
            detailsUrl: buildDashboardRunUrl(documentId),
          );
        }

        final now = DateTime.now().toUtc().toIso8601String();

        await firestore.collection(buildJobsCollection).doc(documentId).set({
          'event': event.event.value,
          'action': event.action?.value,
          'repository': repo.fullName,
          'sender': event.sender?.login,
          'updatedAt': now,
          'createdAt': now,
          'status': hasNeeds ? 'waiting' : 'queued',
          'id': documentId,
          'jobKey': jobInfo.jobKey,
          'workflowRunId': workflowRunId,
          'needs': jobInfo.needs.isNotEmpty ? jobInfo.needs : null,
          'resolvedNeeds': hasNeeds ? resolvedNeeds : null,
          'teamId': teamId,
          'workflowFileName': entry.name,
          'workflowName': workflowName,
          'installationId': installationId,
          'commitSha': commitSha,
          'pullRequestNumber': pullRequestNumber,
          'owner': owner,
          'repo': repoName,
          'installationToken': installationToken,
          'tokenExpiresAt': tokenExpiresAt,
          'checkRunId': checkRunId,
          'runsOn': jobInfo.runsOn,
          'runCount': 0,
          'latestRunId': null,
          'tagName': triggerInfo.tagName,
          'branch': triggerInfo.branch,
          'releaseName': triggerInfo.releaseName,
          'githubApiBaseUrl': apiBaseUrl != defaultGitHubApiBaseUrl
              ? apiBaseUrl
              : null,
          'githubBaseUrl': githubBaseUrl != defaultGitHubBaseUrl
              ? githubBaseUrl
              : null,
        });

        createdJobCount++;
      }
    } catch (e) {
      logError('Failed to process .openci/${entry.name}', {}, e);
      errorCount++;
    }
  }

  return _BuildJobsResult(createdJobs: createdJobCount, errors: errorCount);
}

// ---------------------------------------------------------------------------
// Create GitHub Check Run
// ---------------------------------------------------------------------------

Future<int?> _createCheckRun({
  required Dio dio,
  required String owner,
  required String repo,
  required String name,
  required String headSha,
  required String detailsUrl,
}) async {
  try {
    final response = await dio.post(
      '/repos/$owner/$repo/check-runs',
      data: {
        'name': name,
        'head_sha': headSha,
        'status': 'queued',
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'details_url': detailsUrl,
      },
    );
    return response.data['id'] as int?;
  } catch (e) {
    logError('Failed to create check run', {'name': name}, e);
    return null;
  }
}

// ---------------------------------------------------------------------------
// YAML parsing helper
// ---------------------------------------------------------------------------

Map<String, dynamic>? _parseYaml(String content) {
  try {
    final result = loadYaml(content);
    if (result is! YamlMap) return null;
    return _yamlToMap(result);
  } catch (e) {
    logError('Failed to parse YAML', {}, e);
    return null;
  }
}

/// Convert YamlMap/YamlList to plain Dart Map/List.
Map<String, dynamic> _yamlToMap(YamlMap yaml) {
  final map = <String, dynamic>{};
  for (final entry in yaml.entries) {
    map[entry.key.toString()] = _convertYamlValue(entry.value);
  }
  return map;
}

dynamic _convertYamlValue(dynamic value) {
  if (value is YamlMap) return _yamlToMap(value);
  if (value is YamlList) return value.map(_convertYamlValue).toList();
  return value;
}
