import 'package:dashboard/app_strings.dart';
import 'package:dashboard/team/create_team_bottom_sheet.dart';
import 'package:dashboard/team/delete_team_bottom_sheet.dart';
import 'package:dashboard/team/edit_team_bottom_sheet.dart';
import 'package:dashboard/team/invite_team_member_bottom_sheet.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/team_members_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/adaptive_modal.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class SwitchTeamBottomSheet extends HookConsumerWidget {
  const SwitchTeamBottomSheet({
    super.key,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final teamListStream = ref.watch(teamListProvider);
    final currentTeam = ref.watch(teamStateProvider).value;
    final teamT = t.team;
    final isMembersLoading = useState(false);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          teamListStream.when(
            data: (teams) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
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
                              color: Theme.of(context).dividerColor,
                            ),
                          _TeamItem(
                            name: teams[i].name,
                            isSelected: teams[i].id == currentTeam?.id,
                            onTap: isMembersLoading.value
                                ? null
                                : () async {
                                    try {
                                      await ref
                                          .read(selectedTeamIdProvider.notifier)
                                          .saveSelectedTeamId(teams[i].id);
                                      if (!context.mounted) return;
                                      context.showSnackBarMessage(
                                        teamT.selectedSuccess,
                                      );
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop();
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
                    isMembersLoading: isMembersLoading.value,
                    onMembers: () async {
                      isMembersLoading.value = true;
                      try {
                        ref.invalidate(teamMembersProvider);
                        await ref.read(teamMembersProvider.future);
                        if (context.mounted) {
                          onMembers();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          context.showSnackBarMessage(e.toString());
                        }
                      } finally {
                        isMembersLoading.value = false;
                      }
                    },
                    onInvite: onInvite,
                    onCreate: onCreate,
                    onEdit: onEdit,
                    onDelete: onDelete,
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
    );
  }
}

Future<void> showTeamFlowModal(BuildContext context) {
  final pageIndexNotifier = ValueNotifier<int>(0);
  final teamT = t.team;

  return WoltModalSheet.show<void>(
    context: context,
    pageIndexNotifier: pageIndexNotifier,
    pageListBuilder: (modalSheetContext) {
      final scaffoldBg = Theme.of(modalSheetContext).scaffoldBackgroundColor;
      return [
        // Page 0: チーム選択
        WoltModalSheetPage(
          backgroundColor: scaffoldBg,
          pageTitle: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
            child: Text(
              teamT.selectTeam,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child: SwitchTeamBottomSheet(
            onMembers: () => pageIndexNotifier.value = 1,
            onInvite: () => pageIndexNotifier.value = 2,
            onCreate: () => pageIndexNotifier.value = 3,
            onEdit: () => pageIndexNotifier.value = 4,
            onDelete: () => pageIndexNotifier.value = 5,
          ),
        ),
        // Page 1: メンバー一覧
        WoltModalSheetPage(
          backgroundColor: scaffoldBg,
          leadingNavBarWidget: BackButton(
            onPressed: () => pageIndexNotifier.value = 0,
          ),
          pageTitle: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
            child: Text(
              teamT.members,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child: const TeamMembersBottomSheet(),
        ),
        // Page 2: メンバー招待
        WoltModalSheetPage(
          backgroundColor: scaffoldBg,
          leadingNavBarWidget: BackButton(
            onPressed: () => pageIndexNotifier.value = 0,
          ),
          pageTitle: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
            child: Text(
              teamT.inviteTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child: const InviteTeamMemberBottomSheet(),
        ),
        // Page 3: チーム新規作成
        WoltModalSheetPage(
          backgroundColor: scaffoldBg,
          leadingNavBarWidget: BackButton(
            onPressed: () => pageIndexNotifier.value = 0,
          ),
          pageTitle: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
            child: Text(
              teamT.createTeam,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child: const CreateTeamBottomSheet(),
        ),
        // Page 4: チーム編集
        WoltModalSheetPage(
          backgroundColor: scaffoldBg,
          leadingNavBarWidget: BackButton(
            onPressed: () => pageIndexNotifier.value = 0,
          ),
          pageTitle: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
            child: Text(
              teamT.editTeam,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child: const EditTeamBottomSheet(),
        ),
        // Page 5: チーム削除
        WoltModalSheetPage(
          backgroundColor: scaffoldBg,
          leadingNavBarWidget: BackButton(
            onPressed: () => pageIndexNotifier.value = 0,
          ),
          pageTitle: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
            child: Text(
              teamT.deleteTeam,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child: const DeleteTeamBottomSheet(),
        ),
      ];
    },
    modalTypeBuilder: (context) {
      final usesBottomSheet = usesBottomSheetFormModal(context);
      return usesBottomSheet
          ? WoltModalType.bottomSheet()
          : WoltModalType.dialog();
    },
  );
}

class _TeamActions extends StatelessWidget {
  const _TeamActions({
    required this.onMembers,
    required this.onInvite,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.isMembersLoading,
  });

  final VoidCallback onMembers;
  final VoidCallback onInvite;
  final VoidCallback onCreate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isMembersLoading;

  @override
  Widget build(BuildContext context) {
    final teamT = t.team;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
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
                  onTap: isMembersLoading ? null : onMembers,
                  isLoading: isMembersLoading,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _TeamActionItem(
                  icon: Icons.person_add_alt_1_outlined,
                  label: t.common.invite,
                  onTap: isMembersLoading ? null : onInvite,
                ),
              ),
            ],
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),
          Row(
            children: [
              Expanded(
                child: _TeamActionItem(
                  icon: Icons.add_rounded,
                  label: teamT.createTeam,
                  onTap: isMembersLoading ? null : onCreate,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _TeamActionItem(
                  icon: Icons.edit_outlined,
                  label: teamT.editTeam,
                  onTap: isMembersLoading ? null : onEdit,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _TeamActionItem(
                  icon: Icons.delete_outline_rounded,
                  label: teamT.deleteTeam,
                  isDestructive: true,
                  onTap: isMembersLoading ? null : onDelete,
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
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isDestructive
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      hoverColor: onTap == null
          ? Colors.transparent
          : colorScheme.outlineVariant.withValues(alpha: 0.5),
      splashColor: onTap == null
          ? Colors.transparent
          : colorScheme.outlineVariant.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            else
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
        color: Theme.of(context).dividerColor,
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      hoverColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
      splashColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
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
                  color: isSelected ? colorScheme.primary : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
