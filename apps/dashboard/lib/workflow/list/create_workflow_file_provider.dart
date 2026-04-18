import 'package:dashboard/firebase/dart_function_urls.dart';
import 'package:dashboard/firebase/functions_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_workflow_file_provider.g.dart';

enum CommitMode {
  direct,
  pullRequest
  ;

  String toApiValue() {
    switch (this) {
      case CommitMode.direct:
        return 'direct';
      case CommitMode.pullRequest:
        return 'pull_request';
    }
  }
}

@riverpod
class CreateWorkflowFileNotifier extends _$CreateWorkflowFileNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Map<String, dynamic>> createWorkflowFile({
    required String repository,
    required String branch,
    required String fileName,
    required String content,
    required CommitMode commitMode,
    String? commitMessage,
  }) async {
    state = const AsyncLoading();

    final team = ref.read(teamStateProvider).value;
    if (team == null) throw StateError('team is not loaded yet');
    final functions = ref.read(functionsProvider);

    try {
      final result = await functions
          .httpsCallableFromUrl(dartFunctionUrl('create-workflow-file'))
          .call({
            'teamId': team.id,
            'repository': repository,
            'branch': branch,
            'fileName': fileName,
            'content': content,
            'commitMode': commitMode.toApiValue(),
            if (commitMessage != null && commitMessage.isNotEmpty)
              'commitMessage': commitMessage,
          });

      final data = Map<String, dynamic>.from(result.data as Map);
      if (ref.mounted) state = const AsyncData(null);
      return data;
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      rethrow;
    }
  }
}
