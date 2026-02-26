import 'package:dashboard/supabase/supabase_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'initial_workflow_setup_provider.freezed.dart';
part 'initial_workflow_setup_provider.g.dart';

@riverpod
class InitialWorkflowSetup extends _$InitialWorkflowSetup {
  @override
  InitialWorkflowSetupState build() => InitialWorkflowSetupState(
    isCreated: false,
    name: '',
    selectedRepository: '',
    selectedWorkingDirectory: '',
    selectedTriggerType: TriggerType.push,
    selectedTriggerBranch: '',
  );

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateIsCreated(bool value) {
    state = state.copyWith(isCreated: value);
  }

  void updateSelectedRepository(String repository) {
    state = state.copyWith(selectedRepository: repository);
  }

  void updateSelectedWorkingDirectory(String directory) {
    state = state.copyWith(selectedWorkingDirectory: directory);
  }

  void updateSelectedTriggerType(TriggerType type) {
    state = state.copyWith(selectedTriggerType: type);
  }

  void updateSelectedTriggerBranch(String branch) {
    state = state.copyWith(selectedTriggerBranch: branch);
  }

  Future<void> save({
    required String name,
    required String selectedRepository,
    required String selectedWorkingDirectory,
    String? selectedTriggerBranch,
  }) async {
    final supabase = ref.read(supabaseClientProvider);
    final orgId = ref.read(teamStateProvider).requireValue.id;

    await supabase.from('workflows').insert({
      'org_id': orgId,
      'name': name,
      'yaml_definition': '',
    });
  }
}

@Freezed(makeCollectionsUnmodifiable: false)
abstract class InitialWorkflowSetupState with _$InitialWorkflowSetupState {
  const factory InitialWorkflowSetupState({
    required bool isCreated,
    required String name,
    required String selectedRepository,
    required String selectedWorkingDirectory,
    required TriggerType selectedTriggerType,
    required String selectedTriggerBranch,
  }) = _InitialWorkflowSetupState;

  factory InitialWorkflowSetupState.fromJson(Map<String, Object?> json) =>
      _$InitialWorkflowSetupStateFromJson(json);
}
