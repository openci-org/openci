import 'package:dashboard/app_strings.dart';
import 'package:dashboard/theme/app_colors.dart';

import 'package:dashboard/team/team_provider.dart';

import 'package:dashboard/users/user_provider.dart';

import 'package:dashboard/utilities/async_error_widget.dart';

import 'package:dashboard/utilities/snack_bar_extension.dart';

import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';


class SwitchTeamBottomSheet extends HookConsumerWidget {
  const SwitchTeamBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamListStream = ref.watch(teamListProvider);
    final currentTeam = ref.watch(teamStateProvider).value;
    final teamT = t.team;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                teamT.selectTeam,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ),
            teamListStream.when(
              data: (teams) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.of(context).surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.of(context).border,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < teams.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.of(context).divider,
                          ),
                        _TeamItem(
                          name: teams[i].name,
                          isSelected: teams[i].id == currentTeam?.id,
                          onTap: () async {
                            try {
                              await ref
                                  .read(userProvider.notifier)
                                  .updateSelectedTeamId(teams[i].id);
                              if (!context.mounted) return;
                              context.showSnackBarMessage(
                                teamT.selectedSuccess,
                              );
                              Navigator.of(context).pop();
                            } catch (e) {
                              if (!context.mounted) return;
                              context.showSnackBarMessage(e.toString());
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
              error: asyncErrorWidget,
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TeamItem extends StatelessWidget {
  const _TeamItem({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.of(context).borderSubtle,
      splashColor: AppColors.of(context).borderSubtle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.of(context).accent.withValues(alpha: 0.15)
                    : AppColors.of(context).surfaceTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.of(context).accent
                        : AppColors.of(context).textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected ? AppColors.of(context).accent : AppColors.of(context).textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.of(context).accent,
              ),
          ],
        ),
      ),
    );
  }
}
