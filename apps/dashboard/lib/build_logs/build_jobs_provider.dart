import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/firebase/functions_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yaml/yaml.dart';

part 'build_jobs_provider.freezed.dart';
part 'build_jobs_provider.g.dart';

@riverpod
class BuildJobs extends _$BuildJobs {
  @override
  Stream<List<BuildJob>> build() {
    final firestore = ref.watch(firestoreProvider);
    final teamId = ref.watch(teamStateProvider).value?.id;
    if (teamId == null) return Stream.value([]);

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

  Future<void> retryBuildJob(String buildJobId) async {
    final functions = ref.watch(functionsProvider);
    await functions.httpsCallable(retryBuildJobFunction).call({
      'buildJobId': buildJobId,
    });
  }

  Future<void> cancelBuildJob(String buildJobId) async {
    final functions = ref.watch(functionsProvider);
    await functions.httpsCallable(cancelBuildJobFunction).call({
      'buildJobId': buildJobId,
    });
  }
}

@riverpod
Stream<BuildJob?> buildJobById(Ref ref, String buildJobId) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection(buildJobsCollection)
      .doc(buildJobId)
      .withConverter(
        fromFirestore: (snapshot, _) => BuildJob.fromJson(snapshot.data()!),
        toFirestore: (buildJob, _) => buildJob.toJson(),
      )
      .snapshots()
      .map((snapshot) => snapshot.data());
}

@riverpod
Future<String?> workflowName(Ref ref, BuildJob buildJob) async {
  final fileName = buildJob.workflowFileName;
  if (fileName == null) return null;

  final teamId = buildJob.teamId;
  if (teamId == null) return null;

  final repo = '${buildJob.owner}/${buildJob.repo}';
  final firestore = ref.read(firestoreProvider);

  final qs = await firestore
      .collection(workflowFilesCollection)
      .where('teamId', isEqualTo: teamId)
      .where('repository', isEqualTo: repo)
      .where('fileName', isEqualTo: fileName)
      .limit(1)
      .get();

  if (qs.docs.isEmpty) return null;

  final content = qs.docs.first.data()['content'] as String?;
  if (content == null) return null;

  final parsed = loadYaml(content);
  if (parsed is! Map) return null;
  return parsed['name'] as String?;
}

@freezed
abstract class BuildJob with _$BuildJob {
  const factory BuildJob({
    required String id,
    required String status,
    required String owner,
    required String repo,
    String? teamId,
    String? workflowId,
    String? workflowName,
    String? workflowFileName,
    String? commitSha,
    int? pullRequestNumber,
    int? runCount,
    String? latestRunId,
    String? tagName,
    String? branch,
    String? jobKey,
    String? workflowRunId,
    List<String>? needs,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
    @DateTimeConverter() DateTime? completedAt,
  }) = _BuildJob;

  factory BuildJob.fromJson(Map<String, Object?> json) =>
      _$BuildJobFromJson(json);
}

@riverpod
Stream<Duration?> runDuration(Ref ref, BuildJob buildJob) {
  final runId = buildJob.latestRunId;
  if (runId == null) return Stream.value(null);

  final firestore = ref.read(firestoreProvider);
  return firestore
      .collection(buildJobsCollection)
      .doc(buildJob.id)
      .collection('runs')
      .doc(runId)
      .snapshots()
      .map((snapshot) {
        final data = snapshot.data();
        if (data == null) return null;

        final status = data['status'] as String?;
        if (status != 'completed') return null;

        final createdAtRaw = data['createdAt'];
        final updatedAtRaw = data['updatedAt'];
        if (createdAtRaw == null || updatedAtRaw == null) return null;

        final createdAt = _parseDateTime(createdAtRaw);
        final updatedAt = _parseDateTime(updatedAtRaw);
        if (createdAt == null || updatedAt == null) return null;

        return updatedAt.difference(createdAt);
      });
}

DateTime? _parseDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}
