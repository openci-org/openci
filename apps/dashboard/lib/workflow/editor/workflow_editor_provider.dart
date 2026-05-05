import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/workflow/firestore_workflow_mapper.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workflow_editor_provider.freezed.dart';
part 'workflow_editor_provider.g.dart';

@riverpod
class WorkflowEditor extends _$WorkflowEditor {
  @override
  Stream<Workflow> build(String workflowId) {
    final teamId = ref.watch(teamStateProvider).value?.id;
    if (teamId == null) return const Stream.empty();
    return firestore
        .collection(workflowsCollection)
        .doc(workflowId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null || data['teamId'] != teamId) {
            throw Exception('Workflow not found');
          }
          return workflowFromFirestore(id: snapshot.id, data: data);
        });
  }

  Future<void> updateName(String name) async {
    await _currentWorkflow();
    await _workflowDoc().update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateWorkflowConfig(WorkflowConfig config) async {
    await _currentWorkflow();
    await _workflowDoc().update({
      'workflowConfig': config.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateWorkflowStep({
    required int index,
    required WorkflowStep step,
  }) async {
    final workflow = await _currentWorkflow();
    final steps = List<WorkflowStep>.from(workflow.workflowSteps);
    if (index < 0 || index >= steps.length) return;

    final existingStep = steps[index];
    final updatedStep = step.requiredSecrets.isEmpty
        ? step.copyWith(requiredSecrets: existingStep.requiredSecrets)
        : step;
    steps[index] = updatedStep;

    await _updateSteps(steps);
  }

  Future<void> addStep({int? insertAt}) async {
    final workflow = await _currentWorkflow();
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

    await _updateSteps(steps);
  }

  Future<void> deleteStep(int index) async {
    final workflow = await _currentWorkflow();
    final steps = List<WorkflowStep>.from(workflow.workflowSteps);
    if (index < 0 || index >= steps.length) return;

    steps.removeAt(index);

    await _updateSteps(steps);
  }

  Future<void> reorderSteps(int oldIndex, int newIndex) async {
    final workflow = await _currentWorkflow();
    final steps = List<WorkflowStep>.from(workflow.workflowSteps);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = steps.removeAt(oldIndex);
    steps.insert(newIndex, item);

    await _updateSteps(steps);
  }

  Future<Workflow> _currentWorkflow() async {
    final cached = state.value;
    if (cached != null) return cached;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    final snapshot = await firestore
        .collection(workflowsCollection)
        .doc(workflowId)
        .get();
    final data = snapshot.data();
    if (data == null || data['teamId'] != teamId) {
      throw Exception('Workflow not found');
    }
    return workflowFromFirestore(id: snapshot.id, data: data);
  }

  Future<void> _updateSteps(List<WorkflowStep> steps) {
    return _workflowDoc().update({
      'workflowSteps': steps.map((step) => step.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  DocumentReference<Map<String, dynamic>> _workflowDoc() {
    return firestore.collection(workflowsCollection).doc(workflowId);
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
