import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:github/hooks.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/extract_commit_message_from_push_event.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

Future<void> processWebhookTask(
  AppDatabase db,
  DriftWebhookTask task, {
  Map<String, String>? environment,
  http.Client? client,
}) async {
  final env = environment ?? Platform.environment;
  final githubApiBaseUrlStr = env['GITHUB_API_BASE_URL'];
  if (githubApiBaseUrlStr == null || githubApiBaseUrlStr.isEmpty) {
    throw StateError(
      'Background task error: GITHUB_API_BASE_URL environment variable is not configured.',
    );
  }

  http.Client? httpClient;
  var isSelfGeneratedClient = false;
  try {
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(task.payload) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Background task error: Invalid JSON body: $e');
    }

    final eventType = task.eventType;
    final installation = payload['installation'] as Map<String, dynamic>?;
    if (installation == null || installation['id'] == null) {
      throw StateError('Background task error: Missing installation ID');
    }
    final installationId = installation['id'] as int;

    final team = await db.teamDao.getTeamByInstallationId(installationId);
    if (team == null) {
      throw StateError(
        'Background task warning: No team found for installationId $installationId',
      );
    }

    final appId = env['GITHUB_APP_ID'];
    final privateKeyPath = env['GITHUB_PRIVATE_KEY_PATH'];
    if (appId == null ||
        appId.isEmpty ||
        privateKeyPath == null ||
        privateKeyPath.isEmpty) {
      throw StateError(
        'Background task error: GITHUB_APP_ID or GITHUB_PRIVATE_KEY_PATH is not configured.',
      );
    }

    final privateKeyFile = File(privateKeyPath);
    if (!privateKeyFile.existsSync()) {
      throw StateError(
        'Background task error: GITHUB_PRIVATE_KEY_PATH file does not exist: $privateKeyPath',
      );
    }
    final privateKeyPem = privateKeyFile.readAsStringSync();

    final jwtToken = generateGitHubAppJwt(appId, privateKeyPem);

    final githubApiBaseUrl = githubApiBaseUrlStr;
    final githubBaseUrl = team.githubBaseUrl ?? 'https://github.com';

    if (client != null) {
      httpClient = client;
      isSelfGeneratedClient = false;
    } else {
      httpClient = http.Client();
      isSelfGeneratedClient = true;
    }

    final tokenUrl =
        '$githubApiBaseUrl/app/installations/$installationId/access_tokens';
    final http.Response tokenResponse;
    try {
      tokenResponse = await httpClient
          .post(
            Uri.parse(tokenUrl),
            headers: {
              'Authorization': 'Bearer $jwtToken',
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
              'User-Agent': 'OpenCI-Server',
            },
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw HttpException(
        'Background task error: Access token request timed out or failed: $e',
      );
    }

    if (tokenResponse.statusCode >= 300) {
      throw HttpException(
        'Background task error: Failed to retrieve installation token: ${tokenResponse.statusCode} ${tokenResponse.body}',
      );
    }

    final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final installationToken = tokenData['token'] as String;

    final String owner;
    final String repo;
    final String commitSha;
    final String branch;
    final String? triggerBranch;
    final int? pullRequestNumber;
    final String triggerType;
    final String? commitMessage;

    if (eventType == 'pull_request') {
      final event = PullRequestEvent.fromJson(payload);
      final pr = event.pullRequest;
      final repoMap = event.repository;
      if (pr == null || repoMap == null) {
        throw StateError(
          'Background task error: Missing pull_request or repository data',
        );
      }
      owner = repoMap.owner?.login ?? '';
      repo = repoMap.name;
      commitSha = pr.head?.sha ?? '';
      branch = pr.head?.ref ?? '';
      triggerBranch = pr.base?.ref;
      pullRequestNumber = event.number;
      triggerType = 'pull_request';
      commitMessage = pr.title;
    } else {
      // push event
      if (payload['deleted'] == true) {
        return;
      }
      final repoMap = payload['repository'] as Map<String, dynamic>;
      owner = repoMap['owner']['login'] as String;
      repo = repoMap['name'] as String;
      commitSha = (payload['head_commit']?['id'] ?? payload['after']) as String;
      final ref = payload['ref'] as String;
      if (ref.startsWith('refs/heads/')) {
        branch = ref.substring(11);
      } else {
        branch = ref;
      }
      triggerBranch = branch;
      pullRequestNumber = null;
      triggerType = 'push';

      commitMessage = extractCommitMessageFromPushEvent(payload);
    }

    // Fetch YAML files from .openci directory
    final contentsUrl =
        '$githubApiBaseUrl/repos/$owner/$repo/contents/.openci?ref=$commitSha';
    final http.Response contentsResponse;
    try {
      contentsResponse = await httpClient
          .get(
            Uri.parse(contentsUrl),
            headers: {
              'Authorization': 'token $installationToken',
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'OpenCI-Server',
            },
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw HttpException(
        'Background task error: Fetch contents request timed out or failed: $e',
      );
    }

    if (contentsResponse.statusCode == 404) {
      return;
    }

    if (contentsResponse.statusCode >= 300) {
      throw HttpException(
        'Background task error: Failed to fetch contents: ${contentsResponse.statusCode} ${contentsResponse.body}',
      );
    }

    final contentsList = jsonDecode(contentsResponse.body);
    if (contentsList is! List) {
      throw FormatException(
        'Background task error: .openci is not a directory',
      );
    }

    final yamlFiles = contentsList
        .where(
          (item) =>
              item is Map &&
              item['type'] == 'file' &&
              (item['name'].toString().endsWith('.yaml') ||
                  item['name'].toString().endsWith('.yml')),
        )
        .cast<Map<dynamic, dynamic>>()
        .toList();

    if (yamlFiles.isEmpty) {
      return;
    }

    final fetchedFiles = await fetchWorkflowFiles(
      yamlFiles: yamlFiles,
      githubApiBaseUrl: githubApiBaseUrl,
      owner: owner,
      repo: repo,
      commitSha: commitSha,
      installationToken: installationToken,
      httpClient: httpClient,
    );

    final extractedJobs = parseWorkflowJobs(
      files: fetchedFiles,
      triggerType: triggerType,
      triggerBranch: triggerBranch,
    );

    if (extractedJobs.isEmpty) {
      return;
    }

    // Count jobs per workflow
    final jobCountsByWorkflow = <String, int>{};
    for (final job in extractedJobs) {
      jobCountsByWorkflow[job.workflowName] =
          (jobCountsByWorkflow[job.workflowName] ?? 0) + 1;
    }

    final workflowRunIds = <String, String>{};
    final jobDocumentIdsByWorkflow = <String, Map<String, String>>{};
    final jobInstanceKeysBySourceKeyByWorkflow =
        <String, Map<String, List<String>>>{};

    for (final job in extractedJobs) {
      final wName = job.workflowFileName;
      if (!workflowRunIds.containsKey(wName)) {
        workflowRunIds[wName] = const Uuid().v4();
      }

      final jobDocumentIds = jobDocumentIdsByWorkflow[wName] ??= {};
      jobDocumentIds[job.jobId] = const Uuid().v4();

      final sourceKey = job.workflowJobKey ?? job.jobId;
      final jobInstanceKeysBySourceKey =
          jobInstanceKeysBySourceKeyByWorkflow[wName] ??= {};
      (jobInstanceKeysBySourceKey[sourceKey] ??= []).add(job.jobId);
    }

    for (final job in extractedJobs) {
      final wName = job.workflowFileName;
      final documentId = jobDocumentIdsByWorkflow[wName]![job.jobId]!;
      final workflowRunId = workflowRunIds[wName]!;

      final jobInstanceKeysBySourceKey =
          jobInstanceKeysBySourceKeyByWorkflow[wName]!;

      // Resolve needs and status
      final spec = job.spec;
      final rawNeeds = spec['needs'];
      final List<String> rawNeedKeys;
      if (rawNeeds is List) {
        rawNeedKeys = rawNeeds.map((e) => e.toString()).toList();
      } else if (rawNeeds is String) {
        rawNeedKeys = [rawNeeds];
      } else {
        rawNeedKeys = [];
      }

      final needs = rawNeedKeys
          .flatMap((need) => jobInstanceKeysBySourceKey[need] ?? [need])
          .toList();
      final hasNeeds = needs.isNotEmpty;
      final status = hasNeeds ? BuildJobStatus.WAITING : BuildJobStatus.QUEUED;

      // Create Check Run on GitHub
      final checkRunName = (jobCountsByWorkflow[job.workflowName] ?? 0) > 1
          ? '${job.workflowName} / ${job.workflowJobKey ?? job.jobId}${job.matrixLabel != null ? " (${job.matrixLabel})" : ""}'
          : job.workflowName;

      final checkRunUrl = '$githubApiBaseUrl/repos/$owner/$repo/check-runs';
      final http.Response checkRunResponse;
      try {
        checkRunResponse = await httpClient
            .post(
              Uri.parse(checkRunUrl),
              headers: {
                'Authorization': 'token $installationToken',
                'Accept': 'application/vnd.github+json',
                'X-GitHub-Api-Version': '2022-11-28',
                'User-Agent': 'OpenCI-Server',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'name': checkRunName,
                'head_sha': commitSha,
                'status': 'queued',
                'started_at': DateTime.now().toUtc().toIso8601String(),
                'details_url': 'https://dashboard.openci.org/runs/$documentId',
              }),
            )
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        stderr.writeln(
          'Background task error: Create check run request timed out or failed: $e',
        );
        continue;
      }

      if (checkRunResponse.statusCode >= 300) {
        stderr.writeln(
          'Background task error: Failed to create check run: ${checkRunResponse.statusCode} ${checkRunResponse.body}',
        );
        continue;
      }

      final checkRunData =
          jsonDecode(checkRunResponse.body) as Map<String, dynamic>;
      final checkRunId = checkRunData['id'].toString();

      // Map Matrix to String map
      final matrixMap = job.matrix?.map((k, v) => MapEntry(k, v));

      // Save BuildJob in DB
      final buildJob = BuildJob(
        id: documentId,
        status: status,
        owner: owner,
        repo: repo,
        workflowName: job.workflowName,
        teamId: team.id,
        workflowFileName: job.workflowFileName,
        commitSha: commitSha,
        commitMessage: commitMessage,
        pullRequestNumber: pullRequestNumber,
        runCount: 0,
        tagName: null,
        branch: branch,
        jobKey: job.jobId,
        workflowJobKey: job.workflowJobKey,
        matrix: matrixMap,
        matrixLabel: job.matrixLabel,
        workflowRunId: workflowRunId,
        needs: needs.isEmpty ? null : needs,
        runsOn: job.spec['runs-on']?.toString(),
        githubBaseUrl: githubBaseUrl,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await db.buildJobDao.insertBuildJob(
        buildJob.toDrift(
          installationId: installationId.toString(),
          checkRunId: checkRunId,
        ),
      );
    }
  } finally {
    if (isSelfGeneratedClient && httpClient != null) {
      httpClient.close();
    }
  }
}

String generateGitHubAppJwt(String appId, String privateKeyPem) {
  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final jwt = JWT({
    'iat': nowSeconds - 60,
    'exp': nowSeconds + 540,
    'iss': appId.trim(),
  });
  return jwt.sign(
    RSAPrivateKey(privateKeyPem),
    algorithm: JWTAlgorithm.RS256,
  );
}

class FetchedWorkflowFile {
  final String name;
  final String path;
  final String content;

  FetchedWorkflowFile({
    required this.name,
    required this.path,
    required this.content,
  });
}

Future<List<FetchedWorkflowFile>> fetchWorkflowFiles({
  required List<Map<dynamic, dynamic>> yamlFiles,
  required String githubApiBaseUrl,
  required String owner,
  required String repo,
  required String commitSha,
  required String installationToken,
  required http.Client httpClient,
}) async {
  final fetched = <FetchedWorkflowFile>[];
  for (final file in yamlFiles) {
    final path = file['path'] as String;
    final name = file['name'] as String;

    final fileUrl =
        '$githubApiBaseUrl/repos/$owner/$repo/contents/$path?ref=$commitSha';
    final http.Response fileResponse;
    try {
      fileResponse = await httpClient
          .get(
            Uri.parse(fileUrl),
            headers: {
              'Authorization': 'token $installationToken',
              'Accept': 'application/vnd.github.raw+json',
              'User-Agent': 'OpenCI-Server',
            },
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      stderr.writeln(
        'Warning: Failed to fetch file $path due to timeout or error: $e',
      );
      continue;
    }

    if (fileResponse.statusCode >= 300) {
      stderr.writeln(
        'Warning: Failed to fetch file $path: ${fileResponse.statusCode}',
      );
      continue;
    }

    fetched.add(
      FetchedWorkflowFile(
        name: name,
        path: path,
        content: fileResponse.body,
      ),
    );
  }
  return fetched;
}

List<ExtractedJob> parseWorkflowJobs({
  required List<FetchedWorkflowFile> files,
  required String triggerType,
  required String? triggerBranch,
}) {
  final extractedJobs = <ExtractedJob>[];
  for (final file in files) {
    try {
      final parsed = loadYaml(file.content);
      if (parsed is! Map) {
        stderr.writeln('Warning: YAML at ${file.path} is not an object');
        continue;
      }

      final workflowName = parsed['name'] is String
          ? parsed['name'] as String
          : file.name.replaceAll(RegExp(r'\.(yaml|yml)$'), '');
      if (!matchesTrigger(parsed, triggerType, triggerBranch)) {
        continue;
      }

      final jobs = parsed['jobs'];
      if (jobs is! Map) {
        stderr.writeln(
          'Warning: Workflow ${file.name} does not contain a valid jobs object',
        );
        continue;
      }

      for (final jobEntry in jobs.entries) {
        final jobId = jobEntry.key.toString();
        final spec = jobEntry.value;
        if (spec is! Map) {
          stderr.writeln('Warning: Job $jobId is not an object');
          continue;
        }

        final matrixCells = expandMatrix(spec);
        if (matrixCells != null) {
          for (
            var matrixIndex = 0;
            matrixIndex < matrixCells.length;
            matrixIndex++
          ) {
            final matrix = matrixCells[matrixIndex];
            final expandedJobId = matrixInstanceKey(jobId, matrix);
            final resolvedSpec =
                resolveMatrixExpressions(spec, matrix) as Map<dynamic, dynamic>;

            extractedJobs.add(
              ExtractedJob(
                workflowFileName: file.name,
                workflowName: workflowName,
                jobId: expandedJobId,
                workflowJobKey: jobId,
                spec: resolvedSpec,
                matrix: matrix,
                matrixLabel: matrixLabel(matrix),
                matrixIndex: matrixIndex,
                matrixGroupKey: '${file.name}:$jobId',
                matrixFailFast:
                    (spec['strategy'] as Map?)?['fail-fast'] != false,
              ),
            );
          }
        } else {
          extractedJobs.add(
            ExtractedJob(
              workflowFileName: file.name,
              workflowName: workflowName,
              jobId: jobId,
              workflowJobKey: null,
              spec: spec,
            ),
          );
        }
      }
    } catch (e, s) {
      stderr.writeln('Error parsing YAML at ${file.path}: $e\n$s');
      continue;
    }
  }
  return extractedJobs;
}

class ExtractedJob {
  final String workflowFileName;
  final String workflowName;
  final String jobId;
  final String? workflowJobKey;
  final Map<dynamic, dynamic> spec;
  final MatrixCell? matrix;
  final String? matrixLabel;
  final int? matrixIndex;
  final String? matrixGroupKey;
  final bool? matrixFailFast;

  ExtractedJob({
    required this.workflowFileName,
    required this.workflowName,
    required this.jobId,
    required this.workflowJobKey,
    required this.spec,
    this.matrix,
    this.matrixLabel,
    this.matrixIndex,
    this.matrixGroupKey,
    this.matrixFailFast,
  });
}

typedef MatrixCell = Map<String, dynamic>;

List<MatrixCell>? expandMatrix(Map<dynamic, dynamic> spec) {
  final strategy = spec['strategy'];
  if (strategy is! Map) return null;
  final matrix = strategy['matrix'];
  if (matrix is! Map) return null;

  final axes = <MapEntry<String, List<dynamic>>>[];
  for (final entry in matrix.entries) {
    final key = entry.key.toString();
    if (key == 'include' || key == 'exclude') continue;
    final val = entry.value;
    if (val is! List) return null;
    axes.add(MapEntry(key, val));
  }

  List<MatrixCell> combinations = [{}];
  if (axes.isNotEmpty) {
    for (final axis in axes) {
      final next = <MatrixCell>[];
      for (final comb in combinations) {
        for (final val in axis.value) {
          next.add({...comb, axis.key: val});
        }
      }
      combinations = next;
    }
  } else {
    combinations = [];
  }

  final excludeRaw = matrix['exclude'];
  final excludes = <MatrixCell>[];
  if (excludeRaw is List) {
    for (final ex in excludeRaw) {
      if (ex is Map) {
        excludes.add(ex.map((k, v) => MapEntry(k.toString(), v)));
      }
    }
  }

  if (excludes.isNotEmpty) {
    combinations = combinations.where((comb) {
      return !excludes.any((ex) {
        return ex.entries.every((e) => comb[e.key] == e.value);
      });
    }).toList();
  }

  final includeRaw = matrix['include'];
  final includes = <MatrixCell>[];
  if (includeRaw is List) {
    for (final inc in includeRaw) {
      if (inc is Map) {
        includes.add(inc.map((k, v) => MapEntry(k.toString(), v)));
      }
    }
  }

  final axisKeys = axes.map((e) => e.key).toSet();
  for (final inc in includes) {
    if (axisKeys.isEmpty) {
      combinations.add(inc);
      continue;
    }
    bool didMerge = false;
    combinations = combinations.map((comb) {
      final canMerge = inc.entries.every((e) {
        if (!axisKeys.contains(e.key)) return true;
        return !comb.containsKey(e.key) || comb[e.key] == e.value;
      });
      if (!canMerge) return comb;
      didMerge = true;
      return {...comb, ...inc};
    }).toList();

    if (!didMerge) {
      combinations.add(inc);
    }
  }

  if (axes.isEmpty && includes.isEmpty) return null;
  return combinations;
}

String matrixKeyValueLabel(MatrixCell cell) {
  final entries = cell.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((e) => '${e.key}=${e.value}').join(',');
}

String matrixLabel(MatrixCell cell) {
  if (cell.containsKey('name') && cell['name'] is String) {
    return cell['name'] as String;
  }
  return matrixKeyValueLabel(cell);
}

String matrixInstanceKey(String jobId, MatrixCell cell) {
  return '$jobId[${matrixKeyValueLabel(cell)}]';
}

dynamic resolveMatrixExpressions(dynamic value, MatrixCell matrix) {
  if (value is String) {
    final pattern = RegExp(
      r'\$\{\{\s*matrix\.([A-Za-z_][A-Za-z0-9_-]*)\s*\}\}',
    );
    return value.replaceAllMapped(pattern, (match) {
      final key = match.group(1);
      if (key == null) return match.group(0)!;
      final replacement = matrix[key];
      return replacement == null ? match.group(0)! : replacement.toString();
    });
  }
  if (value is Map) {
    return value.map(
      (k, v) => MapEntry(k, resolveMatrixExpressions(v, matrix)),
    );
  }
  if (value is List) {
    return value.map((v) => resolveMatrixExpressions(v, matrix)).toList();
  }
  return value;
}

bool matchesTrigger(
  Map<dynamic, dynamic> parsed,
  String triggerType,
  String? triggerBranch,
) {
  final on = parsed['on'];
  if (on == null) return false;

  if (on is String) {
    return on == triggerType;
  }

  if (on is List) {
    return on.contains(triggerType);
  }

  if (on is Map) {
    if (!on.containsKey(triggerType)) return false;
    final config = on[triggerType];
    if (config == null) return true;
    if (config is! Map) return true;

    final branches = config['branches'];
    if (branches == null || triggerBranch == null) return true;

    final branchList = branches is List
        ? branches.map((e) => e.toString()).toList()
        : [branches.toString()];
    return branchList.contains(triggerBranch);
  }

  return false;
}

extension FlatMap<T> on Iterable<T> {
  Iterable<R> flatMap<R>(Iterable<R> Function(T) f) => expand(f);
}
