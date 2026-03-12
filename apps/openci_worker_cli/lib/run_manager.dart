import 'package:dart_firebase_admin/firestore.dart';

class RunManager {
  final Firestore _firestore;
  final String _buildJobId;
  final String _runId;

  RunManager(this._firestore, this._buildJobId, this._runId);

  String get runId => _runId;

  Future<void> initialize() async {
    try {
      await _firestore
          .collection('build_jobs_v0')
          .doc(_buildJobId)
          .collection('runs')
          .doc(_runId)
          .set({
            'id': _runId,
            'createdAt': FieldValue.serverTimestamp,
            'status': 'in_progress',
          });

      await _firestore.collection('build_jobs_v0').doc(_buildJobId).update({
        'latestRunId': _runId,
        'runCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('[RunManager] Failed to initialize run: $e');
    }
  }

  Future<void> updateStatus(String status, {String? conclusion}) async {
    try {
      await _firestore
          .collection('build_jobs_v0')
          .doc(_buildJobId)
          .collection('runs')
          .doc(_runId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp,
            'conclusion': ?conclusion,
          });
    } catch (e) {
      print('[RunManager] Failed to update run status: $e');
    }
  }
}
