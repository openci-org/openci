import 'package:dashboard/supabase/supabase_provider.dart';
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

  final team = ref.watch(teamStateProvider).requireValue;
  final supabase = ref.read(supabaseClientProvider);

  final result = await supabase.rpc(
    'list_directories',
    params: {
      'p_org_id': team.id,
      'p_repository': selectedRepository,
    },
  );

  final directories = (result as List<dynamic>)
      .map((e) => e as String)
      .toList();

  return directories;
}
