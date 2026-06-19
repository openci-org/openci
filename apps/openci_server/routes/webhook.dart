import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:github/hooks.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  Map<String, String> env;
  try {
    env = context.read<Map<String, String>>();
  } catch (_) {
    env = Platform.environment;
  }

  final secret = env['GITHUB_WEBHOOK_SECRET'];
  if (secret == null || secret.isEmpty) {
    stderr.writeln('Warning: GITHUB_WEBHOOK_SECRET is not configured.');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Server configuration error'},
    );
  }

  final signatureHeader = context.request.headers['x-hub-signature-256'];
  if (signatureHeader == null || !signatureHeader.startsWith('sha256=')) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'success': false, 'error': 'Missing or invalid signature header'},
    );
  }

  final rawBody = await context.request.body();
  if (!verifyWebhookSignature(
    rawBody: rawBody,
    signatureHeader: signatureHeader,
    secret: secret,
  )) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'success': false, 'error': 'Signature mismatch'},
    );
  }

  final deliveryId = context.request.headers['x-github-delivery'];
  if (deliveryId == null || deliveryId.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'success': false, 'error': 'Missing x-github-delivery header'},
    );
  }

  final db = context.read<AppDatabase>();
  final exists = await (db.select(
    db.processedWebhooks,
  )..where((t) => t.deliveryId.equals(deliveryId))).getSingleOrNull();
  if (exists != null) {
    return Response.json(
      body: {
        'success': true,
        'message': 'Webhook delivery already processed',
      },
    );
  }

  final Map<String, dynamic> payload;
  try {
    payload = jsonDecode(rawBody) as Map<String, dynamic>;
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'success': false, 'error': 'Invalid JSON body'},
    );
  }

  final eventType = context.request.headers['x-github-event'];
  if (eventType != 'pull_request' && eventType != 'push') {
    return Response.json(
      body: {'success': true, 'message': 'Event ignored'},
    );
  }

  final installation = payload['installation'] as Map<String, dynamic>?;
  if (installation == null || installation['id'] == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'success': false,
        'error': 'Missing installation ID in webhook payload',
      },
    );
  }
  final installationId = installation['id'] as int;

  final team = await db.teamDao.getTeamByInstallationId(installationId);
  if (team == null) {
    stderr.writeln('Warning: No team found for installationId $installationId');
    return Response.json(
      body: {
        'success': true,
        'message': 'No registered team found for this installation',
      },
    );
  }

  final appId = env['GITHUB_APP_ID'];
  final privateKeyPath = env['GITHUB_PRIVATE_KEY_PATH'];
  if (appId == null ||
      appId.isEmpty ||
      privateKeyPath == null ||
      privateKeyPath.isEmpty) {
    stderr.writeln(
      'Error: GITHUB_APP_ID or GITHUB_PRIVATE_KEY_PATH is not configured.',
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Server integration configuration error',
      },
    );
  }

  final privateKeyFile = File(privateKeyPath);
  if (!privateKeyFile.existsSync()) {
    stderr.writeln(
      'Error: GITHUB_PRIVATE_KEY_PATH file does not exist: $privateKeyPath',
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Server integration private key not found',
      },
    );
  }
  final privateKeyPem = privateKeyFile.readAsStringSync();

  final jwtToken = generateGitHubAppJwt(appId, privateKeyPem);

  final githubApiBaseUrl = normalizeGitHubApiBaseUrl(team.githubApiBaseUrl);
  final githubBaseUrl = team.githubBaseUrl ?? 'https://github.com';

  http.Client httpClient;
  var isSelfGeneratedClient = false;
  try {
    httpClient = context.read<http.Client>();
  } catch (_) {
    httpClient = http.Client();
    isSelfGeneratedClient = true;
  }

  try {
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
      stderr.writeln('Error: Access token request timed out or failed: $e');
      return Response.json(
        statusCode: HttpStatus.gatewayTimeout,
        body: {
          'success': false,
          'error': 'GitHub API request timed out',
        },
      );
    }

    if (tokenResponse.statusCode >= 300) {
      stderr.writeln(
        'Error: Failed to retrieve installation token: ${tokenResponse.statusCode} ${tokenResponse.body}',
      );
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'error': 'Failed to retrieve installation token',
        },
      );
    }

    final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final installationToken = tokenData['token'] as String;

    // Extract git event metadata
    final String owner;
    final String repo;
    final String commitSha;
    final String branch;
    final String? triggerBranch;
    final int? pullRequestNumber;
    final String triggerType;

    if (eventType == 'pull_request') {
      final event = PullRequestEvent.fromJson(payload);
      final pr = event.pullRequest;
      final repoMap = event.repository;
      if (pr == null || repoMap == null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {
            'success': false,
            'error': 'Missing pull_request or repository data',
          },
        );
      }
      owner = repoMap.owner?.login ?? '';
      repo = repoMap.name;
      commitSha = pr.head?.sha ?? '';
      branch = pr.head?.ref ?? '';
      triggerBranch = pr.base?.ref;
      pullRequestNumber = event.number;
      triggerType = 'pull_request';
    } else {
      // push event
      if (payload['deleted'] == true) {
        return Response.json(
          body: {'success': true, 'message': 'Skipped push deletion event'},
        );
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
      stderr.writeln('Error: Fetch contents request timed out or failed: $e');
      return Response.json(
        statusCode: HttpStatus.gatewayTimeout,
        body: {
          'success': false,
          'error': 'GitHub API request timed out',
        },
      );
    }

    if (contentsResponse.statusCode == 404) {
      return Response.json(
        body: {'success': true, 'message': 'No .openci folder found'},
      );
    }

    if (contentsResponse.statusCode >= 300) {
      stderr.writeln(
        'Error: Failed to fetch contents: ${contentsResponse.statusCode} ${contentsResponse.body}',
      );
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'error': 'Failed to fetch repository contents',
        },
      );
    }

    final contentsList = jsonDecode(contentsResponse.body);
    if (contentsList is! List) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': '.openci is not a directory'},
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
      return Response.json(
        body: {'success': true, 'message': 'No yaml files found in .openci'},
      );
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
      return Response.json(
        body: {'success': true, 'message': 'No jobs matched triggers'},
      );
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
          'Error: Create check run request timed out or failed: $e',
        );
        return Response.json(
          statusCode: HttpStatus.gatewayTimeout,
          body: {
            'success': false,
            'error': 'GitHub API request timed out',
          },
        );
      }

      if (checkRunResponse.statusCode >= 300) {
        stderr.writeln(
          'Error: Failed to create check run: ${checkRunResponse.statusCode} ${checkRunResponse.body}',
        );
        return Response.json(
          statusCode: HttpStatus.internalServerError,
          body: {
            'success': false,
            'error': 'Failed to create GitHub check run',
          },
        );
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
        githubBaseUrl: githubBaseUrl,
        githubApiBaseUrl: githubApiBaseUrl,
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

    // Mark delivery as processed in DB
    await db
        .into(db.processedWebhooks)
        .insert(
          ProcessedWebhooksCompanion.insert(
            deliveryId: deliveryId,
            processedAt: DateTime.now().toUtc(),
          ),
        );

    return Response.json(
      body: {
        'success': true,
        'message': 'Webhook processed and build jobs created.',
      },
    );
  } finally {
    if (isSelfGeneratedClient) {
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

bool constantTimeCompare(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }

  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a[i] ^ b[i];
  }
  return result == 0;
}

