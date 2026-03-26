import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/functions_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/initial_workflow_setup_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'directories_provider.g.dart';

@riverpod
String selectedRepository(Ref ref) {
  return ref.watch(initialWorkflowSetupProvider).selectedRepository;
}

@riverpod
Future<List<String>> directories(Ref ref) async {
  final selectedRepository = ref.watch(selectedRepositoryProvider);

  if (selectedRepository.isEmpty) return [];

  final team = ref.watch(teamStateProvider).value;
  if (team == null) return [];
  final functions = ref.watch(functionsProvider);

  final result = await functions.httpsCallable(listDirectoriesFunction).call({
    'teamId': team.id,
    'repository': selectedRepository,
  });

  final data = result.data as Map<String, dynamic>;
  final directories =
      (data['directories'] as List<dynamic>).map((e) => e as String).toList();

  return directories;
}
