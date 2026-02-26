import 'package:dashboard/supabase/supabase_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workflow_editor_provider.freezed.dart';
part 'workflow_editor_provider.g.dart';

@riverpod
class WorkflowEditor extends _$WorkflowEditor {
  @override
  Stream<Workflow> build(String workflowId) {
    final supabase = ref.watch(supabaseClientProvider);
    return supabase
        .from('workflows')
        .stream(primaryKey: ['id'])
        .eq('id', workflowId)
        .map((rows) {
          if (rows.isEmpty) throw Exception('Workflow not found');
          final row = rows.first;
          return Workflow(
            createdAt: DateTime.parse(row['created_at'] as String),
            updatedAt: DateTime.parse(row['updated_at'] as String),
            documentId: row['id'] as String,
            name: row['name'] as String,
            teamId: row['org_id'] as String? ?? '',
            workflowConfig: WorkflowConfig(
              selectedRepository: '',
              selectedWorkingDirectory: '',
              selectedTriggerType: TriggerType.push,
            ),
            workflowSteps: [],
            isEditing: false,
          );
        });
  }

  Future<void> updateName(String name) async {
    final supabase = ref.watch(supabaseClientProvider);
    await supabase
        .from('workflows')
        .update({'name': name})
        .eq('id', workflowId);
  }

  Future<void> updateWorkflowConfig(WorkflowConfig config) async {
    final supabase = ref.watch(supabaseClientProvider);
    await supabase
        .from('workflows')
        .update({'yaml_definition': ''})
        .eq('id', workflowId);
  }

  Future<void> updateWorkflowStep({
    required int index,
    required WorkflowStep step,
  }) async {
    // YAML-based workflows handle steps differently
  }

  Future<void> deleteStep(int index) async {
    // YAML-based workflows handle steps differently
  }

  Future<void> reorderSteps(int oldIndex, int newIndex) async {
    // YAML-based workflows handle steps differently
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
