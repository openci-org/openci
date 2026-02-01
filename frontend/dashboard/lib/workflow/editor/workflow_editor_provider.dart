import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workflow_editor_provider.freezed.dart';
part 'workflow_editor_provider.g.dart';

@riverpod
class WorkflowEditor extends _$WorkflowEditor {
  @override
  Stream<Workflow> build(String workflowId) {
    return FirebaseFirestore.instance
        .collection('workflows_v1')
        .doc(workflowId)
        .withConverter(
          fromFirestore: (snapshot, _) => Workflow.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots()
        .map((doc) {
          final workflow = doc.data();
          if (workflow == null) {
            throw Exception('Workflow not found');
          }
          return workflow;
        });
  }
}

@Freezed(makeCollectionsUnmodifiable: false)
abstract class CreateWorkflowState with _$CreateWorkflowState {
  const factory CreateWorkflowState({
    required bool isCreated,
    required String selectedRepository,
    required String selectedWorkingDirectory,
    required TriggerType selectedTriggerType,
    required String selectedTriggerBranch,
    required List<WorkflowStep> selectedWorkflowSteps,
  }) = _CreateWorkflowState;

  factory CreateWorkflowState.fromJson(Map<String, Object?> json) =>
      _$CreateWorkflowStateFromJson(json);
}
