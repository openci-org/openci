import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';
import '../util/github_app.dart';
import '../util/github_urls.dart';
import '../util/logger.dart';
import '../util/team_auth.dart';

const _branchesQuery = r'''
  query($owner: String!, $repo: String!, $cursor: String) {
    repository(owner: $owner, name: $repo) {
      defaultBranchRef { name }
      refs(refPrefix: "refs/heads/", first: 100, after: $cursor, orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) {
        nodes {
          name
          target {
            ... on Commit { committedDate }
          }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
''';

String _buildDirectoryTreeFragment(int depth) {
  if (depth == 0) return 'name type';
  return 'name type object { ... on Tree { entries { ${_buildDirectoryTreeFragment(depth - 1)} } } }';
}

final _directoryTreeQuery =
    '''
  query(\$owner: String!, \$repo: String!, \$expression: String!) {
    repository(owner: \$owner, name: \$repo) {
      object(expression: \$expression) {
        ... on Tree {
          entries {
            ${_buildDirectoryTreeFragment(7)}
          }
        }
      }
    }
  }
''';

const _openciDirQuery = r'''
  query($owner: String!, $repo: String!, $expression: String!) {
    repository(owner: $owner, name: $repo) {
      object(expression: $expression) {
        ... on Tree {
          entries {
            name
            type
            object {
              ... on Blob { text }
            }
          }
        }
      }
    }
  }
''';

// ---------------------------------------------------------------------------
// Request models
// ---------------------------------------------------------------------------

class TeamIdRequest {
  const TeamIdRequest({required this.teamId});

  factory TeamIdRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    if (teamId == null || teamId.isEmpty) {
      throw InvalidArgumentError('Missing teamId');
    }
    return TeamIdRequest(teamId: teamId);
  }

  final String teamId;
}

class RepoRequest {
  const RepoRequest({required this.teamId, required this.repository});

  factory RepoRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    final repository = json['repository'] as String?;
    if (teamId == null ||
        teamId.isEmpty ||
        repository == null ||
        repository.isEmpty) {
      throw InvalidArgumentError('Missing teamId or repository');
    }
    return RepoRequest(teamId: teamId, repository: repository);
  }

  final String teamId;
  final String repository;
}

class ListWorkflowFilesRequest {
  const ListWorkflowFilesRequest({
    required this.teamId,
    required this.repository,
    this.branch,
  });

  factory ListWorkflowFilesRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    final repository = json['repository'] as String?;
    if (teamId == null ||
        teamId.isEmpty ||
        repository == null ||
        repository.isEmpty) {
      throw InvalidArgumentError('Missing teamId or repository');
    }
    return ListWorkflowFilesRequest(
      teamId: teamId,
      repository: repository,
      branch: json['branch'] as String?,
    );
  }

  final String teamId;
  final String repository;
  final String? branch;
}

class SearchGitHubActionsRequest {
  const SearchGitHubActionsRequest({
    required this.teamId,
    required this.type,
    this.query,
    this.fullName,
  });

  factory SearchGitHubActionsRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    final type = json['type'] as String?;
    if (teamId == null || teamId.isEmpty) {
      throw InvalidArgumentError('Missing teamId');
    }
    return SearchGitHubActionsRequest(
      teamId: teamId,
      type: type ?? 'search',
      query: json['query'] as String?,
      fullName: json['fullName'] as String?,
    );
  }

  final String teamId;
  final String type;
  final String? query;
  final String? fullName;
}

class CreateWorkflowFileRequest {
  const CreateWorkflowFileRequest({
    required this.teamId,
    required this.repository,
    required this.branch,
    required this.fileName,
    required this.content,
    required this.commitMode,
    this.commitMessage,
  });

