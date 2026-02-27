import 'package:dashboard/supabase/supabase_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:dashboard/workflow/mock_workflow_data.dart';
import 'package:dashboard/workflow/yaml_workflow_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yaml/yaml.dart';

part 'workflow_list_provider.freezed.dart';
part 'workflow_list_provider.g.dart';

@riverpod
class WorkflowList extends _$WorkflowList {
  @override
  Stream<List<WorkflowListItem>> build() {
    if (useMockData) {
      return Stream.value(getMockWorkflowList());
    }

    final supabase = ref.read(supabaseClientProvider);

    return supabase
        .from('workflows')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .asyncMap((rows) async {
          final items = <WorkflowListItem>[];

          for (final row in rows) {
            final workflowId = row['id'] as String;
            final yamlRaw = row['yaml_definition'] as String? ?? '';

            String triggerSummary = '';
            String repository = '';
            if (yamlRaw.isNotEmpty) {
              try {
                final yamlMap = loadYaml(yamlRaw);
                if (yamlMap is Map) {
                  final parsed = YamlWorkflowConverter.fromYamlMap(
                    Map<String, dynamic>.from(yamlMap),
                  );
                  triggerSummary = YamlWorkflowConverter.triggerSummary(
                    parsed.on,
                  );
                }
              } catch (_) {}
            }

            final latestBuild = await supabase
                .from('builds')
                .select('id, status, created_at')
                .eq('org_id', row['org_id'] as String)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();

            items.add(
              WorkflowListItem(
                id: workflowId,
                name: row['name'] as String? ?? 'Untitled',
                orgId: row['org_id'] as String? ?? '',
                yamlDefinition: yamlRaw,
                triggerSummary: triggerSummary,
                repository: repository,
                lastBuildStatus: latestBuild?['status'] as String?,
                lastBuildAt: latestBuild != null
                    ? DateTime.tryParse(
                        latestBuild['created_at'] as String? ?? '',
                      )
                    : null,
                createdAt: DateTime.parse(row['created_at'] as String),
                updatedAt: DateTime.parse(row['updated_at'] as String),
              ),
            );
          }

          return items;
        });
  }

  Future<String> duplicateWorkflow(WorkflowListItem workflow) async {
    if (useMockData) return 'mock-duplicated';

    final supabase = ref.read(supabaseClientProvider);
    final row = await supabase
        .from('workflows')
        .insert({
          'org_id': workflow.orgId,
          'name': '${workflow.name} (Copy)',
          'yaml_definition': workflow.yamlDefinition,
        })
        .select()
        .single();
    return row['id'] as String;
  }

  Future<void> deleteWorkflow(String workflowId) async {
    if (useMockData) return;

    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('workflows').delete().eq('id', workflowId);
  }
}

@freezed
abstract class WorkflowListItem with _$WorkflowListItem {
  const factory WorkflowListItem({
    required String id,
    required String name,
    required String orgId,
    required String yamlDefinition,
    required String triggerSummary,
    required String repository,
    @Default('main') String branch,
    @Default('.openci/workflow.yaml') String filePath,
    String? commitSha,
    String? lastBuildStatus,
    DateTime? lastBuildAt,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _WorkflowListItem;

  factory WorkflowListItem.fromJson(Map<String, Object?> json) =>
      _$WorkflowListItemFromJson(json);
}
