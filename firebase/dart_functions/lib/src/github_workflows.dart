import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import 'planning_event.dart';
import 'github_changed_files.dart';

enum PullRequestObservation { current, stale, closed }

// Directory segments follow the same portable path grammar as the executor.
final _workflowFile = RegExp(r'^(?:[A-Za-z0-9_-]+/)*[A-Za-z0-9_.-]+\.dart$');
final _workflowDirectory = RegExp(r'^[A-Za-z0-9_-]+(?:/[A-Za-z0-9_-]+)*$');
const _supportDirectories = {'generated', 'lib', 'test', 'tool'};

class GitHubWorkflows {
  GitHubWorkflows({
    required this.client,
    required this.apiBaseUrl,
    required this.appJwt,
    bool allowLocalHttp = false,
  }) {
    final uri = Uri.parse(apiBaseUrl);
    if (uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.scheme != 'https' &&
            !(allowLocalHttp &&
                uri.scheme == 'http' &&
                ['localhost', '127.0.0.1'].contains(uri.host)))) {
      throw ArgumentError('GitHub API requires HTTPS');
    }
  }

  final http.Client client;
  final String apiBaseUrl;
  final String Function() appJwt;

  static String signAppJwt(String appId, String privateKey) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return JWT({
      'iat': now - 60,
      'exp': now + 540,
      'iss': appId,
    }).sign(RSAPrivateKey(privateKey), algorithm: JWTAlgorithm.RS256);
  }

  Future<http.Response> _request(
    String method,
    String path,
    String token, {
    Map<String, String>? query,
    Map<String, Object?>? body,
  }) {
    final uri = Uri.parse(
      '${apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/$path',
    ).replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..followRedirects = false
      ..headers.addAll({
        'authorization': 'Bearer $token',
        'accept': 'application/vnd.github+json',
        'user-agent': 'OpenCI-BuildJobPlanner',
        'content-type': 'application/json',
      });
    if (body != null) request.body = jsonEncode(body);
    return client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 15));
  }

  Object? _json(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('GitHub request failed');
    }
    return jsonDecode(response.body);
  }

  /// Resolve the release tag once; all workflow reads and the checkout use the
  /// resulting commit SHA, never the release's mutable target_commitish.
  Future<String> resolveReleaseCommit(PlanningEvent event) async {
    if (!event.isRelease) throw StateError('Expected a release');
    final webhook = event.webhook;
    final auth = _json(
      await _request(
        'POST',
        'app/installations/${webhook.installationId}/access_tokens',
        appJwt(),
        body: {
          'repository_ids': [event.repositoryId],
          'permissions': {'contents': 'read'},
        },
      ),
    );
    if (auth is! Map<String, dynamic> ||
        auth['token'] is! String ||
        (auth['token'] as String).isEmpty) {
      throw StateError('GitHub token is unavailable');
    }
    final token = auth['token'] as String;
    final repoPath =
        'repos/${Uri.encodeComponent(webhook.owner)}/${Uri.encodeComponent(webhook.repo)}';
    try {
      final repository = _json(await _request('GET', repoPath, token));
      if (repository is! Map<String, dynamic> ||
          repository['id'] != event.repositoryId ||
          repository['owner'] is! Map<String, dynamic> ||
          (repository['owner'] as Map<String, dynamic>)['id'] !=
              event.ownerId) {
        throw const InvalidPlanningInput('invalid_payload');
      }
      final tag = Uri.encodeComponent(webhook.triggerBranch);
      final ref = _json(
        await _request('GET', '$repoPath/git/ref/tags/$tag', token),
      );
      if (ref is! Map<String, dynamic> || ref['ref'] != webhook.branch) {
        throw StateError('Invalid GitHub release tag reference');
      }
      Object? object = ref['object'];
      // Annotated tags may refer to other tags. Bound traversal and require a
      // commit: a tree/blob object must never become executable workflow input.
      final visited = <String>{};
      for (var depth = 0; depth < 10; depth++) {
        if (object is! Map<String, dynamic> || object['sha'] is! String) break;
        final sha = object['sha'] as String;
        if (!RegExp(r'^(?:[0-9a-f]{40}|[0-9a-f]{64})$').hasMatch(sha) ||
            RegExp(r'^0+$').hasMatch(sha) ||
            !visited.add(sha)) {
          break;
        }
        if (object['type'] == 'commit') return sha;
        if (object['type'] != 'tag') break;
        final annotated = _json(
          await _request('GET', '$repoPath/git/tags/$sha', token),
        );
        if (annotated is! Map<String, dynamic> || annotated['sha'] != sha) {
          break;
        }
        object = annotated['object'];
      }
      throw const InvalidPlanningInput('invalid_release_tag');
    } finally {
      final revoked = await _request('DELETE', 'installation/token', token);
      if (revoked.statusCode != 204) {
        throw StateError('GitHub token revocation failed');
      }
    }
  }

  /// Verify the live PR after acquiring the planning fence. Do not use delivery
  /// times or commit ancestry: delayed deliveries and force pushes reorder both.
  Future<PullRequestObservation> observePullRequest(PlanningEvent event) async {
    final webhook = event.webhook;
    if (webhook.pullRequestNumber == null) throw StateError('Expected a PR');
    final auth = _json(
      await _request(
        'POST',
        'app/installations/${webhook.installationId}/access_tokens',
        appJwt(),
        body: {
          'repository_ids': [event.repositoryId],
          'permissions': {'pull_requests': 'read'},
        },
      ),
    );
    if (auth is! Map<String, dynamic> ||
        auth['token'] is! String ||
        (auth['token'] as String).isEmpty) {
      throw StateError('GitHub token is unavailable');
    }
    final token = auth['token'] as String;
    try {
      final pr = _json(
        await _request(
          'GET',
          'repos/${Uri.encodeComponent(webhook.owner)}/${Uri.encodeComponent(webhook.repo)}/pulls/${webhook.pullRequestNumber}',
          token,
        ),
      );
      if (pr is! Map<String, dynamic> ||
          pr['number'] != webhook.pullRequestNumber ||
          pr['head'] is! Map<String, dynamic> ||
          pr['base'] is! Map<String, dynamic>) {
        throw StateError('Invalid GitHub pull request');
      }
      final head = pr['head'] as Map<String, dynamic>;
      final base = pr['base'] as Map<String, dynamic>;
      if (base['repo'] is! Map<String, dynamic> ||
          (base['repo'] as Map<String, dynamic>)['id'] != event.repositoryId) {
        throw const InvalidPlanningInput('untrusted_pull_request');
      }
      if (pr['state'] != 'open' && pr['state'] != 'closed' ||
          head['sha'] is! String ||
          base['ref'] is! String) {
        throw StateError('Invalid GitHub pull request revision');
      }
      // Closed PRs can have a deleted source repository. Cancellation never
      // executes repository code and only needs the verified target identity.
      if (pr['state'] == 'closed') return PullRequestObservation.closed;
      if (event.isPullRequestClosed) return PullRequestObservation.stale;
      if (head['repo'] is! Map<String, dynamic> ||
          (head['repo'] as Map<String, dynamic>)['id'] != event.repositoryId) {
        throw const InvalidPlanningInput('untrusted_pull_request');
      }
      return head['sha'] == webhook.commitSha &&
              base['ref'] == webhook.triggerBranch
          ? PullRequestObservation.current
          : PullRequestObservation.stale;
    } finally {
      final revoked = await _request('DELETE', 'installation/token', token);
      if (revoked.statusCode != 204) {
        throw StateError('GitHub token revocation failed');
      }
    }
  }

  Future<ChangedFilesResult> fetchChangedFiles(PlanningEvent event) async {
    final webhook = event.webhook;
    final auth = _json(
      await _request(
        'POST',
        'app/installations/${webhook.installationId}/access_tokens',
        appJwt(),
        body: {
          'repository_ids': [event.repositoryId],
          'permissions': {
            'contents': 'read',
            if (webhook.pullRequestNumber != null) 'pull_requests': 'read',
          },
        },
      ),
    );
    if (auth is! Map<String, dynamic> ||
        auth['token'] is! String ||
        (auth['token'] as String).isEmpty) {
      throw StateError('GitHub token is unavailable');
    }
    final token = auth['token'] as String;
    return GitHubChangedFiles(
      (path, query) => _request('GET', path, token, query: query),
    ).fetch(event);
  }

  Future<List<OpenCIFile>> fetch(PlanningEvent event) async {
    final webhook = event.webhook;
    final auth = _json(
      await _request(
        'POST',
        'app/installations/${webhook.installationId}/access_tokens',
        appJwt(),
        body: {
          'repository_ids': [event.repositoryId],
          'permissions': {'contents': 'read'},
        },
      ),
    );
    if (auth is! Map<String, dynamic> ||
        auth['token'] is! String ||
        (auth['token'] as String).isEmpty) {
      throw StateError('GitHub token is unavailable');
    }
    final token = auth['token'] as String;
    final repoPath =
        'repos/${Uri.encodeComponent(webhook.owner)}/${Uri.encodeComponent(webhook.repo)}';
    final repository = _json(await _request('GET', repoPath, token));
    if (repository is! Map<String, dynamic> ||
        repository['id'] != event.repositoryId ||
        repository['owner'] is! Map<String, dynamic> ||
        (repository['owner'] as Map<String, dynamic>)['id'] != event.ownerId) {
      throw const InvalidPlanningInput('invalid_payload');
    }
    final commit = _json(
      await _request(
        'GET',
        '$repoPath/git/commits/${webhook.commitSha}',
        token,
      ),
    );
    if (commit case {'tree': {'sha': final String rootSha}}) {
      final root = await _gitTree(repoPath, token, rootSha);
      for (final entry in root.entries) {
        if (entry['path'] == 'openci' && entry['type'] == 'tree') {
          final sources = await _workflowPaths(repoPath, token, entry['sha']);
          return _readWorkflows(repoPath, token, webhook.commitSha, sources);
        }
      }
      return [];
    }
    throw StateError('GitHub commit tree is unavailable');
  }

  Future<({List<Map<String, dynamic>> entries, bool truncated})> _gitTree(
    String repoPath,
    String token,
    Object? sha, {
    bool recursive = false,
  }) async {
    if (sha is! String ||
        !RegExp(r'^(?:[a-f0-9]{40}|[a-f0-9]{64})$').hasMatch(sha)) {
      throw StateError('Invalid GitHub tree SHA');
    }
    final data = _json(
      await _request(
        'GET',
        '$repoPath/git/trees/$sha',
        token,
        query: recursive ? {'recursive': '1'} : null,
      ),
    );
    if (data case {
      'tree': final List<Object?> entries,
      'truncated': final bool truncated,
    }) {
      if (truncated && !recursive) {
        throw StateError('Incomplete GitHub directory listing');
      }
      return (
        entries: entries.cast<Map<String, dynamic>>(),
        truncated: truncated,
      );
    }
    throw StateError('Invalid GitHub tree');
  }

  Future<List<String>> _workflowPaths(
    String repoPath,
    String token,
    Object? sha,
  ) async {
    final paths = <String>[];
    var totalSize = 0;
    final pending = [(prefix: '', sha: sha)];
    while (pending.isNotEmpty) {
      final directory = pending.removeLast();
      var tree = await _gitTree(
        repoPath,
        token,
        directory.sha,
        recursive: true,
      );
      // GitHub can truncate large recursive trees. Walk their child trees individually.
      final walkChildren = tree.truncated;
      if (walkChildren) tree = await _gitTree(repoPath, token, directory.sha);
      for (final entry in tree.entries) {
        final name = entry['path'];
        if (name is! String) throw StateError('Invalid GitHub tree path');
        final path = '${directory.prefix}$name';
        if (_supportDirectories.contains(path.split('/').first)) continue;
        if (entry['type'] == 'tree') {
          if (walkChildren && _workflowDirectory.hasMatch(path)) {
            pending.add((prefix: '$path/', sha: entry['sha']));
          }
          continue;
        }
        if (entry['type'] != 'blob' ||
            (entry['mode'] != '100644' && entry['mode'] != '100755') ||
            !_workflowFile.hasMatch(path)) {
          continue;
        }
        final size = entry['size'];
        if (size is! int || size < 0) {
          throw const InvalidPlanningInput('invalid_workflow');
        }
        totalSize += size;
        paths.add(path);
        if (paths.length > 100 || totalSize > 1024 * 1024) {
          throw const InvalidPlanningInput('invalid_workflow');
        }
      }
    }
    return paths..sort();
  }

  Future<List<OpenCIFile>> _readWorkflows(
    String repoPath,
    String token,
    String commitSha,
    List<String> sources,
  ) async {
    final query = {'ref': commitSha};
    final files = <OpenCIFile>[];
    var totalBytes = 0;
    for (var offset = 0; offset < sources.length; offset += 4) {
      final batch = await Future.wait(
        sources.skip(offset).take(4).map((relativePath) async {
          final path = 'openci/$relativePath';
          final data = _json(
            await _request(
              'GET',
              '$repoPath/contents/$path',
              token,
              query: query,
            ),
          );
          if (data is! Map<String, dynamic> ||
              data['type'] != 'file' ||
              data['encoding'] != 'base64' ||
              data['content'] is! String) {
            throw const InvalidPlanningInput('invalid_workflow');
          }
          try {
            final bytes = base64Decode(
              (data['content'] as String).replaceAll(RegExp(r'\s'), ''),
            );
            totalBytes += bytes.length;
            if (totalBytes > 1024 * 1024) {
              throw const InvalidPlanningInput('invalid_workflow');
            }
            return OpenCIFile(
              name: relativePath.split('/').last,
              path: path,
              content: utf8.decode(bytes),
            );
          } on FormatException {
            throw const InvalidPlanningInput('invalid_workflow');
          }
        }),
      );
      files.addAll(batch);
    }
    return files;
  }
}
