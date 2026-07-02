import 'dart:async';
import 'dart:convert';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:openci_shared/openci_shared.dart';

part 'build_jobs_provider.g.dart';

const _buildJobsHistoryLimit = 100;

@Riverpod(keepAlive: true)
class BuildJobs extends _$BuildJobs {
  List<BuildJob>? _cache;

  @override
  Stream<List<BuildJob>> build() async* {
    final teamId = ref.watch(selectedTeamIdProvider).value;
    if (teamId == null) {
      _cache = null;
      yield const [];
      return;
    }

    final serverUrl = ref.watch(openciServerUrlProvider);
    final token = await ref.watch(authedFirebaseIdTokenProvider.future);

    final initialJobs = await _fetchBuildJobs(serverUrl, teamId, token);
    if (initialJobs != null) {
      _cache = initialJobs;
      yield initialJobs;
    } else {
      yield _cache ?? const [];
    }

    yield* Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final jobs = await _fetchBuildJobs(serverUrl, teamId, token);
      if (jobs != null) {
        _cache = jobs;
      }
      return _cache ?? const [];
    });
  }

  Future<List<BuildJob>?> _fetchBuildJobs(
    String serverUrl,
    String teamId,
    String token,
  ) async {
    try {
      final url = Uri.parse(
        '$serverUrl/builds?teamId=$teamId&limit=$_buildJobsHistoryLimit',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
          'Fetch build jobs failed with status: ${response.statusCode}',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['buildJobs'] as List<dynamic>;
      return items
          .map(
            (item) => BuildJob.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (e, s) {
      debugPrint('Error fetching build jobs: $e\n$s');
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
class OtaBuildJobs extends _$OtaBuildJobs {
  List<BuildJob>? _cache;

  @override
  Stream<List<BuildJob>> build() async* {
    final teamId = ref.watch(selectedTeamIdProvider).value;
    if (teamId == null) {
      _cache = null;
      yield const [];
      return;
    }

    final serverUrl = ref.watch(openciServerUrlProvider);
    final token = await ref.watch(authedFirebaseIdTokenProvider.future);

    final initialJobs = await _fetchOtaBuildJobs(serverUrl, teamId, token);
    if (initialJobs != null) {
      _cache = initialJobs;
      yield initialJobs;
    } else {
      yield _cache ?? const [];
    }

    yield* Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final jobs = await _fetchOtaBuildJobs(serverUrl, teamId, token);
      if (jobs != null) {
        _cache = jobs;
      }
      return _cache ?? const [];
    });
  }

  Future<List<BuildJob>?> _fetchOtaBuildJobs(
    String serverUrl,
    String teamId,
    String token,
  ) async {
    try {
      final url = Uri.parse(
        '$serverUrl/builds?teamId=$teamId&hasIpa=true&limit=100',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
          'Fetch ota build jobs failed with status: ${response.statusCode}',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['buildJobs'] as List<dynamic>;
      return items
          .map(
            (item) => BuildJob.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (e, s) {
      debugPrint('Error fetching ota build jobs: $e\n$s');
      return null;
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
  final token = await ref.watch(authedFirebaseIdTokenProvider.future);

  BuildJob? cache;

  Future<BuildJob?> fetchJob(String token) async {
    try {
      final url = Uri.parse('$serverUrl/builds/$buildJobId');

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint(
          'Fetch build job by id failed with status: ${response.statusCode}',
        );
        return cache;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final job = BuildJob.fromJson(data);
      if (job.teamId != null) {
        final selectedTeamId = ref.read(selectedTeamIdProvider).value;
        if (selectedTeamId != job.teamId) {
          unawaited(
            Future.microtask(() {
              ref
                  .read(selectedTeamIdProvider.notifier)
                  .saveSelectedTeamId(job.teamId!);
            }),
          );
        }
      }
      cache = job;
      return job;
    } catch (e, s) {
      debugPrint('Error fetching build job by id: $e\n$s');
      return cache;
    }
  }

  final initialJob = await fetchJob(token);
  yield initialJob;

  yield* Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
    return fetchJob(token);
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

Future<void> cancelBuildJob(
  OpenCiApiService apiService,
  String buildJobId,
) async {
  final response = await apiService.completeJob(buildJobId, {
    'status': BuildJobStatus.CANCELLED.name,
  });

  if (!response.isSuccessful) {
    throw Exception('Failed to cancel build job: ${response.error}');
  }
}

Future<void> retryBuildJob(
  OpenCiApiService apiService,
  String buildJobId,
) async {
  final response = await apiService.completeJob(buildJobId, {
    'status': BuildJobStatus.QUEUED.name,
    'failureSummary': null,
    'failureSummaryModel': null,
    'failureSummaryStatus': null,
    'failureSummaryDurationMs': null,
    'completedAt': null,
  });

  if (!response.isSuccessful) {
    throw Exception('Failed to retry build job: ${response.error}');
  }
}
