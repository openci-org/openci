import 'package:dashboard/firebase/dataconnect.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/workflow/dataconnect_workflow_mapper.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'workflow_list_provider.g.dart';

@riverpod
class WorkflowList extends _$WorkflowList {
  @override
  Stream<List<Workflow>> build() {
    final team = ref.watch(teamStateProvider).value;
    if (team == null) return Stream.value([]);
    return dataConnector
        .listWorkflowsForTeam(teamId: team.id)
        .ref()
        .subscribe()
        .map(
          (result) => result.data.workflows
              .map(
                (workflow) => workflowFromDataConnect(
                  id: workflow.id,
                  teamId: workflow.teamId,
                  name: workflow.name,
                  workflowConfig: workflow.workflowConfig,
                  workflowSteps: workflow.workflowSteps,
                  isEditing: workflow.isEditing,
                  createdAt: workflow.createdAt,
                  updatedAt: workflow.updatedAt,
                ),
              )
              .toList(),
        );
  }

  Future<String> duplicateWorkflow(Workflow workflow) async {
    final newId = const Uuid().v4();

    final duplicated = workflow.copyWith(
      documentId: newId,
      name: '${workflow.name} (Copy)',
      isEditing: false,
    );

    await dataConnector
        .createWorkflow(
          id: newId,
          teamId: workflow.teamId,
          name: duplicated.name,
          workflowConfig: anyValue(duplicated.workflowConfig.toJson()),
          workflowSteps: anyValue(
            duplicated.workflowSteps.map((step) => step.toJson()).toList(),
          ),
          isEditing: duplicated.isEditing,
        )
        .execute();
    return newId;
  }

  Future<void> deleteWorkflow(String workflowId) async {
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await dataConnector.deleteWorkflow(id: workflowId, teamId: teamId).execute();
  }
}
