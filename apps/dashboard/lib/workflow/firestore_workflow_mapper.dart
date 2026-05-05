import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/workflow/workflow.dart';

Workflow workflowFromFirestore({
  required String id,
  required Map<String, dynamic> data,
}) {
  final config = firestoreMap(data['workflowConfig']);
  final normalizedConfig = {
    'selectedRepository': '',
    'selectedWorkingDirectory': '',
    ...config,
  };
  final steps = firestoreList(data['workflowSteps'])
      .whereType<Map>()
      .map((step) => WorkflowStep.fromJson(step.cast<String, Object?>()))
      .toList();

  return Workflow(
    createdAt: dateTimeFromFirestore(data['createdAt']),
    updatedAt: dateTimeFromFirestore(data['updatedAt']),
    documentId: id,
    name: data['name'] as String? ?? 'Untitled Workflow',
    teamId: data['teamId'] as String? ?? '',
    workflowConfig: WorkflowConfig.fromJson(normalizedConfig),
    workflowSteps: steps,
    isEditing: data['isEditing'] as bool? ?? false,
  );
}
