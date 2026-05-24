import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'build_jobs_provider.freezed.dart';
part 'build_jobs_provider.g.dart';

const _buildJobsHistoryLimit = 100;

@riverpod
class BuildJobs extends _$BuildJobs {
  @override
  Stream<List<BuildJob>> build() async* {
    final teamId = ref.watch(userProvider).value?.selectedTeamId;
    if (teamId == null) {
      yield const [];
      return;
    }

    final query = firestore
        .collection(buildJobsCollection)
        .where('teamId', isEqualTo: teamId)
        .orderBy('createdAt', descending: true)
        .limit(_buildJobsHistoryLimit);

    final initialResult = await query.get();
    final initialJobs = _sortedBuildJobs(
      initialResult.docs.map((doc) => _buildJobFromData(doc.id, doc.data())),
    );
    yield initialJobs;

    yield* query.snapshots().map(
      (result) {
        final jobs = _sortedBuildJobs(
          result.docs.map((doc) => _buildJobFromData(doc.id, doc.data())),
        );
        return jobs;
      },
    );
  }

  Future<void> retryBuildJob(String buildJobId) async {
    final currentJobs = state.value;
    if (currentJobs == null) {
      throw StateError('Build jobs are not loaded yet');
    }
    final originalJob = currentJobs.firstWhere((j) => j.id == buildJobId);

    final newBuildJobId = const Uuid().v4();
    final now = DateTime.now().toUtc();

    final newJob = originalJob.copyWith(
      id: newBuildJobId,
      status: BuildJobStatus.QUEUED,
      runCount: 0,
      latestRunId: null,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
      failureSummary: null,
      failureSummaryModel: null,
      failureSummaryStatus: null,
      failureSummaryDurationMs: null,
    );

    try {
      // 1. Firestore にプレースホルダーを即座に作成
      await firestore
          .collection(buildJobsCollection)
          .doc(newBuildJobId)
          .set(newJob.toJson());

      // 2. Functions を呼び出す
      final functions = firebaseFunctions;
      await functions.httpsCallable('retryBuildJob').call(
        {
          'buildJobId': buildJobId,
          'newBuildJobId': newBuildJobId,
        },
      );
      ref.invalidateSelf();
    } catch (e, s) {
      debugPrint('Error in retryBuildJob: $e\n$s');
      // エラー時はロールバック
      try {
        await firestore
            .collection(buildJobsCollection)
            .doc(newBuildJobId)
            .delete();
      } catch (deleteError) {
        debugPrint('Failed to delete placeholder job: $deleteError');
      }
      rethrow;
    }
  }

  Future<void> cancelBuildJob(String buildJobId) async {
    final functions = firebaseFunctions;
    await functions.httpsCallable('cancelBuildJob').call({
      'buildJobId': buildJobId,
    });
    ref.invalidateSelf();
  }

  Future<void> retryWorkflowRun(
    String workflowRunId, {
    String? workflowFileName,
  }) async {
    final currentJobs = state.value;
    if (currentJobs == null) {
      throw StateError('Build jobs are not loaded yet');
    }
    var originalJobs = currentJobs
        .where((j) => j.workflowRunId == workflowRunId)
        .toList();
    if (workflowFileName != null) {
      originalJobs = originalJobs
          .where((j) => j.workflowFileName == workflowFileName)
          .toList();
    }

    if (originalJobs.isEmpty) return;

    final newWorkflowRunId = const Uuid().v4();
    final newJobDocIds = <String, String>{};
    for (final job in originalJobs) {
      if (job.jobKey != null) {
        newJobDocIds[job.jobKey!] = const Uuid().v4();
      }
    }

    final now = DateTime.now().toUtc();
    final batch = firestore.batch();
    final List<String> createdDocIds = [];

    try {
      for (final originalJob in originalJobs) {
        final jobKey = originalJob.jobKey;
        final newDocumentId = (jobKey != null)
            ? newJobDocIds[jobKey]!
            : const Uuid().v4();
        createdDocIds.add(newDocumentId);

        final originalNeeds = originalJob.needs;
        final hasNeeds = originalNeeds != null && originalNeeds.isNotEmpty;

        final newJob = originalJob.copyWith(
          id: newDocumentId,
          status: hasNeeds ? BuildJobStatus.WAITING : BuildJobStatus.QUEUED,
          workflowRunId: newWorkflowRunId,
          runCount: 0,
          latestRunId: null,
          createdAt: now,
          updatedAt: now,
          completedAt: null,
          failureSummary: null,
          failureSummaryModel: null,
          failureSummaryStatus: null,
          failureSummaryDurationMs: null,
        );

        batch.set(
          firestore.collection(buildJobsCollection).doc(newDocumentId),
          newJob.toJson(),
        );
      }

      // 1. Firestore に一括プレースホルダー作成
      await batch.commit();

      // 2. Functions を呼び出す
      final functions = firebaseFunctions;
      await functions.httpsCallable('retryWorkflowRun').call({
        'workflowRunId': workflowRunId,
        'newWorkflowRunId': newWorkflowRunId,
        'newJobDocIds': newJobDocIds,
        'workflowFileName': ?workflowFileName,
      });
      ref.invalidateSelf();
    } catch (e, s) {
      debugPrint('Error in retryWorkflowRun: $e\n$s');
      // エラー時は一括ロールバック
      try {
        final deleteBatch = firestore.batch();
        for (final docId in createdDocIds) {
          deleteBatch.delete(
            firestore.collection(buildJobsCollection).doc(docId),
          );
        }
        await deleteBatch.commit();
      } catch (deleteError) {
        debugPrint('Failed to delete placeholder workflow jobs: $deleteError');
      }
      rethrow;
    }
  }
}

