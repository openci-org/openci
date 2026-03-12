import 'package:dart_firebase_admin/firestore.dart';
import 'package:logging/logging.dart';
import 'package:openci_shared/firestore_paths.dart';

final _log = Logger('RunManager');

Future<String> initializeRun(
  Firestore firestore,
  String buildJobId,
) async {
  final runId = firestore
      .collection(buildJobsCollection)
      .doc(buildJobId)
      .collection('runs')
      .doc()
      .id;
  try {
    await firestore
        .collection(buildJobsCollection)
        .doc(buildJobId)
        .collection('runs')
        .doc(runId)
        .set({
          'id': runId,
          'createdAt': FieldValue.serverTimestamp,
          'status': 'in_progress',
        });

    await firestore.collection(buildJobsCollection).doc(buildJobId).update({
      'latestRunId': runId,
      'runCount': FieldValue.increment(1),
    });
  } catch (e) {
    _log.severe('Failed to initialize run: $e');
  }
  return runId;
}

Future<void> updateRunStatus(
  Firestore firestore,
  String buildJobId,
  String runId,
  String status, {
  String? conclusion,
}) async {
  try {
    await firestore
        .collection(buildJobsCollection)
        .doc(buildJobId)
        .collection('runs')
        .doc(runId)
        .update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp,
          'conclusion': ?conclusion,
        });
  } catch (e) {
    _log.severe('Failed to update run status: $e');
  }
}
