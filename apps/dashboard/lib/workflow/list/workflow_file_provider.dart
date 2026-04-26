import 'package:dashboard/firebase/dataconnect.dart';
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

  return dataConnector
      .listWorkflowFilesForBranch(
        teamId: team.id,
        repository: selectedRepo,
        branch: selectedBranch,
      )
      .ref()
      .subscribe()
      .map(
        (result) => result.data.workflowFiles
            .map(
              (file) => WorkflowFile(
                name: file.fileName,
                path: file.filePath,
                content: file.content,
                enabled: file.enabled ?? true,
              ),
            )
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

  await dataConnector
      .updateWorkflowFileEnabled(id: docId, teamId: team.id, enabled: enabled)
      .execute();
}
