import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'build_repository.dart';

export 'package:openci_shared/openci_shared.dart';

part 'build_jobs_provider.g.dart';

@riverpod
Stream<BuildJob?> buildJobById(Ref ref, String buildJobId) async* {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) {
    yield null;
    return;
  }
  final repository = await ref.watch(buildRepositoryProvider.future);
  var selectedInitialTeam = false;
  await for (final job in repository.watchJob(buildJobId)) {
    if (!ref.mounted) return;
    if (!selectedInitialTeam && job?.teamId != null) {
      selectedInitialTeam = true;
      final teamId = job!.teamId!;
      if (ref.read(selectedTeamIdProvider).value != teamId) {
        await ref
            .read(selectedTeamIdProvider.notifier)
            .saveSelectedTeamId(teamId);
      }
    }
    yield job;
  }
}
