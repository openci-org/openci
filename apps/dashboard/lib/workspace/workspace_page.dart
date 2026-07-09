import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/workspace/dashboard_shell.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WorkspacePage extends ConsumerWidget {
  const WorkspacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTeamIdAsync = ref.watch(selectedTeamIdProvider);
    final teamAsync = ref.watch(teamStateProvider);

    return selectedTeamIdAsync.when(
      data: (selectedTeamId) {
        if (selectedTeamId == null) {
          FirebaseAuth.instance.signOut();
          throw Exception("No team selected");
        }
        final teamName = teamAsync.asData?.value.name;
        return DashboardShell(
          key: ValueKey(selectedTeamId),
          workspaceId: selectedTeamId,
          workspaceName: teamName ?? 'OpenCI team',
          onSwitchTeam: () => showTeamFlowModal(context),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: asyncErrorWidget,
    );
  }
}
