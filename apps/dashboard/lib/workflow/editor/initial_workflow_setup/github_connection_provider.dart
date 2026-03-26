import 'package:dashboard/team/team_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_connection_provider.g.dart';

@riverpod
bool isGitHubConnected(Ref ref) {
  final team = ref.watch(teamStateProvider).value;
  if (team == null) return false;
  return team.installationIds.isNotEmpty;
}
