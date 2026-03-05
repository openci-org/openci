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
Future<List<WorkflowFile>> workflowFiles(Ref ref) async {
  final team = ref.watch(teamStateProvider).requireValue;
  final user = ref.watch(userProvider).requireValue;
  final functions = ref.watch(functionsProvider);

  final selectedRepo = user.selectedRepository;
  final selectedBranch = user.selectedBranch;

  if (selectedRepo == null) {
    return [];
  }

  final result = await functions.httpsCallable('listWorkflowFiles').call({
    'teamId': team.id,
    'repository': selectedRepo,
    if (selectedBranch != null) 'branch': selectedBranch,
  });

  final data = result.data as Map<String, dynamic>;
  final files = (data['files'] as List<dynamic>)
      .map((e) => WorkflowFile.fromJson(Map<String, Object?>.from(e as Map)))
      .toList();

  return files;
}
