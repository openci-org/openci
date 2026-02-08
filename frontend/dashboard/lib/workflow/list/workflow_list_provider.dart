import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workflow_list_provider.g.dart';

@riverpod
Stream<List<Workflow>> workflowList(Ref ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    throw Exception('User not logged in');
  }
  return ref
      .read(firestoreProvider)
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
