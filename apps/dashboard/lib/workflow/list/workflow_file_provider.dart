import 'dart:convert';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/github/repository_aliases.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workflow_file_provider.freezed.dart';
part 'workflow_file_provider.g.dart';

@freezed
abstract class WorkflowFile with _$WorkflowFile {
  const factory WorkflowFile({
    required String name,
    required String path,
    required String content,
    required String repository,
    required String branch,
  }) = _WorkflowFile;

  factory WorkflowFile.fromJson(Map<String, Object?> json) =>
      _$WorkflowFileFromJson(json);
}

@riverpod
Stream<List<WorkflowFile>> workflowFiles(Ref ref) async* {
  final serverUrl = ref.watch(openciServerUrlProvider);
  final user = ref.watch(userProvider).value;
  if (user == null) {
    yield const [];
    return;
  }
  final teamId = user.selectedTeamId;

  final token = await ref.watch(firebaseIdTokenProvider.future);
  if (token == null) {
    yield const [];
    return;
  }

  final workspaceSnapshots = firestore.doc('workspaces/$teamId').snapshots();

  await for (final snapshot in workspaceSnapshots) {
    final selections = _workflowRepositorySelectionsFromWorkspace(
      snapshot.data(),
    );
    if (selections.isEmpty) {
      yield const [];
      continue;
    }

    yield await _loadWorkflowFilesForSelections(
      teamId: teamId,
      selections: selections,
      token: token,
      serverUrl: serverUrl,
    );
  }
}

class _WorkflowRepositorySelection {
  const _WorkflowRepositorySelection({
    required this.repository,
    required this.branch,
  });

  final String repository;
  final String branch;
}

List<_WorkflowRepositorySelection> _workflowRepositorySelectionsFromWorkspace(
  Map<String, dynamic>? data,
) {
  final selections = <_WorkflowRepositorySelection>[];
  final seen = <String>{};
  final repositories = data?['syncedGitHubRepoFullNames'];
  if (repositories is! List) {
    return selections;
  }

  for (final value in repositories) {
    final repository = canonicalRepositoryFullName(
      value is String ? value : '',
    );
    if (repository.isEmpty) continue;
    const branch = 'HEAD';
    final key = '$repository@$branch';
    if (!seen.add(key)) continue;
    selections.add(
      _WorkflowRepositorySelection(repository: repository, branch: branch),
    );
  }
  selections.sort((a, b) => a.repository.compareTo(b.repository));
  return selections;
}

Future<List<WorkflowFile>> _loadWorkflowFilesForSelections({
  required String teamId,
  required List<_WorkflowRepositorySelection> selections,
  required String token,
  required String serverUrl,
}) async {
  final allFiles = <WorkflowFile>[];

  for (final selection in selections) {
    final githubFiles = await _listWorkflowFilesFromGitHubWithFallback(
      teamId: teamId,
      repository: selection.repository,
      branch: selection.branch,
      token: token,
      serverUrl: serverUrl,
    );
    allFiles.addAll(githubFiles);
  }

  final uniqueFiles = _uniqueWorkflowFiles(allFiles);
  uniqueFiles.sort((a, b) {
    final repositoryComparison = a.repository.compareTo(b.repository);
    if (repositoryComparison != 0) return repositoryComparison;
    return a.name.compareTo(b.name);
  });
  return uniqueFiles;
}

List<WorkflowFile> _uniqueWorkflowFiles(List<WorkflowFile> files) {
  final byKey = <String, WorkflowFile>{};
  for (final file in files) {
    final key = _workflowFileKey(file);
    byKey.putIfAbsent(
      key,
      () => file.copyWith(
        repository: canonicalRepositoryFullName(file.repository),
      ),
    );
  }
  return byKey.values.toList();
}

String _workflowFileKey(WorkflowFile file) {
  final repository = canonicalRepositoryFullName(file.repository);
  final path = file.path.isNotEmpty ? file.path : file.name;
  return '$repository@${file.branch}:$path';
}

Future<List<WorkflowFile>> _listWorkflowFilesFromGitHubWithFallback({
  required String teamId,
  required String repository,
  required String branch,
  required String token,
  required String serverUrl,
}) async {
  final branches = <String>[
    branch,
    'develop',
    'main',
    'HEAD',
  ].where((value) => value.isNotEmpty).toSet();

  Object? lastError;
  for (final candidateBranch in branches) {
    try {
      final files = await _listWorkflowFilesFromGitHub(
        teamId: teamId,
        repository: repository,
        branch: candidateBranch,
        token: token,
        serverUrl: serverUrl,
      );
      if (files.isNotEmpty) return files;
    } catch (error) {
      lastError = error;
    }
  }

  if (lastError != null) throw lastError;
  return const [];
}

Future<List<WorkflowFile>> _listWorkflowFilesFromGitHub({
  required String teamId,
  required String repository,
  required String branch,
  required String token,
  required String serverUrl,
}) async {
  final encodedRepo = Uri.encodeComponent(repository);
  final encodedBranch = Uri.encodeComponent(branch);
  final url = Uri.parse(
    '$serverUrl/teams/$teamId/workflows?repository=$encodedRepo&branch=$encodedBranch',
  );

  final response = await http
      .get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      )
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw StateError(
      'Failed to load workflows: ${response.statusCode} ${response.body}',
    );
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final files = (data['files'] as List<dynamic>).map((entry) {
    final file = Map<String, dynamic>.from(entry as Map);
    return WorkflowFile(
      name: file['name'] as String? ?? '',
      path: file['path'] as String? ?? '',
      content: file['content'] as String? ?? '',
      repository: canonicalRepositoryFullName(repository),
      branch: branch,
    );
  }).toList()..sort((a, b) => a.name.compareTo(b.name));
  return files;
}