  factory CreateWorkflowFileRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    final repository = json['repository'] as String?;
    final branch = json['branch'] as String?;
    final fileName = json['fileName'] as String?;
    final content = json['content'] as String?;
    final commitMode = json['commitMode'] as String?;
    if (teamId == null ||
        repository == null ||
        branch == null ||
        fileName == null ||
        content == null ||
        commitMode == null) {
      throw InvalidArgumentError('Missing required fields');
    }
    if (!fileName.endsWith('.yaml') && !fileName.endsWith('.yml')) {
      throw InvalidArgumentError('File name must end with .yaml or .yml');
    }
    return CreateWorkflowFileRequest(
      teamId: teamId,
      repository: repository,
      branch: branch,
      fileName: fileName,
      content: content,
      commitMode: commitMode,
      commitMessage: json['commitMessage'] as String?,
    );
  }

  final String teamId;
  final String repository;
  final String branch;
  final String fileName;
  final String content;
  final String commitMode;
  final String? commitMessage;
}

class SyncWorkflowFilesRequest {
  const SyncWorkflowFilesRequest({
    required this.teamId,
    required this.repository,
    this.branch,
  });

  factory SyncWorkflowFilesRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    final repository = json['repository'] as String?;
    if (teamId == null ||
        teamId.isEmpty ||
        repository == null ||
        repository.isEmpty) {
      throw InvalidArgumentError('Missing teamId or repository');
    }
    return SyncWorkflowFilesRequest(
      teamId: teamId,
      repository: repository,
      branch: json['branch'] as String?,
    );
  }

  final String teamId;
  final String repository;
  final String? branch;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Gets installation IDs from team data, throwing if none.
