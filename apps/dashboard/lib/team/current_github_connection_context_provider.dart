import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/team/github_connection_context.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentGitHubConnectionContextProvider =
    Provider.autoDispose<GitHubConnectionContext?>((ref) {
      final store = ref.watch(connectionStoreProvider);
      final profileState = ref.watch(activeConnectionProfileProvider(store));
      final teamState = ref.watch(selectedTeamProvider);
      final profile = profileState.asData?.value;
      final team = teamState.asData?.value;
      final userId = ref.watch(currentUserIdProvider);
      if (profileState.isLoading ||
          teamState.isLoading ||
          profile == null ||
          team == null ||
          userId == null) {
        return null;
      }
      return GitHubConnectionContext(
        profileId: profile.id,
        apiUrl: profile.apiUrl,
        userId: userId,
        teamId: team.id,
      );
    });
