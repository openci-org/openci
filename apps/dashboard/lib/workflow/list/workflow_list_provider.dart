import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/workflow/firestore_workflow_mapper.dart';
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
    return firestore
        .collection(workflowsCollection)
        .where('teamId', isEqualTo: team.id)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((result) => result.docs
            .map((doc) => workflowFromFirestore(id: doc.id, data: doc.data()))
            .toList());
  }

  Future<String> duplicateWorkflow(Workflow workflow) async {
    final newId = const Uuid().v4();

    final duplicated = workflow.copyWith(
      documentId: newId,
      name: '${workflow.name} (Copy)',
      isEditing: false,
    );

    final timestamp = FieldValue.serverTimestamp();
    await firestore.collection(workflowsCollection).doc(newId).set({
      'id': newId,
      'teamId': workflow.teamId,
      'name': duplicated.name,
      'workflowConfig': duplicated.workflowConfig.toJson(),
      'workflowSteps': duplicated.workflowSteps.map((step) => step.toJson()).toList(),
      'isEditing': duplicated.isEditing,
      'createdAt': timestamp,
      'updatedAt': timestamp,
    });
    return newId;
  }

  Future<void> deleteWorkflow(String workflowId) async {
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    final doc = firestore.collection(workflowsCollection).doc(workflowId);
    final snapshot = await doc.get();
    if (snapshot.data()?['teamId'] != teamId) return;
    await doc.delete();
  }
}
