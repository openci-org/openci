import 'package:dashboard/firebase/dataconnect.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_jobs_provider.freezed.dart';
part 'build_jobs_provider.g.dart';

@riverpod
class BuildJobs extends _$BuildJobs {
  @override
  Stream<List<BuildJob>> build() async* {
    final teamId = ref.watch(userProvider).value?.selectedTeamId;
    if (teamId == null) {
      yield const [];
      return;
    }

    final query = dataConnector
        .listBuildJobsForTeam(teamId: teamId, limit: 20)
        .ref();

    final initialResult = await query.execute();
    final initialJobs = _sortedBuildJobs(
      initialResult.data.buildJobs.map(_buildJobFromList),
    );
    _debugBuildJobsResult('execute', teamId, initialJobs);
    yield initialJobs;

    yield* query.subscribe().map(
      (result) {
        final jobs = _sortedBuildJobs(
          result.data.buildJobs.map(_buildJobFromList),
        );
        _debugBuildJobsResult('subscribe', teamId, jobs);
        return jobs;
      },
    );
  }

  Future<void> retryBuildJob(String buildJobId) async {
    final functions = firebaseFunctions;
    await functions.httpsCallable('retryBuildJob').call(
      {
        'buildJobId': buildJobId,
      },
    );
    ref.invalidateSelf();
  }

  Future<void> cancelBuildJob(String buildJobId) async {
    final functions = firebaseFunctions;
    await functions.httpsCallable('cancelBuildJob').call({
      'buildJobId': buildJobId,
    });
    ref.invalidateSelf();
  }

  Future<void> retryWorkflowRun(String workflowRunId) async {
    final functions = firebaseFunctions;
    await functions.httpsCallable('retryWorkflowRun').call({
      'workflowRunId': workflowRunId,
    });
    ref.invalidateSelf();
  }
}

@riverpod
Stream<BuildJob?> buildJobById(Ref ref, String buildJobId) async* {
  final teamId = ref.watch(userProvider).value?.selectedTeamId;
  if (teamId == null) {
    yield null;
    return;
  }
  final query = dataConnector
      .getBuildJobForTeam(id: buildJobId, teamId: teamId)
      .ref();

  yield* query.subscribe().map(
    (result) => _buildJobFromTeamResult(result.data.buildJob),
  );
}

@riverpod
Future<String?> workflowName(Ref ref, BuildJob buildJob) async {
  return buildJob.workflowName;
}

@freezed
abstract class BuildJob with _$BuildJob {
  const factory BuildJob({
    required String id,
    required BuildJobStatus status,
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
    String? failureSummary,
    String? failureSummaryModel,
    String? failureSummaryStatus,
    int? failureSummaryDurationMs,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
    @DateTimeConverter() DateTime? completedAt,
  }) = _BuildJob;

  factory BuildJob.fromJson(Map<String, Object?> json) =>
      _$BuildJobFromJson(json);
}

@riverpod
Stream<Duration?> runDuration(Ref ref, BuildJob buildJob) {
  final completedAt = buildJob.completedAt;
  if (completedAt == null) return Stream.value(null);
  return Stream.value(completedAt.difference(buildJob.createdAt));
}

BuildJob _buildJobFromList(ListBuildJobsForTeamBuildJobs job) {
  return BuildJob(
    id: job.id,
    status: _knownBuildJobStatus(job.status),
    owner: job.owner,
    repo: job.repo,
    teamId: job.teamId,
    workflowId: job.workflowId,
    workflowName: job.workflowName,
    workflowFileName: job.workflowFileName,
    commitSha: job.commitSha,
    pullRequestNumber: job.pullRequestNumber,
    runCount: job.runCount,
    latestRunId: job.latestRunId,
    tagName: job.tagName,
    branch: job.branch,
    jobKey: job.jobKey,
    workflowRunId: job.workflowRunId,
    needs: job.needs,
    failureSummary: job.failureSummary,
    failureSummaryModel: job.failureSummaryModel,
    failureSummaryStatus: job.failureSummaryStatus,
    failureSummaryDurationMs: job.failureSummaryDurationMs,
    createdAt: dateTimeFromDataConnect(job.createdAt),
    updatedAt: dateTimeFromDataConnect(job.updatedAt),
    completedAt: job.completedAt == null
        ? null
        : dateTimeFromDataConnect(job.completedAt!),
  );
}

BuildJobStatus _knownBuildJobStatus(EnumValue<BuildJobStatus> status) {
  if (status is Known<BuildJobStatus>) {
    return status.value;
  }
  final legacyStatus = _legacyBuildJobStatusValues[status.stringValue];
  if (legacyStatus != null) {
    return legacyStatus;
  }
  throw StateError('Unknown BuildJobStatus: ${status.stringValue}');
}

const _legacyBuildJobStatusValues = {
  'waiting': BuildJobStatus.WAITING,
  'queued': BuildJobStatus.QUEUED,
  'in_progress': BuildJobStatus.IN_PROGRESS,
  'success': BuildJobStatus.SUCCESS,
  'failure': BuildJobStatus.FAILURE,
  'cancelled': BuildJobStatus.CANCELLED,
  'skipped': BuildJobStatus.SKIPPED,
  'timed_out': BuildJobStatus.TIMED_OUT,
};

List<BuildJob> _sortedBuildJobs(Iterable<BuildJob> jobs) {
  return jobs.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

void _debugBuildJobsResult(String source, String teamId, List<BuildJob> jobs) {
  if (!kDebugMode) return;
  final first = jobs.isEmpty ? null : jobs.first;
  debugPrint(
    '[OpenCI] ListBuildJobsForTeam $source teamId=$teamId '
    'count=${jobs.length} first=${first?.id} firstCreatedAt=${first?.createdAt.toIso8601String()}',
  );
}

BuildJob? _buildJobFromTeamResult(GetBuildJobForTeamBuildJob? job) {
  if (job == null) return null;
  return BuildJob(
    id: job.id,
    status: _knownBuildJobStatus(job.status),
    owner: job.owner,
    repo: job.repo,
    teamId: job.teamId,
    workflowId: job.workflowId,
    workflowName: job.workflowName,
    workflowFileName: job.workflowFileName,
    commitSha: job.commitSha,
    pullRequestNumber: job.pullRequestNumber,
    runCount: job.runCount,
    latestRunId: job.latestRunId,
    tagName: job.tagName,
    branch: job.branch,
    jobKey: job.jobKey,
    workflowRunId: job.workflowRunId,
    needs: job.needs,
    failureSummary: job.failureSummary,
    failureSummaryModel: job.failureSummaryModel,
    failureSummaryStatus: job.failureSummaryStatus,
    failureSummaryDurationMs: job.failureSummaryDurationMs,
    createdAt: dateTimeFromDataConnect(job.createdAt),
    updatedAt: dateTimeFromDataConnect(job.updatedAt),
    completedAt: job.completedAt == null
        ? null
        : dateTimeFromDataConnect(job.completedAt!),
  );
}
