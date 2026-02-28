import 'package:dashboard/workflow/mock_workflow_data.dart';
import 'package:dashboard/workflow/yaml_workflow.dart';
import 'package:dashboard/workflow/yaml_workflow_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yaml/yaml.dart';

part 'workflow_editor_provider.freezed.dart';
part 'workflow_editor_provider.g.dart';

@riverpod
class WorkflowEditor extends _$WorkflowEditor {
  @override
  Future<WorkflowEditorState> build(String workflowId) async {
    if (useMockData) {
      return getMockEditorState(workflowId);
    }

    throw UnimplementedError(
      'Loading workflow from GitHub API is not yet implemented. '
      'Workflow files are managed via .openci/ directory in the repository.',
    );
  }

  Future<void> updateYaml(String newYaml) async {
    if (useMockData) {
      YamlWorkflow? parsed;
      try {
        final yamlMap = loadYaml(newYaml);
        if (yamlMap is Map) {
          parsed = YamlWorkflowConverter.fromYamlMap(
            Map<String, dynamic>.from(yamlMap),
          );
        }
      } catch (_) {}

      final current = state.requireValue;
      state = AsyncData(
        current.copyWith(
          yamlRaw: newYaml,
          parsedWorkflow: parsed ?? current.parsedWorkflow,
          dbName: parsed?.name ?? current.dbName,
        ),
      );
      return;
    }

    throw UnimplementedError(
      'Saving workflow to GitHub API is not yet implemented.',
    );
  }

  Future<void> updateFromVisual(YamlWorkflow workflow) async {
    final yamlString = YamlWorkflowConverter.toYamlString(workflow);
    await updateYaml(yamlString);
  }

  Future<void> addStep(YamlWorkflowStep step, {int? insertAt}) async {
    final current = state.requireValue.parsedWorkflow;
    final steps = List<YamlWorkflowStep>.from(current.steps);
    if (insertAt != null && insertAt <= steps.length) {
      steps.insert(insertAt, step);
    } else {
      steps.add(step);
    }
    final updated = current.copyWith(steps: steps);
    await updateFromVisual(updated);
  }

  Future<void> removeStep(int index) async {
    final current = state.requireValue.parsedWorkflow;
    final steps = List<YamlWorkflowStep>.from(current.steps);
    if (index >= 0 && index < steps.length) {
      steps.removeAt(index);
    }
    final updated = current.copyWith(steps: steps);
    await updateFromVisual(updated);
  }

  Future<void> updateStep(int index, YamlWorkflowStep step) async {
    final current = state.requireValue.parsedWorkflow;
    final steps = List<YamlWorkflowStep>.from(current.steps);
    if (index >= 0 && index < steps.length) {
      steps[index] = step;
    }
    final updated = current.copyWith(steps: steps);
    await updateFromVisual(updated);
  }

  Future<void> reorderSteps(int oldIndex, int newIndex) async {
    final current = state.requireValue.parsedWorkflow;
    final steps = List<YamlWorkflowStep>.from(current.steps);
    if (newIndex > oldIndex) newIndex--;
    final item = steps.removeAt(oldIndex);
    steps.insert(newIndex, item);
    final updated = current.copyWith(steps: steps);
    await updateFromVisual(updated);
  }

  Future<void> updateTrigger(YamlWorkflowTrigger trigger) async {
    final current = state.requireValue.parsedWorkflow;
    final updated = current.copyWith(on: trigger);
    await updateFromVisual(updated);
  }

  Future<void> updateWorkflowName(String name) async {
    final current = state.requireValue.parsedWorkflow;
    final updated = current.copyWith(name: name);
    await updateFromVisual(updated);
  }
}

@freezed
abstract class WorkflowEditorState with _$WorkflowEditorState {
  const factory WorkflowEditorState({
    required String workflowId,
    required String orgId,
    required String dbName,
    required String yamlRaw,
    required YamlWorkflow parsedWorkflow,
    String? parseError,
    required String repository,
    required String branch,
    required String filePath,
    String? commitSha,
  }) = _WorkflowEditorState;
}
