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

  ref.watch(teamStateProvider).requireValue;

  throw UnimplementedError(
    'TODO: Migrate to Firebase Data Connect',
  );
}
