import 'package:dashboard/supabase/supabase_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workflow_list_provider.g.dart';

@riverpod
class WorkflowList extends _$WorkflowList {
  @override
  Stream<List<Workflow>> build() {
    final supabase = ref.read(supabaseClientProvider);

    return supabase
        .from('workflows')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((rows) {
          return rows
              .map(
                (row) => Workflow(
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
                ),
              )
              .toList();
        });
  }

  Future<String> duplicateWorkflow(Workflow workflow) async {
    final supabase = ref.read(supabaseClientProvider);
    final row = await supabase
        .from('workflows')
        .insert({
          'org_id': workflow.teamId,
          'name': '${workflow.name} (Copy)',
          'yaml_definition': '',
        })
        .select()
        .single();
    return row['id'] as String;
  }

  Future<void> deleteWorkflow(String workflowId) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('workflows').delete().eq('id', workflowId);
  }
}
