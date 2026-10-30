import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/build_logs/build_repository.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cicd_log_providers.g.dart';

@riverpod
class CicdCommitGroups extends _$CicdCommitGroups {
  @override
  Stream<List<CicdCommitGroup>> build() async* {
    final user = await ref.watch(authStateChangesProvider.future);
    final teamId = ref.watch(selectedTeamIdProvider).value;
    if (user == null || teamId == null || teamId.isEmpty) {
      yield [];
      return;
    }
    final repository = await ref.watch(buildRepositoryProvider.future);
    yield* repository.watchJobs(teamId).map(groupBuildJobsToCommitGroups);
  }
}
