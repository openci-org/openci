import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:dashboard/workflow/mock_workflow_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workflow_list_provider.freezed.dart';
part 'workflow_list_provider.g.dart';

@riverpod
class WorkflowList extends _$WorkflowList {
  @override
  FutureOr<List<WorkflowListItem>> build() {
    if (useMockData) {
      return getMockWorkflowList();
    }

    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
  }

  Future<void> duplicateWorkflow(WorkflowListItem workflow) async {
    if (useMockData) {
      final current = state.requireValue;
      final duplicate = workflow.copyWith(
        id: 'mock-wf-dup-${DateTime.now().millisecondsSinceEpoch}',
        name: '${workflow.name} (Copy)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      state = AsyncData([...current, duplicate]);
      return;
    }
    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
  }

  Future<void> deleteWorkflow(String workflowId) async {
    if (useMockData) {
      final current = state.requireValue;
      state = AsyncData(
        current.where((w) => w.id != workflowId).toList(),
      );
      return;
    }
    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
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
