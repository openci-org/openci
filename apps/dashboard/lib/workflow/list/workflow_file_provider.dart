import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/github/repository_aliases.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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
    @Default(true) bool enabled,
  }) = _WorkflowFile;

  factory WorkflowFile.fromJson(Map<String, Object?> json) =>
      _$WorkflowFileFromJson(json);
}

@riverpod
Stream<List<WorkflowFile>> workflowFiles(Ref ref) async* {
  final user = ref.watch(userProvider).value;
  if (user == null) {
    yield const [];
    return;
  }
  final teamId = user.selectedTeamId;

  final repositorySnapshots = firestore
      .collection('workspaces/$teamId/githubRepos')
      .where('enabled', isEqualTo: true)
      .snapshots();

  await for (final snapshot in repositorySnapshots) {
    final selections = _workflowRepositorySelectionsFromDocs(snapshot.docs);
    if (selections.isEmpty) {
      yield const [];
      continue;
    }

    yield await _loadWorkflowFilesForSelections(
      teamId: teamId,
      selections: selections,
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

List<_WorkflowRepositorySelection> _workflowRepositorySelectionsFromDocs(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  final selections = <_WorkflowRepositorySelection>[];
  final seen = <String>{};
  for (final doc in docs) {
    final data = doc.data();
    final repository = canonicalRepositoryFullName(
      data['fullName'] as String? ?? '',
    );
    if (repository.isEmpty) continue;
    final branch = data['defaultBranch'] as String? ?? 'HEAD';
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
}) async {
  final enabledOverrides = await _workflowEnabledOverrides(teamId);
  final allFiles = <WorkflowFile>[];

  for (final selection in selections) {
    final githubFiles = await _listWorkflowFilesFromGitHubWithFallback(
      teamId: teamId,
      repository: selection.repository,
      branch: selection.branch,
    );
    allFiles.addAll(
      githubFiles.map(
        (file) => file.copyWith(
          enabled: enabledOverrides[_workflowFileKey(file)] ?? file.enabled,
        ),
      ),
    );
  }

  final uniqueFiles = _uniqueWorkflowFiles(allFiles);
  uniqueFiles.sort((a, b) {
    final repositoryComparison = a.repository.compareTo(b.repository);
    if (repositoryComparison != 0) return repositoryComparison;
    return a.name.compareTo(b.name);
  });
  return uniqueFiles;
}

Future<Map<String, bool>> _workflowEnabledOverrides(String teamId) async {
  final snapshot = await firestore
      .collection(workflowFilesCollection)
      .where('teamId', isEqualTo: teamId)
      .get();
  final overrides = <String, bool>{};
  for (final doc in snapshot.docs) {
    final data = doc.data();
    final repository = canonicalRepositoryFullName(
      data['repository'] as String? ?? '',
    );
    final branch = data['branch'] as String? ?? '';
    final path =
        data['filePath'] as String? ?? data['fileName'] as String? ?? '';
    final enabled = data['enabled'];
    if (repository.isEmpty ||
        branch.isEmpty ||
        path.isEmpty ||
        enabled is! bool) {
      continue;
    }
    overrides['$repository@$branch:$path'] = enabled;
  }
  return overrides;
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
}) async {
  final result = await firebaseFunctions
      .httpsCallable('listWorkflowFiles')
      .call({
        'teamId': teamId,
        'repository': repository,
        'branch': branch,
      });
  final data = result.data as Map<String, dynamic>;
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

/// Generate a stable document ID matching the Firebase Functions logic.
String _workflowFileDocId(
  String teamId,
  String repository,
  String branch,
  String fileName,
) {
  return '${teamId}_${repository.replaceAll('/', '_')}_${branch}_$fileName';
}

@riverpod
Future<void> toggleWorkflowEnabled(
  Ref ref, {
  required String repository,
  required String branch,
  required String fileName,
  required bool enabled,
}) async {
  final user = await ref.read(userProvider.future);
  final teamId = user.selectedTeamId;

  final aliases = repositoryFullNameAliases(repository);
  final result = await firestore
      .collection(workflowFilesCollection)
      .where('teamId', isEqualTo: teamId)
      .where('repository', whereIn: aliases)
      .where('branch', isEqualTo: branch)
      .where('fileName', isEqualTo: fileName)
      .limit(1)
      .get();

  final docRef = result.docs.isNotEmpty
      ? result.docs.first.reference
      : firestore
            .collection(workflowFilesCollection)
            .doc(
              _workflowFileDocId(
                teamId,
                canonicalRepositoryFullName(repository),
                branch,
                fileName,
              ),
            );

  await docRef.update({
    'enabled': enabled,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
