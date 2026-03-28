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
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
    @DateTimeConverter() DateTime? completedAt,
  }) = _BuildJob;

  factory BuildJob.fromJson(Map<String, Object?> json) =>
      _$BuildJobFromJson(json);
}
