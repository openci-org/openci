import 'package:dashboard/app_strings.dart';
import 'package:dashboard/team/create_team_bottom_sheet.dart';
import 'package:dashboard/team/delete_team_bottom_sheet.dart';
import 'package:dashboard/team/edit_team_bottom_sheet.dart';
import 'package:dashboard/team/invite_team_member_bottom_sheet.dart';
import 'package:dashboard/team/team_members_bottom_sheet.dart';
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

    void openTeamSheet(Widget child, {bool isScrollControlled = true}) {
      final navigator = Navigator.of(context);
      navigator.pop();
      showModalBottomSheet<void>(
        showDragHandle: true,
        isScrollControlled: isScrollControlled,
        context: navigator.context,
        builder: (_) => child,
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
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
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
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
                    ),
                    const SizedBox(height: 12),
                    _TeamActions(
                      onMembers: () => openTeamSheet(
                        const TeamMembersBottomSheet(),
                        isScrollControlled: false,
                      ),
                      onInvite: () => openTeamSheet(
                        InviteTeamMemberBottomSheet(
                          initialTeamId: currentTeam?.id,
                        ),
                      ),
                      onCreate: () => openTeamSheet(
                        const CreateTeamBottomSheet(),
                      ),
                      onEdit: () => openTeamSheet(
                        const EditTeamBottomSheet(),
                      ),
                      onDelete: () => openTeamSheet(
                        const DeleteTeamBottomSheet(),
                      ),
                    ),
                  ],
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

class _TeamActions extends StatelessWidget {
  const _TeamActions({
    required this.onMembers,
    required this.onInvite,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onMembers;
  final VoidCallback onInvite;
  final VoidCallback onCreate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final teamT = t.team;

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
          Row(
            children: [
              Expanded(
                child: _TeamActionItem(
                  icon: Icons.group_outlined,
                  label: teamT.members,
                  onTap: onMembers,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _TeamActionItem(
                  icon: Icons.person_add_alt_1_outlined,
                  label: t.common.invite,
                  onTap: onInvite,
                ),
              ),
            ],
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.of(context).divider,
          ),
          Row(
            children: [
              Expanded(
                child: _TeamActionItem(
                  icon: Icons.add_rounded,
                  label: teamT.createTeam,
                  onTap: onCreate,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _TeamActionItem(
                  icon: Icons.edit_outlined,
                  label: teamT.editTeam,
                  onTap: onEdit,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _TeamActionItem(
                  icon: Icons.delete_outline_rounded,
                  label: teamT.deleteTeam,
                  isDestructive: true,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamActionItem extends StatelessWidget {
  const _TeamActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foreground = isDestructive
        ? AppColors.of(context).error
        : AppColors.of(context).textSecondary;

    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.of(context).borderSubtle,
      splashColor: AppColors.of(context).borderSubtle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: foreground,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: AppColors.of(context).divider,
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
                  color: isSelected
                      ? AppColors.of(context).accent
                      : AppColors.of(context).textPrimary,
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
