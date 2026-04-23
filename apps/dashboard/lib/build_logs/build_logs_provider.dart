import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logs_provider.freezed.dart';
part 'logs_provider.g.dart';

@riverpod
Stream<List<BuildLog>> buildLogs(Ref ref, String buildJobId, String runId) {
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
abstract class BuildLog with _$BuildLog {
  const factory BuildLog({
    required String message,
    required String level,
    @DateTimeConverter() DateTime? timestamp,
  }) = _BuildLog;

  factory BuildLog.fromJson(Map<String, Object?> json) =>
      _$BuildLogFromJson(json);
}
