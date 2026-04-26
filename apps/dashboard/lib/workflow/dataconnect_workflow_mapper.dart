import 'package:dashboard/firebase/dataconnect.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';

Workflow workflowFromDataConnect({
  required String id,
  required String teamId,
  required String? name,
  required AnyValue? workflowConfig,
  required AnyValue? workflowSteps,
  required bool? isEditing,
  required Timestamp createdAt,
  required Timestamp updatedAt,
}) {
  final config = anyMap(workflowConfig);
  final steps = anyList(workflowSteps)
      .whereType<Map>()
      .map((step) => WorkflowStep.fromJson(step.cast<String, Object?>()))
      .toList();

  return Workflow(
    createdAt: dateTimeFromDataConnect(createdAt),
    updatedAt: dateTimeFromDataConnect(updatedAt),
    documentId: id,
    name: name ?? 'Untitled Workflow',
    teamId: teamId,
    workflowConfig: config.isEmpty
        ? const WorkflowConfig(
            selectedRepository: '',
            selectedWorkingDirectory: '',
          )
        : WorkflowConfig.fromJson(config),
    workflowSteps: steps,
    isEditing: isEditing ?? false,
  );
}
