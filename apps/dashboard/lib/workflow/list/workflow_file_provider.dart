import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/team/team_provider.dart';
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
    @Default(true) bool enabled,
  }) = _WorkflowFile;

  factory WorkflowFile.fromJson(Map<String, Object?> json) =>
      _$WorkflowFileFromJson(json);
}

@riverpod
Stream<List<WorkflowFile>> workflowFiles(Ref ref) {
  final team = ref.watch(teamStateProvider).value;
  final user = ref.watch(userProvider).value;

  if (team == null || user == null) {
    return Stream.value([]);
  }

  final selectedRepo = user.selectedRepository;
  final selectedBranch = user.selectedBranch;

  if (selectedRepo == null || selectedBranch == null) {
    return Stream.value([]);
  }

  return firestore
      .collection(workflowFilesCollection)
      .where('teamId', isEqualTo: team.id)
      .where('repository', isEqualTo: selectedRepo)
      .where('branch', isEqualTo: selectedBranch)
      .orderBy('fileName')
      .snapshots()
      .map(
        (result) => result.docs
            .map((doc) {
              final data = doc.data();
              return WorkflowFile(
                name: data['fileName'] as String? ?? '',
                path: data['filePath'] as String? ?? '',
                content: data['content'] as String? ?? '',
                enabled: data['enabled'] as bool? ?? true,
              );
            })
            .toList(),
      );
}

@riverpod
Future<void> syncWorkflowFiles(Ref ref) async {
  final team = ref.watch(teamStateProvider).value;
  final user = ref.watch(userProvider).value;

  if (team == null || user == null) {
    throw StateError('team or user is not loaded yet');
  }

  final functions = firebaseFunctions;

  final selectedRepo = user.selectedRepository;
  final selectedBranch = user.selectedBranch;

  if (selectedRepo == null) {
    throw StateError('selectedRepository is null');
  }

  await functions.httpsCallable('syncWorkflowFiles').call({
    'teamId': team.id,
    'repository': selectedRepo,
    'branch': selectedBranch,
  });
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
  required String fileName,
  required bool enabled,
}) async {
  final team = ref.watch(teamStateProvider).value;
  final user = ref.watch(userProvider).value;
  if (team == null || user == null) return;

  final selectedRepo = user.selectedRepository;
  final selectedBranch = user.selectedBranch;
  if (selectedRepo == null || selectedBranch == null) return;

  final docId = _workflowFileDocId(
    team.id,
    selectedRepo,
    selectedBranch,
    fileName,
  );

  await firestore.collection(workflowFilesCollection).doc(docId).update({
    'enabled': enabled,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
