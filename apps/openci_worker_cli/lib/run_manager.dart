import 'dart:async';

import 'package:dart_firebase_admin/firestore.dart';
import 'package:logging/logging.dart';
import 'package:openci_shared/firestore_paths.dart';
import 'package:openci_worker_cli/cloud_function_caller.dart';

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
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'status': 'in_progress',
        });

    await firestore.collection(buildJobsCollection).doc(buildJobId).update({
      'latestRunId': runId,
      'runCount': FieldValue.increment(1),
    });
  } catch (e) {
    _log.severe('Failed to initialize run: $e');
  }

  // Notify check run update (replaces onRunCreated Firestore trigger)
  unawaited(notifyCheckRunUpdate(buildJobId, 'in_progress'));

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
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
          'conclusion': ?conclusion,
        });
  } catch (e) {
    _log.severe('Failed to update run status: $e');
  }
}
