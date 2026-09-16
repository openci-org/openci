import 'dart:async';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:openci_shared/openci_shared.dart';

part 'build_jobs_provider.g.dart';

@riverpod
Stream<BuildJob?> buildJobById(Ref ref, String buildJobId) async* {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.value == null) {
    yield null;
    return;
  }

  final api = ref.watch(openciApiServiceProvider);

  BuildJob? cache;

  Future<BuildJob?> fetchJob() async {
    try {
      final response = await api.getBuildJob(buildJobId);

      if (!response.isSuccessful || response.body == null) {
        debugPrint(
          'Fetch build job by id failed with status: ${response.statusCode}',
        );
        return cache;
      }

      final job = BuildJob.fromJson(response.body!);
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

  final initialJob = await fetchJob();
  yield initialJob;

  yield* Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
    return fetchJob();
  });
}
