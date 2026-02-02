import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logs_provider.freezed.dart';
part 'logs_provider.g.dart';

@riverpod
Stream<List<BuildJob>> buildJobsList(Ref ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection(buildJobsCollection)
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => BuildJob.fromJson(doc.data())).toList(),
      );
}

@riverpod
Stream<List<BuildLog>> buildLogs(Ref ref, String buildJobId, String runId) {
  return FirebaseFirestore.instance
      .collection(buildJobsCollection)
      .doc(buildJobId)
      .collection('runs')
      .doc(runId)
      .collection('logs')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => BuildLog.fromJson(doc.data())).toList(),
      );
}

@freezed
abstract class BuildJob with _$BuildJob {
  const factory BuildJob({
    required String id,
    required String status,
    required String owner,
    required String repo,
    String? userId,
    String? commitSha,
    int? pullRequestNumber,
    int? runCount,
    String? latestRunId,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _BuildJob;

  factory BuildJob.fromJson(Map<String, Object?> json) =>
      _$BuildJobFromJson(json);
}

@freezed
abstract class BuildLog with _$BuildLog {
  const factory BuildLog({
    required String message,
    required String level,
    @TimestampConverter() DateTime? timestamp,
  }) = _BuildLog;

  factory BuildLog.fromJson(Map<String, Object?> json) =>
      _$BuildLogFromJson(json);
}