bool verifyWebhookSignature({
  required String rawBody,
  required String signatureHeader,
  required String secret,
}) {
  if (!signatureHeader.startsWith('sha256=')) {
    return false;
  }
  final expectedSignature = signatureHeader.substring(7);
  final rawBodyBytes = utf8.encode(rawBody);

  final key = utf8.encode(secret);
  final hmacSha256 = Hmac(sha256, key);
  final digest = hmacSha256.convert(rawBodyBytes);
  final computedSignature = digest.toString();

  final computedSignatureBytes = utf8.encode(computedSignature);
  final expectedSignatureBytes = utf8.encode(expectedSignature);

  return constantTimeCompare(computedSignatureBytes, expectedSignatureBytes);
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

// Extracted Job DTO
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

// Matrix helper methods
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

  // exclude
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

  // include
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
  if (value is List) {
    return value.map((e) => resolveMatrixExpressions(e, matrix)).toList();
  }
  if (value is Map) {
    return value.map(
      (k, v) => MapEntry(k, resolveMatrixExpressions(v, matrix)),
    );
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

String normalizeGitHubApiBaseUrl(String? apiBaseUrl) {
  if (apiBaseUrl == null || apiBaseUrl.isEmpty) return 'https://api.github.com';
  final normalized = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  if (normalized == 'https://api.github.com' ||
      normalized == 'https://github.com' ||
      normalized == 'https://api.github.com/graphql') {
    return 'https://api.github.com';
  }
  if (normalized.endsWith('/api/v3')) return normalized;
  try {
    final uri = Uri.parse(normalized);
    if (normalized.endsWith('/api/graphql') ||
        normalized.endsWith('/graphql')) {
      return '${uri.scheme}://${uri.host}/api/v3';
    }
    return '${uri.scheme}://${uri.host}/api/v3';
  } catch (_) {
    return 'https://api.github.com';
  }
}

extension FlatMap<T> on Iterable<T> {
  Iterable<R> flatMap<R>(Iterable<R> Function(T) f) => expand(f);
}
