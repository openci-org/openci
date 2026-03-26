import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/firebase/functions_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_jobs_provider.freezed.dart';
part 'build_jobs_provider.g.dart';

@riverpod
class BuildJobs extends _$BuildJobs {
  @override
  Stream<List<BuildJob>> build() {
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
Future<String?> workflowName(Ref ref, String? workflowId) async {
  if (workflowId == null) return null;
  final firestore = ref.read(firestoreProvider);
  final doc = await firestore
      .collection(workflowsCollection)
      .doc(workflowId)
      .get();
  if (!doc.exists) return null;
  return doc.data()?['name'] as String?;
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
    String? commitSha,
    int? pullRequestNumber,
    int? runCount,
    String? latestRunId,
    String? tagName,
    String? branch,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _BuildJob;

  factory BuildJob.fromJson(Map<String, Object?> json) =>
      _$BuildJobFromJson(json);
}
