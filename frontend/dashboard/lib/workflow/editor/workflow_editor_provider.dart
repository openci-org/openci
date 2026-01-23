import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workflow_editor_provider.freezed.dart';
part 'workflow_editor_provider.g.dart';

@riverpod
class WorkflowEditor extends _$WorkflowEditor {
  @override
  Stream<Workflow?> build() => workflowStream();

  Stream<Workflow?> workflowStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Firebase Auth User Id is null');
    }
    return FirebaseFirestore.instance
        .collection('workflows_v1')
        .withConverter(
          fromFirestore: (snapshot, _) => Workflow.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('isEditing', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((qs) {
          if (qs.docs.isEmpty) {
            return null;
          }
          return qs.docs.first.data();
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
