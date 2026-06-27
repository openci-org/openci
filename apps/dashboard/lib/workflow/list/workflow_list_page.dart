import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/workspace/dashboard_shell.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WorkspacePage extends ConsumerWidget {
  const WorkspacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTeamId = ref.watch(selectedTeamIdProvider).value;
    final teamAsync = ref.watch(teamStateProvider);

    if (selectedTeamId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final teamName = teamAsync.asData?.value.name;
    return DashboardShell(
      key: ValueKey(selectedTeamId),
      workspaceId: selectedTeamId,
      workspaceName: teamName ?? 'OpenCI team',
      onSwitchTeam: () => showTeamFlowModal(context),
    );
  }
}
