import 'package:dashboard/firebase/dataconnect.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/workflow/dataconnect_workflow_mapper.dart';
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
    return dataConnector
        .getWorkflow(id: workflowId, teamId: teamId)
        .ref()
        .subscribe()
        .map((result) {
          final workflow = result.data.workflow;
          if (workflow == null) throw Exception('Workflow not found');
          return workflowFromDataConnect(
            id: workflow.id,
            teamId: workflow.teamId,
            name: workflow.name,
            workflowConfig: workflow.workflowConfig,
            workflowSteps: workflow.workflowSteps,
            isEditing: workflow.isEditing,
            createdAt: workflow.createdAt,
            updatedAt: workflow.updatedAt,
          );
        });
  }

  Future<void> updateName(String name) async {
    final workflow = await _currentWorkflow();
    await dataConnector
        .updateWorkflowName(
          id: workflowId,
          teamId: workflow.teamId,
          name: name,
        )
        .execute();
  }

  Future<void> updateWorkflowConfig(WorkflowConfig config) async {
    final workflow = await _currentWorkflow();
    await dataConnector
        .updateWorkflowConfig(
          id: workflowId,
          teamId: workflow.teamId,
          workflowConfig: anyValue(config.toJson()),
        )
        .execute();
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

    await _updateSteps(workflow.teamId, steps);
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

    await _updateSteps(workflow.teamId, steps);
  }

  Future<void> deleteStep(int index) async {
    final workflow = await _currentWorkflow();
    final steps = List<WorkflowStep>.from(workflow.workflowSteps);
    if (index < 0 || index >= steps.length) return;

    steps.removeAt(index);

    await _updateSteps(workflow.teamId, steps);
  }

  Future<void> reorderSteps(int oldIndex, int newIndex) async {
    final workflow = await _currentWorkflow();
    final steps = List<WorkflowStep>.from(workflow.workflowSteps);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = steps.removeAt(oldIndex);
    steps.insert(newIndex, item);

    await _updateSteps(workflow.teamId, steps);
  }

  Future<Workflow> _currentWorkflow() async {
    final cached = state.value;
    if (cached != null) return cached;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    final result = await dataConnector
        .getWorkflow(id: workflowId, teamId: teamId)
        .execute();
    final workflow = result.data.workflow;
    if (workflow == null) throw Exception('Workflow not found');
    return workflowFromDataConnect(
      id: workflow.id,
      teamId: workflow.teamId,
      name: workflow.name,
      workflowConfig: workflow.workflowConfig,
      workflowSteps: workflow.workflowSteps,
      isEditing: workflow.isEditing,
      createdAt: workflow.createdAt,
      updatedAt: workflow.updatedAt,
    );
  }

  Future<void> _updateSteps(String teamId, List<WorkflowStep> steps) {
    return dataConnector
        .updateWorkflowSteps(
          id: workflowId,
          teamId: teamId,
          workflowSteps: anyValue(steps.map((step) => step.toJson()).toList()),
        )
        .execute();
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
