import 'package:dashboard/supabase/supabase_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:dashboard/workflow/list/git_context_provider.dart';
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
  Future<List<WorkflowListItem>> build() async {
    if (useMockData) {
      return getMockWorkflowList();
    }

    final supabase = ref.read(supabaseClientProvider);
    final team = ref.read(teamStateProvider).requireValue;
    final gitContext = ref.read(gitContextProvider);

    final installationRows = await supabase
        .from('integrations')
        .select('installation_id')
        .eq('team_id', team.id);

    if (installationRows.isEmpty) return [];

    final installationId = installationRows.first['installation_id'];

    final response = await supabase.functions.invoke(
      'github-proxy',
      body: {
        'action': 'list_workflow_files',
        'installation_id': installationId,
        'owner': gitContext.repository.split('/').first,
        'repo': gitContext.repository.split('/').last,
        'ref': gitContext.branch,
      },
    );

    if (response.status != 200) return [];

    final files = (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];
    final items = <WorkflowListItem>[];

    for (final file in files) {
      final filePath = file['path'] as String? ?? '';
      final content = file['content'] as String? ?? '';

      String name = filePath
          .split('/')
          .last
          .replaceAll('.yaml', '')
          .replaceAll('.yml', '');
      String triggerSummary = '';

      if (content.isNotEmpty) {
        try {
          final yamlMap = loadYaml(content);
          if (yamlMap is Map) {
            final parsed = YamlWorkflowConverter.fromYamlMap(
              Map<String, dynamic>.from(yamlMap),
            );
            name = parsed.name;
            triggerSummary = YamlWorkflowConverter.triggerSummary(parsed.on);
          }
        } catch (_) {}
      }

      final latestBuild = await supabase
          .from('builds')
          .select('id, status, created_at')
          .eq('team_id', team.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      items.add(
        WorkflowListItem(
          id: filePath,
          name: name,
          orgId: team.id,
          yamlDefinition: content,
          triggerSummary: triggerSummary,
          repository: gitContext.repository,
          branch: gitContext.branch,
          filePath: filePath,
          commitSha: gitContext.commitSha,
          lastBuildStatus: latestBuild?['status'] as String?,
          lastBuildAt: latestBuild != null
              ? DateTime.tryParse(
                  latestBuild['created_at'] as String? ?? '',
                )
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    return items;
  }

  Future<void> deleteWorkflow(String filePath) async {
    if (useMockData) return;
    throw UnimplementedError(
      'Deleting workflow files via GitHub API is not yet implemented',
    );
  }

  Future<String> duplicateWorkflow(WorkflowListItem workflow) async {
    if (useMockData) return 'mock-duplicated';
    throw UnimplementedError(
      'Duplicating workflow files via GitHub API is not yet implemented',
    );
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
