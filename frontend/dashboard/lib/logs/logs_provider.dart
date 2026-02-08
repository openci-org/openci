import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logs_provider.freezed.dart';
part 'logs_provider.g.dart';

@riverpod
Stream<List<BuildJob>> buildJobsList(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  final teamId = ref.watch(teamStateProvider).requireValue.id;

  return firestore
      .collection(buildJobsCollection)
      .where('teamId', isEqualTo: teamId)
      .orderBy('createdAt', descending: true)
      .withConverter(
        fromFirestore: (snapshot, _) => BuildJob.fromJson(snapshot.data()!),
        toFirestore: (buildJob, _) => buildJob.toJson(),
      )
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
}

@riverpod
Stream<List<BuildLog>> buildLogs(Ref ref, String buildJobId, String runId) {
  final firestore = ref.read(firestoreProvider);

  return firestore
      .collection(buildJobsCollection)
      .doc(buildJobId)
      .collection('runs')
      .doc(runId)
      .collection('logs')
      .orderBy('timestamp', descending: false)
      .withConverter(
        fromFirestore: (snapshot, _) => BuildLog.fromJson(snapshot.data()!),
        toFirestore: (buildLog, _) => buildLog.toJson(),
      )
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
}

@freezed
abstract class BuildJob with _$BuildJob {
  const factory BuildJob({
    required String id,
    required String status,
    required String owner,
    required String repo,
    String? teamId,
    String? commitSha,
    int? pullRequestNumber,
    int? runCount,
    String? latestRunId,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _BuildJob;

  factory BuildJob.fromJson(Map<String, Object?> json) =>
      _$BuildJobFromJson(json);
}

@freezed
abstract class BuildLog with _$BuildLog {
  const factory BuildLog({
    required String message,
    required String level,
    @DateTimeConverter() DateTime? timestamp,
  }) = _BuildLog;

  factory BuildLog.fromJson(Map<String, Object?> json) =>
      _$BuildLogFromJson(json);
}
