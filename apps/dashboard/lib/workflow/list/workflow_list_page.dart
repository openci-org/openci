import 'package:dashboard/workspace/dashboard_shell.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WorkspacePage extends ConsumerWidget {
  const WorkspacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final teamAsync = ref.watch(teamStateProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, stackTrace) => asyncErrorWidget(error, stackTrace),
      data: (user) {
        final teamName = teamAsync.asData?.value.name;
        return DashboardShell(
          key: ValueKey(user.selectedTeamId),
          workspaceId: user.selectedTeamId,
          workspaceName: teamName ?? 'OpenCI team',
          onSwitchTeam: () => showTeamFlowModal(context),
        );
      },
    );
  }
}