List<int> _getInstallationIds(Map<String, dynamic> teamData) {
  final ids =
      (teamData['installationIds'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ??
      [];
  if (ids.isEmpty) {
    throw FailedPreconditionError('GitHub App is not installed for this team');
  }
  return ids;
}

/// Flattens tree entries into directory paths.
List<String> _flattenTreeEntries(List<dynamic> entries, [String prefix = '']) {
  final dirs = <String>[];
  for (final entry in entries) {
    final e = entry as Map<String, dynamic>;
    if (e['type'] != 'tree') continue;
    final path = prefix.isEmpty ? e['name'] as String : '$prefix/${e['name']}';
    dirs.add(path);
    final childEntries =
        (e['object'] as Map<String, dynamic>?)?['entries'] as List<dynamic>?;
    if (childEntries != null) {
      dirs.addAll(_flattenTreeEntries(childEntries, path));
    }
  }
  return dirs;
}

/// Generates stable document ID for workflow files in Firestore.
String _workflowFileDocId(
  String teamId,
  String repository,
  String branch,
  String fileName,
) {
  return '${teamId}_${repository.replaceAll('/', '_')}_${branch}_$fileName';
}

// ---------------------------------------------------------------------------
// Handlers
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> handleListRepositories(
  CallableRequest<TeamIdRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final teamData = await verifyTeamMembership(
    auth: request.auth,
    teamId: request.data.teamId,
  );

  final installationIds = _getInstallationIds(teamData);
  final apiBaseUrl = getApiBaseUrlFromTeamData(teamData);

  try {
    final allRepositories = <Map<String, dynamic>>[];

    for (final installationId in installationIds) {
      final tokenData = await getInstallationToken(
        installationId,
        apiBaseUrl: apiBaseUrl,
      );
      final token = tokenData['token'] as String;

      final data = await githubGet(
        '/installation/repositories',
        token,
        queryParameters: {'per_page': 100},
        apiBaseUrl: apiBaseUrl,
      );

      final repos =
          (data['repositories'] as List<dynamic>?)?.map((repo) {
            final r = repo as Map<String, dynamic>;
            final owner = r['owner'] as Map<String, dynamic>;
            return {
              'fullName': r['full_name'],
              'name': r['name'],
              'owner': owner['login'],
              'private': r['private'],
              'defaultBranch': r['default_branch'],
            };
          }).toList() ??
          [];

      allRepositories.addAll(repos);
    }

    return <String, dynamic>{'repositories': allRepositories};
  } catch (e) {
    if (e is HttpsError) rethrow;
    logError('Failed to list repositories', null, e);
    throw InternalError('Failed to list repositories');
  }
}

Future<Map<String, dynamic>> handleListBranches(
  CallableRequest<RepoRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final teamData = await verifyTeamMembership(
    auth: request.auth,
    teamId: request.data.teamId,
  );

  final installationIds = _getInstallationIds(teamData);
  final apiBaseUrl = getApiBaseUrlFromTeamData(teamData);
  final parts = request.data.repository.split('/');
  final owner = parts[0];
  final repo = parts[1];

  try {
    for (final installationId in installationIds) {
      try {
        final tokenData = await getInstallationToken(
          installationId,
          apiBaseUrl: apiBaseUrl,
        );
        final token = tokenData['token'] as String;

        final allBranches = <Map<String, dynamic>>[];
        String? cursor;
        String? defaultBranchName;

        while (true) {
          final result = await githubGraphql(
            _branchesQuery,
            token,
            variables: {'owner': owner, 'repo': repo, 'cursor': cursor},
            apiBaseUrl: apiBaseUrl,
          );

          final repository =
              result['data']?['repository'] as Map<String, dynamic>?;
          if (repository == null) break;

          defaultBranchName ??=
              (repository['defaultBranchRef'] as Map<String, dynamic>?)?['name']
                  as String?;

          final refs = repository['refs'] as Map<String, dynamic>;
          final nodes = refs['nodes'] as List<dynamic>;
          allBranches.addAll(nodes.cast<Map<String, dynamic>>());

          final pageInfo = refs['pageInfo'] as Map<String, dynamic>;
          if (pageInfo['hasNextPage'] != true) break;
          cursor = pageInfo['endCursor'] as String?;
        }

        // Sort: default branch first, then by committed date
        allBranches.sort((a, b) {
          if (a['name'] == defaultBranchName) return -1;
          if (b['name'] == defaultBranchName) return 1;
          final aDate =
              (a['target'] as Map<String, dynamic>?)?['committedDate']
                  as String? ??
              '';
          final bDate =
              (b['target'] as Map<String, dynamic>?)?['committedDate']
                  as String? ??
              '';
          return bDate.compareTo(aDate);
        });

        final branches = allBranches.map((b) => b['name'] as String).toList();

        return <String, dynamic>{'branches': branches};
      } catch (_) {
        continue;
      }
    }

    throw NotFoundError('Repository not found in any installation');
  } catch (e) {
    if (e is HttpsError) rethrow;
    logError('Failed to list branches', null, e);
    throw InternalError('Failed to list branches');
  }
}

Future<Map<String, dynamic>> handleListDirectories(
  CallableRequest<RepoRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final teamData = await verifyTeamMembership(
    auth: request.auth,
    teamId: request.data.teamId,
  );

  final installationIds = _getInstallationIds(teamData);
  final apiBaseUrl = getApiBaseUrlFromTeamData(teamData);
  final parts = request.data.repository.split('/');
  final owner = parts[0];
  final repo = parts[1];

  try {
    for (final installationId in installationIds) {
      try {
        final tokenData = await getInstallationToken(
          installationId,
          apiBaseUrl: apiBaseUrl,
        );
        final token = tokenData['token'] as String;

        final result = await githubGraphql(
          _directoryTreeQuery,
          token,
          variables: {'owner': owner, 'repo': repo, 'expression': 'HEAD:'},
          apiBaseUrl: apiBaseUrl,
        );

        final entries =
            ((result['data']?['repository'] as Map<String, dynamic>?)?['object']
                    as Map<String, dynamic>?)?['entries']
                as List<dynamic>? ??
            [];

        final directories = <String>[
          '.',
          ..._flattenTreeEntries(entries)..sort(),
        ];

        return <String, dynamic>{'directories': directories};
      } catch (_) {
        continue;
      }
    }

    throw NotFoundError('Repository not found in any installation');
  } catch (e) {
    if (e is HttpsError) rethrow;
    logError('Failed to list directories', null, e);
    throw InternalError('Failed to list directories');
  }
}

Future<Map<String, dynamic>> handleListWorkflowFiles(
  CallableRequest<ListWorkflowFilesRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final teamData = await verifyTeamMembership(
    auth: request.auth,
    teamId: request.data.teamId,
  );

  final installationIds = _getInstallationIds(teamData);
  final apiBaseUrl = getApiBaseUrlFromTeamData(teamData);
  final parts = request.data.repository.split('/');
  final owner = parts[0];
  final repo = parts[1];

  try {
    for (final installationId in installationIds) {
      try {
        final tokenData = await getInstallationToken(
          installationId,
          apiBaseUrl: apiBaseUrl,
        );
        final token = tokenData['token'] as String;

        final expression = '${request.data.branch ?? "HEAD"}:.openci';

        List<dynamic> entries;
        try {
          final result = await githubGraphql(
            _openciDirQuery,
            token,
            variables: {'owner': owner, 'repo': repo, 'expression': expression},
            apiBaseUrl: apiBaseUrl,
          );
          entries =
              ((result['data']?['repository']
                          as Map<String, dynamic>?)?['object']
                      as Map<String, dynamic>?)?['entries']
                  as List<dynamic>? ??
              [];
        } catch (e) {
          if (e.toString().contains('Could not resolve to an object')) {
            return <String, dynamic>{'files': <Map<String, dynamic>>[]};
          }
          rethrow;
        }

        final files = entries
            .where((entry) {
              final e = entry as Map<String, dynamic>;
              final name = e['name'] as String;
              return e['type'] == 'blob' &&
                  (name.endsWith('.yaml') || name.endsWith('.yml')) &&
                  (e['object'] as Map<String, dynamic>?)?['text'] != null;
            })
            .map((entry) {
              final e = entry as Map<String, dynamic>;
              return {
                'name': e['name'],
                'path': '.openci/${e['name']}',
                'content': (e['object'] as Map<String, dynamic>)['text'],
              };
            })
            .toList();

        return <String, dynamic>{'files': files};
      } catch (e) {
        if (e is HttpsError) rethrow;
        continue;
      }
    }

    throw NotFoundError('Repository not found in any installation');
  } catch (e) {
    if (e is HttpsError) rethrow;
    logError('Failed to list workflow files', null, e);
    throw InternalError('Failed to list workflow files');
  }
}

Future<Map<String, dynamic>> handleSearchGitHubActions(
  CallableRequest<SearchGitHubActionsRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final teamData = await verifyTeamMembership(
    auth: request.auth,
    teamId: request.data.teamId,
  );

  final installationIds = _getInstallationIds(teamData);
  final apiBaseUrl = getApiBaseUrlFromTeamData(teamData);

  try {
    final tokenData = await getInstallationToken(
      installationIds[0],
      apiBaseUrl: apiBaseUrl,
    );
    final token = tokenData['token'] as String;

    if (request.data.type == 'search') {
      final searchQuery = request.data.query?.trim().isNotEmpty == true
          ? request.data.query!.trim()
          : 'github action';

      final data = await githubGet(
        '/search/repositories',
        token,
        queryParameters: {
          'q': searchQuery,
          'sort': 'stars',
          'order': 'desc',
          'per_page': 50,
        },
        apiBaseUrl: apiBaseUrl,
      );

      final actions =
          (data['items'] as List<dynamic>?)?.map((repo) {
            final r = repo as Map<String, dynamic>;
            final owner = r['owner'] as Map<String, dynamic>;
            return {
              'fullName': r['full_name'],
              'description': r['description'] ?? '',
              'stars': r['stargazers_count'],
              'owner': owner['login'],
              'avatarUrl': owner['avatar_url'],
              'htmlUrl': r['html_url'],
              'defaultBranch': r['default_branch'] ?? 'main',
              'isOfficial': owner['login'] == 'actions',
            };
          }).toList() ??
          [];

      return <String, dynamic>{'actions': actions};
    }

    if (request.data.type == 'tags') {
      final fullName = request.data.fullName;
      if (fullName == null || fullName.isEmpty) {
        throw InvalidArgumentError('Missing fullName for tags');
      }

      final parts = fullName.split('/');
      final owner = parts[0];
      final repo = parts[1];

      final dio = Dio();
      try {
        final tagsResponse = await dio.get<List<dynamic>>(
          '$apiBaseUrl/repos/$owner/$repo/tags',
          queryParameters: {'per_page': 100},
          options: Options(
            headers: {
              'Authorization': 'token $token',
              'Accept': 'application/vnd.github+json',
            },
          ),
        );

        final majorTags = <String>[];
        final allTags = <String>[];

        for (final tag in tagsResponse.data ?? []) {
          final name = (tag as Map<String, dynamic>)['name'] as String;
          allTags.add(name);
          if (RegExp(r'^v\d+$').hasMatch(name)) {
            majorTags.add(name);
          }
        }

        return <String, dynamic>{
          'tags': majorTags.isNotEmpty ? majorTags : allTags,
        };
      } finally {
        dio.close();
      }
    }

    throw InvalidArgumentError('Invalid type');
  } catch (e) {
    if (e is HttpsError) rethrow;
    logError('Failed to search GitHub actions', null, e);
    throw InternalError('Failed to search GitHub actions');
  }
}

Future<Map<String, dynamic>> handleCreateWorkflowFile(
  CallableRequest<CreateWorkflowFileRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final teamData = await verifyTeamMembership(
    auth: request.auth,
    teamId: request.data.teamId,
  );

  final installationIds = _getInstallationIds(teamData);
  final apiBaseUrl = getApiBaseUrlFromTeamData(teamData);
  final parts = request.data.repository.split('/');
  final owner = parts[0];
  final repo = parts[1];
  final filePath = '.openci/${request.data.fileName}';
  final message =
      request.data.commitMessage ?? 'Add workflow: ${request.data.fileName}';
  final contentBase64 = base64.encode(utf8.encode(request.data.content));

  try {
    for (final installationId in installationIds) {
      try {
        final tokenData = await getInstallationToken(
          installationId,
          apiBaseUrl: apiBaseUrl,
        );
        final token = tokenData['token'] as String;

        if (request.data.commitMode == 'direct') {
          // Get latest commit SHA
          final refData = await githubGet(
            '/repos/$owner/$repo/git/ref/heads/${request.data.branch}',
            token,
            apiBaseUrl: apiBaseUrl,
          );
          final latestCommitSha =
              (refData['object'] as Map<String, dynamic>)['sha'] as String;

          // Create blob
          final blobData = await githubPost(
            '/repos/$owner/$repo/git/blobs',
            token,
            data: {'content': contentBase64, 'encoding': 'base64'},
            apiBaseUrl: apiBaseUrl,
          );

          // Get latest commit tree
          final latestCommit = await githubGet(
            '/repos/$owner/$repo/git/commits/$latestCommitSha',
            token,
            apiBaseUrl: apiBaseUrl,
          );
          final baseTreeSha =
              (latestCommit['tree'] as Map<String, dynamic>)['sha'] as String;

          // Create tree
          final treeData = await githubPost(
            '/repos/$owner/$repo/git/trees',
            token,
            data: {
              'base_tree': baseTreeSha,
              'tree': [
                {
                  'path': filePath,
                  'mode': '100644',
                  'type': 'blob',
                  'sha': blobData['sha'],
                },
              ],
            },
            apiBaseUrl: apiBaseUrl,
          );

          // Create commit
          final newCommit = await githubPost(
            '/repos/$owner/$repo/git/commits',
            token,
            data: {
              'message': message,
              'tree': treeData['sha'],
              'parents': [latestCommitSha],
            },
            apiBaseUrl: apiBaseUrl,
          );

          // Update ref
          await githubPatch(
            '/repos/$owner/$repo/git/refs/heads/${request.data.branch}',
            token,
            data: {'sha': newCommit['sha']},
            apiBaseUrl: apiBaseUrl,
          );

          return <String, dynamic>{
            'mode': 'direct',
            'commitSha': newCommit['sha'],
            'branch': request.data.branch,
          };
        } else {
          // Pull request mode
          final newBranchName =
              'openci/add-${request.data.fileName.replaceAll(RegExp(r'\.(yaml|yml)$'), '')}-${DateTime.now().millisecondsSinceEpoch}';

          final refData = await githubGet(
            '/repos/$owner/$repo/git/ref/heads/${request.data.branch}',
            token,
            apiBaseUrl: apiBaseUrl,
          );

          await githubPost(
            '/repos/$owner/$repo/git/refs',
            token,
            data: {
              'ref': 'refs/heads/$newBranchName',
              'sha': (refData['object'] as Map<String, dynamic>)['sha'],
            },
            apiBaseUrl: apiBaseUrl,
          );

          await githubPut(
            '/repos/$owner/$repo/contents/$filePath',
            token,
            data: {
              'message': message,
              'content': contentBase64,
              'branch': newBranchName,
            },
            apiBaseUrl: apiBaseUrl,
          );

          final pr = await githubPost(
            '/repos/$owner/$repo/pulls',
            token,
            data: {
              'title': message,
              'head': newBranchName,
              'base': request.data.branch,
              'body':
                  'This workflow file was created by OpenCI.\n\nFile: `$filePath`',
            },
            apiBaseUrl: apiBaseUrl,
          );

          return <String, dynamic>{
            'mode': 'pull_request',
            'pullRequestUrl': pr['html_url'],
            'pullRequestNumber': pr['number'],
            'branch': newBranchName,
          };
        }
      } catch (e) {
        if (e is HttpsError) rethrow;
        continue;
      }
    }

    throw NotFoundError('Repository not found in any installation');
  } catch (e) {
    if (e is HttpsError) rethrow;
    logError('Failed to create workflow file', null, e);
    throw InternalError('Failed to create workflow file');
  }
}

Future<Map<String, dynamic>> handleSyncWorkflowFiles(
  CallableRequest<SyncWorkflowFilesRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final teamData = await verifyTeamMembership(
    auth: request.auth,
    teamId: request.data.teamId,
  );

  final installationIds = _getInstallationIds(teamData);
  final apiBaseUrl = getApiBaseUrlFromTeamData(teamData);
  final parts = request.data.repository.split('/');
  final owner = parts[0];
  final repo = parts[1];
  final targetBranch = request.data.branch ?? 'HEAD';

  try {
    for (final installationId in installationIds) {
      try {
        final tokenData = await getInstallationToken(
          installationId,
          apiBaseUrl: apiBaseUrl,
        );
        final token = tokenData['token'] as String;

        // Verify repository access
        await githubGet('/repos/$owner/$repo', token, apiBaseUrl: apiBaseUrl);

        // Sync workflow files
        final result = await _syncWorkflowFilesToFirestore(
          teamId: request.data.teamId,
          repository: request.data.repository,
          branch: targetBranch,
          token: token,
          apiBaseUrl: apiBaseUrl,
        );

        return result;
      } catch (e) {
        if (e is HttpsError) rethrow;
        continue;
      }
    }

    throw NotFoundError('Repository not found in any installation');
  } catch (e) {
    if (e is HttpsError) rethrow;
    logError('Failed to sync workflow files', null, e);
    throw InternalError('Failed to sync workflow files');
  }
}

/// Syncs .openci/ workflow files from GitHub to Firestore.
Future<Map<String, dynamic>> _syncWorkflowFilesToFirestore({
  required String teamId,
  required String repository,
  required String branch,
  required String token,
  String apiBaseUrl = defaultGitHubApiBaseUrl,
}) async {
  final parts = repository.split('/');
  final owner = parts[0];
  final repo = parts[1];
  final expression = '$branch:.openci';

  List<dynamic> entries;
  try {
    final result = await githubGraphql(
      _openciDirQuery,
      token,
      variables: {'owner': owner, 'repo': repo, 'expression': expression},
      apiBaseUrl: apiBaseUrl,
    );
    entries =
        ((result['data']?['repository'] as Map<String, dynamic>?)?['object']
                as Map<String, dynamic>?)?['entries']
            as List<dynamic>? ??
        [];
  } catch (e) {
    if (e.toString().contains('Could not resolve to an object')) {
      // .openci/ directory does not exist — delete all cached files
      await _deleteAllWorkflowFiles(teamId, repository, branch);
      return <String, dynamic>{'synced': 0, 'deleted': 0};
    }
    rethrow;
  }

  final yamlEntries = entries.where((entry) {
    final e = entry as Map<String, dynamic>;
    final name = e['name'] as String;
    return e['type'] == 'blob' &&
        (name.endsWith('.yaml') || name.endsWith('.yml')) &&
        (e['object'] as Map<String, dynamic>?)?['text'] != null;
  }).toList();

  final currentFileNames = <String>{};
  var syncedCount = 0;
  final now = DateTime.now().toUtc().toIso8601String();

  for (final entry in yamlEntries) {
    final e = entry as Map<String, dynamic>;
    final name = e['name'] as String;
    final docId = _workflowFileDocId(teamId, repository, branch, name);
    final docRef = firestore.collection(workflowFilesCollection).doc(docId);

    currentFileNames.add(name);

    await docRef.set({
      'teamId': teamId,
      'repository': repository,
      'branch': branch,
      'fileName': name,
      'filePath': '.openci/$name',
      'content': (e['object'] as Map<String, dynamic>)['text'],
      'updatedAt': now,
      'syncedAt': now,
    });

    syncedCount++;
  }

  // Delete workflow files that no longer exist in the repository
  final deletedCount = await _deleteRemovedWorkflowFiles(
    teamId,
    repository,
    branch,
    currentFileNames,
  );

  logInfo(
    'Synced $syncedCount workflow files, deleted $deletedCount for $repository@$branch',
  );

  return <String, dynamic>{'synced': syncedCount, 'deleted': deletedCount};
}

Future<int> _deleteAllWorkflowFiles(
  String teamId,
  String repository,
  String branch,
) async {
  final snapshot = await firestore
      .collection(workflowFilesCollection)
      .where('teamId', WhereFilter.equal, teamId)
      .where('repository', WhereFilter.equal, repository)
      .where('branch', WhereFilter.equal, branch)
      .get();

  if (snapshot.docs.isEmpty) return 0;

  for (final doc in snapshot.docs) {
    await doc.ref.delete();
  }

  return snapshot.docs.length;
}

Future<int> _deleteRemovedWorkflowFiles(
  String teamId,
  String repository,
  String branch,
  Set<String> currentFileNames,
) async {
  final snapshot = await firestore
      .collection(workflowFilesCollection)
      .where('teamId', WhereFilter.equal, teamId)
      .where('repository', WhereFilter.equal, repository)
      .where('branch', WhereFilter.equal, branch)
      .get();

  final toDelete = snapshot.docs
      .where((doc) => !currentFileNames.contains(doc.data()['fileName']))
      .toList();

  if (toDelete.isEmpty) return 0;

  for (final doc in toDelete) {
    await doc.ref.delete();
  }

  return toDelete.length;
}
