import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';
import '../util/github_urls.dart';
import '../util/logger.dart';
import 'graphql_queries.dart';
import 'installation_token.dart';
import 'workflow_parser.dart';

Future<void> syncWorkflowFiles({
  required String repository,
  required String branch,
  required int installationId,
}) async {
  final teamId = await _findTeamIdForInstallation(installationId);
  if (teamId == null) {
    logInfo('No team found for installation, skipping sync', {
      'installationId': installationId,
    });
    return;
  }

  final apiBaseUrl = await getGitHubApiBaseUrl(teamId);

  final (:token, expiresAt: _) = await getInstallationToken(
    installationId,
    apiBaseUrl: apiBaseUrl,
  );
  final dio = createGitHubDio(token, apiBaseUrl: apiBaseUrl);

  try {
    final [owner, repo] = repository.split('/');
    final expression = '$branch:.openci';

    List<OpenciDirEntry> entries;
    try {
      final response = await dio.post(
        graphqlEndpoint(apiBaseUrl),
        data: {
          'query': openciDirQuery,
          'variables': {'owner': owner, 'repo': repo, 'expression': expression},
        },
      );

      entries =
          ((response.data['data']?['repository']?['object']?['entries']
                      as List<dynamic>?) ??
                  [])
              .map((e) => OpenciDirEntry.fromJson(e as Map<String, dynamic>))
              .toList();
    } catch (e) {
      final message = e.toString();
      if (message.contains('Could not resolve to an object')) {
        await _deleteAllWorkflowFiles(teamId, repository, branch);
        return;
      }
      rethrow;
    }

    final yamlEntries = entries.where(
      (e) =>
          e.type == 'blob' &&
          (e.name.endsWith('.yaml') || e.name.endsWith('.yml')) &&
          e.text != null,
    );

    final currentFileNames = <String>{};
    var syncedCount = 0;

    for (final entry in yamlEntries) {
      final docId = workflowFileDocId(teamId, repository, branch, entry.name);
      final now = DateTime.now().toUtc().toIso8601String();

      currentFileNames.add(entry.name);

      await firestore.collection(workflowFilesCollection).doc(docId).set({
        'teamId': teamId,
        'repository': repository,
        'branch': branch,
        'fileName': entry.name,
        'filePath': '.openci/${entry.name}',
        'content': entry.text,
        'updatedAt': now,
        'syncedAt': now,
      }, options: const SetOptions.merge());

      syncedCount++;
    }

    final deletedCount = await _deleteRemovedWorkflowFiles(
      teamId,
      repository,
      branch,
      currentFileNames,
    );

    logInfo('Synced workflow files', {
      'synced': syncedCount,
      'deleted': deletedCount,
      'repo': repository,
      'branch': branch,
    });
  } catch (e, stackTrace) {
    await logError(
      'Failed to sync workflow files',
      {'repo': repository},
      e,
      stackTrace,
    );
  } finally {
    dio.close();
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
  } catch (e, stackTrace) {
    await logError('Failed to find team for installation', {}, e, stackTrace);
    return null;
  }
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

  final toDelete = snapshot.docs.where(
    (doc) => !currentFileNames.contains(doc.data()['fileName']),
  );

  var count = 0;
  for (final doc in toDelete) {
    await doc.ref.delete();
    count++;
  }

  return count;
}
