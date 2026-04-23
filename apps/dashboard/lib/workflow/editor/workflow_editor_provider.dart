import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workflow_editor_provider.freezed.dart';
part 'workflow_editor_provider.g.dart';

@riverpod
class WorkflowEditor extends _$WorkflowEditor {
  @override
  Stream<Workflow> build(String workflowId) {
    return firestore
        .collection(workflowsCollection)
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

  Future<void> updateName(String name) async {
    await firestore.collection(workflowsCollection).doc(workflowId).update({
      'name': name,
    });
  }

  Future<void> updateWorkflowConfig(WorkflowConfig config) async {
    await firestore.collection(workflowsCollection).doc(workflowId).update({
      'workflowConfig': config.toJson(),
    });
  }

  Future<void> updateWorkflowStep({
    required int index,
    required WorkflowStep step,
  }) async {
    final doc = await firestore
        .collection(workflowsCollection)
        .doc(workflowId)
        .get();
    final data = doc.data();
    if (data == null) return;

    final workflow = Workflow.fromJson(data);
    final steps = List<WorkflowStep>.from(workflow.workflowSteps);
    if (index < 0 || index >= steps.length) return;

    final existingStep = steps[index];
    final updatedStep = step.requiredSecrets.isEmpty
        ? step.copyWith(requiredSecrets: existingStep.requiredSecrets)
        : step;
    steps[index] = updatedStep;

    await firestore.collection(workflowsCollection).doc(workflowId).update({
      'workflowSteps': steps.map((s) => s.toJson()).toList(),
    });
  }

  Future<void> addStep({int? insertAt}) async {
    final doc = await firestore
        .collection(workflowsCollection)
        .doc(workflowId)
        .get();
    final data = doc.data();
    if (data == null) return;

    final workflow = Workflow.fromJson(data);
    final steps = List<WorkflowStep>.from(workflow.workflowSteps);
    final newStep = WorkflowStep(
      name: 'New Step',
      command: 'echo "Hello, OpenCI!"',
      isCompleted: true,
    );

    if (insertAt != null && insertAt >= 0 && insertAt <= steps.length) {
      steps.insert(insertAt, newStep);
    } else {
      steps.add(newStep);
    }

    await firestore.collection(workflowsCollection).doc(workflowId).update({
      'workflowSteps': steps.map((s) => s.toJson()).toList(),
    });
  }

  Future<void> deleteStep(int index) async {
    final doc = await firestore
        .collection(workflowsCollection)
        .doc(workflowId)
        .get();
    final data = doc.data();
    if (data == null) return;

    final workflow = Workflow.fromJson(data);
    final steps = List<WorkflowStep>.from(workflow.workflowSteps);
    if (index < 0 || index >= steps.length) return;

    steps.removeAt(index);

    await firestore.collection(workflowsCollection).doc(workflowId).update({
      'workflowSteps': steps.map((s) => s.toJson()).toList(),
    });
  }

  Future<void> reorderSteps(int oldIndex, int newIndex) async {
    final doc = await firestore
        .collection(workflowsCollection)
        .doc(workflowId)
        .get();
    final data = doc.data();
    if (data == null) return;

    final workflow = Workflow.fromJson(data);
    final steps = List<WorkflowStep>.from(workflow.workflowSteps);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = steps.removeAt(oldIndex);
    steps.insert(newIndex, item);

    await firestore.collection(workflowsCollection).doc(workflowId).update({
      'workflowSteps': steps.map((s) => s.toJson()).toList(),
    });
  }
}

@Freezed(makeCollectionsUnmodifiable: false)
abstract class CreateWorkflowState with _$CreateWorkflowState {
  const factory CreateWorkflowState({
    required bool isCreated,
    required String selectedRepository,
    required String selectedWorkingDirectory,
    required Map<String, String?> triggers,
    required List<WorkflowStep> selectedWorkflowSteps,
  }) = _CreateWorkflowState;

  factory CreateWorkflowState.fromJson(Map<String, Object?> json) =>
      _$CreateWorkflowStateFromJson(json);
}
