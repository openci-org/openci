import 'package:dashboard/firebase/dart_function_urls.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  final functions = FirebaseFunctions.instance;

  final result = await functions
      .httpsCallableFromUrl(dartFunctionUrl('list-directories'))
      .call({
    'teamId': team.id,
    'repository': selectedRepository,
  });

  final data = result.data as Map<String, dynamic>;
  final directories = (data['directories'] as List<dynamic>)
      .map((e) => e as String)
      .toList();

  return directories;
}