@riverpod
Stream<BuildJob?> buildJobById(Ref ref, String buildJobId) async* {
  final teamId = ref.watch(userProvider).value?.selectedTeamId;
  if (teamId == null) {
    yield null;
    return;
  }
  yield* firestore
      .collection(buildJobsCollection)
      .doc(buildJobId)
      .snapshots()
      .map((snapshot) {
        final job = _buildJobFromSnapshot(snapshot);
        if (job?.teamId != teamId) return null;
        return job;
      });
}

@freezed
abstract class BuildJob with _$BuildJob {
  const BuildJob._();

  const factory BuildJob({
    required String id,
    required BuildJobStatus status,
    required String owner,
    required String repo,
    required String workflowName,
    String? teamId,
    String? workflowId,
    String? workflowFileName,
    String? commitSha,
    int? pullRequestNumber,
    int? runCount,
    String? latestRunId,
    String? tagName,
    String? branch,
    String? jobKey,
    String? workflowJobKey,
    Map<String, Object?>? matrix,
    String? matrixLabel,
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

  String? get displayMatrixLabel {
    if (matrixLabel != null && matrixLabel!.isNotEmpty) {
      return matrixLabel;
    }
    if (matrix == null || matrix!.isEmpty) {
      return null;
    }
    if (matrix!.containsKey('name') && matrix!['name'] is String) {
      return matrix!['name'] as String;
    }
    return matrix!.values.map((v) => v.toString()).join(' / ');
  }
}

@riverpod
Stream<Duration?> runDuration(Ref ref, BuildJob buildJob) {
  final runId = buildJob.latestRunId;
  if (runId == null) {
    return Stream.value(_durationFromBuildJob(buildJob));
  }

  return firestore
      .collection(buildJobsCollection)
      .doc(buildJob.id)
      .collection('runs')
      .doc(runId)
      .snapshots()
      .map((snapshot) {
        final data = snapshot.data();
        final runStartedAt = _nullableDateTimeFromFirestore(data?['createdAt']);
        final runUpdatedAt = _nullableDateTimeFromFirestore(data?['updatedAt']);
        final runCompleted =
            data?['status'] == 'completed' || data?['conclusion'] != null;
        final runCompletedAt = runCompleted ? runUpdatedAt : null;
        final completedAt = runCompletedAt ?? buildJob.completedAt;
        if (runStartedAt != null && completedAt != null) {
          return _positiveDuration(runStartedAt, completedAt);
        }
        return _durationFromBuildJob(buildJob);
      });
}

DateTime? _nullableDateTimeFromFirestore(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Duration? _durationFromBuildJob(BuildJob buildJob) {
  final completedAt = buildJob.completedAt;
  if (completedAt == null) return null;
  return _positiveDuration(buildJob.createdAt, completedAt);
}

Duration? _positiveDuration(DateTime startedAt, DateTime completedAt) {
  final duration = completedAt.difference(startedAt);
  if (duration.isNegative || duration.inSeconds == 0) return null;
  return duration;
}

BuildJob? _buildJobFromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  if (data == null) return null;
  return _buildJobFromData(doc.id, data);
}

BuildJob _buildJobFromData(String id, Map<String, dynamic> job) {
  return BuildJob(
    id: id,
    status: buildJobStatusFromFirestore(job['status']),
    owner: job['owner'] as String? ?? '',
    repo: job['repo'] as String? ?? '',
    workflowName: job['workflowName'] as String,
    teamId: job['teamId'] as String?,
    workflowId: job['workflowId'] as String?,
    workflowFileName: job['workflowFileName'] as String?,
    commitSha: job['commitSha'] as String?,
    pullRequestNumber: job['pullRequestNumber'] as int?,
    runCount: job['runCount'] as int?,
    latestRunId: job['latestRunId'] as String?,
    tagName: job['tagName'] as String?,
    branch: job['branch'] as String?,
    jobKey: job['jobKey'] as String?,
    workflowJobKey: job['workflowJobKey'] as String?,
    matrix: (job['matrix'] as Map?)?.cast<String, Object?>(),
    matrixLabel: job['matrixLabel'] as String?,
    workflowRunId: job['workflowRunId'] as String?,
    needs: (job['needs'] as List?)?.whereType<String>().toList(),
    failureSummary: job['failureSummary'] as String?,
    failureSummaryModel: job['failureSummaryModel'] as String?,
    failureSummaryStatus: job['failureSummaryStatus'] as String?,
    failureSummaryDurationMs: job['failureSummaryDurationMs'] as int?,
    createdAt: dateTimeFromFirestore(job['createdAt']),
    updatedAt: dateTimeFromFirestore(job['updatedAt']),
    completedAt: job['completedAt'] == null
        ? null
        : dateTimeFromFirestore(job['completedAt']),
  );
}

List<BuildJob> _sortedBuildJobs(Iterable<BuildJob> jobs) {
  return jobs.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
