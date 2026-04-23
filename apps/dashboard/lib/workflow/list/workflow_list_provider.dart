import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
        .withConverter(
          fromFirestore: (snapshot, _) => Workflow.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots()
        .map((qs) => qs.docs.map((d) => d.data()).toList());
  }

  Future<String> duplicateWorkflow(Workflow workflow) async {
    final now = DateTime.now();
    final newDoc = firestore.collection(workflowsCollection).doc();

    final duplicated = workflow.copyWith(
      documentId: newDoc.id,
      name: '${workflow.name} (Copy)',
      createdAt: now,
      updatedAt: now,
      isEditing: false,
    );

    await newDoc.set(duplicated.toJson());
    return newDoc.id;
  }

  Future<void> deleteWorkflow(String workflowId) async {
    await firestore.collection(workflowsCollection).doc(workflowId).delete();
  }
}
