import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TeamSwitchButton extends ConsumerWidget {
  const TeamSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamStateProvider);

    return teamAsync.maybeWhen(
      data: (team) => TextButton.icon(
        onPressed: () => showTeamFlowModal(context),
        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
        label: Text(
          team.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
