import 'dart:async';
import 'dart:convert';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

export 'package:openci_shared/openci_shared.dart';

part 'build_jobs_provider.g.dart';

const _buildJobsHistoryLimit = 100;

@Riverpod(keepAlive: true)
class BuildJobs extends _$BuildJobs {
  @override
  Stream<List<BuildJob>> build() async* {
    final teamId = ref.watch(userProvider).value?.selectedTeamId;
    if (teamId == null) {
      yield const [];
      return;
    }

    final serverUrl = ref.watch(openciServerUrlProvider);

    yield await _fetchBuildJobs(serverUrl, teamId);

    yield* Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      return _fetchBuildJobs(serverUrl, teamId);
    });
  }

  Future<List<BuildJob>> _fetchBuildJobs(
    String serverUrl,
    String teamId,
  ) async {
    try {
      final url = Uri.parse(
        '$serverUrl/builds?teamId=$teamId&limit=$_buildJobsHistoryLimit',
      );
      final token = await ref.watch(firebaseIdTokenProvider.future);
      if (token == null) return const [];

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['buildJobs'] as List<dynamic>;
      return items
          .map(
            (item) => BuildJob.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (e, s) {
      debugPrint('Error fetching build jobs: $e\n$s');
      return const [];
    }
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
    await getCancelBuildJobCallable().call({
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

@Riverpod(keepAlive: true)
class OtaBuildJobs extends _$OtaBuildJobs {
  @override
  Stream<List<BuildJob>> build() async* {
    final teamId = ref.watch(userProvider).value?.selectedTeamId;
    if (teamId == null) {
      yield const [];
      return;
    }

    final serverUrl = ref.watch(openciServerUrlProvider);

    yield await _fetchOtaBuildJobs(serverUrl, teamId);

    yield* Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      return _fetchOtaBuildJobs(serverUrl, teamId);
    });
  }

  Future<List<BuildJob>> _fetchOtaBuildJobs(
    String serverUrl,
    String teamId,
  ) async {
    try {
      final url = Uri.parse(
        '$serverUrl/builds?teamId=$teamId&hasIpa=true&limit=100',
      );
      final token = await ref.watch(firebaseIdTokenProvider.future);
      if (token == null) return const [];

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['buildJobs'] as List<dynamic>;
      return items
          .map(
            (item) => BuildJob.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (e, s) {
      debugPrint('Error fetching ota build jobs: $e\n$s');
      return const [];
    }
  }
}

@riverpod
Stream<BuildJob?> buildJobById(Ref ref, String buildJobId) async* {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.value == null) {
    yield null;
    return;
  }

  final serverUrl = ref.watch(openciServerUrlProvider);

  Future<BuildJob?> fetchJob() async {
    try {
      final url = Uri.parse('$serverUrl/builds/$buildJobId');
      final token = await ref.watch(firebaseIdTokenProvider.future);
      if (token == null) return null;

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final job = BuildJob.fromJson(data);
      if (job.teamId != null) {
        final userAsync = ref.read(userProvider);
        userAsync.whenData((user) {
          if (user.selectedTeamId != job.teamId) {
            Future.microtask(() {
              ref.read(userProvider.notifier).updateSelectedTeamId(job.teamId!);
            });
          }
        });
      }
      return job;
    } catch (e, s) {
      debugPrint('Error fetching build job by id: $e\n$s');
      return null;
    }
  }

  yield await fetchJob();

  yield* Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
    return fetchJob();
  });
}

@riverpod
Stream<Duration?> runDuration(Ref ref, BuildJob buildJob) async* {
  Duration? calculate() {
    final completedAt = buildJob.completedAt;
    if (completedAt != null) {
      return _positiveDuration(buildJob.createdAt, completedAt);
    }
    if (buildJob.status == BuildJobStatus.IN_PROGRESS ||
        buildJob.status == BuildJobStatus.QUEUED) {
      return _positiveDuration(buildJob.createdAt, DateTime.now().toUtc());
    }
    return null;
  }

  yield calculate();

  if (buildJob.completedAt == null) {
    yield* Stream.periodic(const Duration(seconds: 1)).map((_) => calculate());
  }
}

Duration? _positiveDuration(DateTime startedAt, DateTime completedAt) {
  final duration = completedAt.difference(startedAt);
  if (duration.isNegative || duration.inSeconds == 0) return null;
  return duration;
}
