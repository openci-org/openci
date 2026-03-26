import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/firebase/functions_provider.dart';
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

  return ref
      .read(firestoreProvider)
      .collection(workflowFilesCollection)
      .where('teamId', isEqualTo: team.id)
      .where('repository', isEqualTo: selectedRepo)
      .where('branch', isEqualTo: selectedBranch)
      .orderBy('fileName')
      .snapshots()
      .map(
        (qs) => qs.docs.map((d) {
          final data = d.data();
          return WorkflowFile(
            name: data['fileName'] as String,
            path: data['filePath'] as String,
            content: data['content'] as String,
          );
        }).toList(),
      );
}

@riverpod
Future<void> syncWorkflowFiles(Ref ref) async {
  final team = ref.watch(teamStateProvider).value;
  final user = ref.watch(userProvider).value;

  if (team == null || user == null) {
    throw StateError('team or user is not loaded yet');
  }

  final functions = ref.read(functionsProvider);

  final selectedRepo = user.selectedRepository;
  final selectedBranch = user.selectedBranch;

  if (selectedRepo == null) {
    throw StateError('selectedRepository is null');
  }

  await functions.httpsCallable(syncWorkflowFilesFunction).call({
    'teamId': team.id,
    'repository': selectedRepo,
    'branch': selectedBranch,
  });
}
