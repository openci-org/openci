import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'issue_board_ima_page.dart';

class IssueBoardBody extends ConsumerWidget {
  const IssueBoardBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final teamAsync = ref.watch(teamStateProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: asyncErrorWidget,
      data: (user) {
        final teamName = teamAsync.asData?.value.name;
        return IssueBoardPage(
          key: ValueKey(user.selectedTeamId),
          workspaceId: user.selectedTeamId,
          workspaceName: teamName ?? 'OpenCI team',
          onSwitchTeam: () => _showSwitchTeamBottomSheet(context),
        );
      },
    );
  }

  Future<void> _showSwitchTeamBottomSheet(BuildContext context) {
    return showTeamFlowModal(context);
  }
}
