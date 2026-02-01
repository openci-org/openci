import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workflow_list_provider.g.dart';

@riverpod
Stream<List<Workflow>> workflowList(Ref ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return Stream.value([]);
  }
  return FirebaseFirestore.instance
      .collection(workflowsCollection)
      .where('userId', isEqualTo: userId)
      .orderBy('updatedAt', descending: true)
      .withConverter(
        fromFirestore: (snapshot, _) => Workflow.fromJson(snapshot.data()!),
        toFirestore: (model, _) => model.toJson(),
      )
      .snapshots()
      .map((qs) => qs.docs.map((d) => d.data()).toList());
}
