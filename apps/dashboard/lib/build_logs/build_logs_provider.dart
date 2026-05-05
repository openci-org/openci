import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logs_provider.freezed.dart';
part 'logs_provider.g.dart';

@riverpod
Stream<List<BuildLog>> buildLogs(
  Ref ref,
  String buildJobId,
  String runId,
) async* {
  final teamId = ref.watch(teamStateProvider).value?.id;
  if (teamId == null) {
    yield const [];
    return;
  }
  final buildJob = await firestore
      .collection(buildJobsCollection)
      .doc(buildJobId)
      .get();
  if (buildJob.data()?['teamId'] != teamId) {
    yield const [];
    return;
  }

  yield* firestore
      .collection(buildJobsCollection)
      .doc(buildJobId)
      .collection('runs')
      .doc(runId)
      .collection('logs')
      .orderBy('timestamp')
      .limit(1000)
      .snapshots()
      .map((result) => _buildLogsFromDocs(result.docs));
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

List<BuildLog> _buildLogsFromDocs(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> logs,
) {
  return logs
      .map(
        (doc) => BuildLog(
          message: doc.data()['message'] as String? ?? '',
          level: doc.data()['level'] as String? ?? 'info',
          timestamp: dateTimeFromFirestore(doc.data()['timestamp']),
        ),
      )
      .toList();
}
