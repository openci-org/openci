import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

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
    triggers: {'push': 'main'},
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

  void updateTriggers(Map<String, String?> triggers) {
    state = state.copyWith(triggers: triggers);
  }

  Future<void> save({
    required String name,
    required String selectedRepository,
    required String selectedWorkingDirectory,
  }) async {
    final documentId = Uuid().v4();
    final team = ref.watch(teamStateProvider).value;
    if (team == null) throw StateError('team is not loaded yet');
    final teamId = team.id;

    await FirebaseFirestore.instance
        .collection('workflows_v1')
        .doc(documentId)
        .set(
          Workflow(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            documentId: documentId,
            teamId: teamId,
            name: name,
            workflowConfig: WorkflowConfig(
              selectedRepository: selectedRepository,
              selectedWorkingDirectory: selectedWorkingDirectory,
              triggers: state.triggers,
            ),
            workflowSteps: [],
            isEditing: true,
          ).toJson(),
        );
  }
}

@Freezed(makeCollectionsUnmodifiable: false)
abstract class InitialWorkflowSetupState with _$InitialWorkflowSetupState {
  const factory InitialWorkflowSetupState({
    required bool isCreated,
    required String name,
    required String selectedRepository,
    required String selectedWorkingDirectory,
    required Map<String, String?> triggers,
  }) = _InitialWorkflowSetupState;

  factory InitialWorkflowSetupState.fromJson(Map<String, Object?> json) =>
      _$InitialWorkflowSetupStateFromJson(json);
}
