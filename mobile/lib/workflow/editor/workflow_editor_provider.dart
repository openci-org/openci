import 'package:dashboard/supabase/supabase_provider.dart';
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
  Stream<WorkflowEditorState> build(String workflowId) {
    if (useMockData) {
      return Stream.value(getMockEditorState(workflowId));
    }

    final supabase = ref.watch(supabaseClientProvider);
    return supabase
        .from('workflows')
        .stream(primaryKey: ['id'])
        .eq('id', workflowId)
        .map((rows) {
          if (rows.isEmpty) throw Exception('Workflow not found');
          final row = rows.first;
          final yamlRaw = row['yaml_definition'] as String? ?? '';

          YamlWorkflow? parsedWorkflow;
          String? parseError;

          if (yamlRaw.isNotEmpty) {
            try {
              final yamlMap = loadYaml(yamlRaw);
              if (yamlMap is Map) {
                parsedWorkflow = YamlWorkflowConverter.fromYamlMap(
                  Map<String, dynamic>.from(yamlMap),
                );
              }
            } catch (e) {
              parseError = e.toString();
            }
          }

          parsedWorkflow ??= YamlWorkflow(
            name: row['name'] as String? ?? 'Untitled',
            on: const YamlWorkflowTrigger(),
          );

          return WorkflowEditorState(
            workflowId: row['id'] as String,
            orgId: row['org_id'] as String? ?? '',
            dbName: row['name'] as String? ?? '',
            yamlRaw: yamlRaw,
            parsedWorkflow: parsedWorkflow,
            parseError: parseError,
            repository: row['github_repo'] as String? ?? '',
            branch: row['branch'] as String? ?? 'main',
            filePath: row['file_path'] as String? ?? '.openci/workflow.yaml',
            commitSha: row['commit_sha'] as String?,
          );
        });
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

    final supabase = ref.read(supabaseClientProvider);

    YamlWorkflow? parsed;
    try {
      final yamlMap = loadYaml(newYaml);
      if (yamlMap is Map) {
        parsed = YamlWorkflowConverter.fromYamlMap(
          Map<String, dynamic>.from(yamlMap),
        );
      }
    } catch (_) {}

    final name = parsed?.name ?? state.requireValue.dbName;

    await supabase
        .from('workflows')
        .update({
          'yaml_definition': newYaml,
          'name': name,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', workflowId);
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
