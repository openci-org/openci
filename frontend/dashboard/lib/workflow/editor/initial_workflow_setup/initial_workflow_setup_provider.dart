import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final documentId = Uuid().v4();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Firebase Auth User Id is null');
    }

    await ref
        .read(firestoreProvider.notifier)
        .state
        .collection('workflows_v1')
        .doc(documentId)
        .set(
          Workflow(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            documentId: documentId,
            userId: userId,
            name: name,
            workflowConfig: WorkflowConfig(
              selectedRepository: selectedRepository,
              selectedWorkingDirectory: selectedWorkingDirectory,
              selectedTriggerType: state.selectedTriggerType,
              selectedTriggerBranch: selectedTriggerBranch,
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
    required TriggerType selectedTriggerType,
    required String selectedTriggerBranch,
  }) = _InitialWorkflowSetupState;

  factory InitialWorkflowSetupState.fromJson(Map<String, Object?> json) =>
      _$InitialWorkflowSetupStateFromJson(json);
}
