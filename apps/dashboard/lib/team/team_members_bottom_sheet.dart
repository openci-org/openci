import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/team/team_members_api.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:skeletonizer/skeletonizer.dart';

part 'team_members_bottom_sheet.freezed.dart';
part 'team_members_bottom_sheet.g.dart';

@freezed
abstract class TeamMember with _$TeamMember {
  const factory TeamMember({
    required String uid,
    String? email,
    String? displayName,
    String? photoURL,
  }) = _TeamMember;

  factory TeamMember.fromMap(Map<String, dynamic> map) =>
      TeamMember.fromJson(map);

  factory TeamMember.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberFromJson(json);
}

@riverpod
Future<List<TeamMember>> teamMembers(Ref ref) async {
  ref.keepAlive();
  final team = ref.watch(selectedTeamProvider).value;
  if (team == null) return [];

  final api = await ref.watch(teamMembersApiProvider.future);
  final members = await api.members(team.id);
  return members.map(TeamMember.fromMap).toList();
}

class TeamMembersBottomSheet extends ConsumerWidget {
  const TeamMembersBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider);
    final currentUid = ref.watch(currentUserIdProvider);
    final teamT = t.team;
    final colorScheme = Theme.of(context).colorScheme;

    return membersAsync.when(
      loading: () => Skeletonizer(
        enabled: true,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: 3,
          separatorBuilder: (_, index) =>
              index == 0 ? const SizedBox.shrink() : const SizedBox(height: 2),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      child: const Text('3 members'),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 120,
                                height: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 180,
                            height: 12,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            e.toString(),
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.8),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (members) {
        final sorted = [...members]
          ..sort((a, b) {
            if (a.uid == currentUid) return -1;
            if (b.uid == currentUid) return 1;
            return 0;
          });

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: sorted.length + 1,
          separatorBuilder: (_, index) =>
              index == 0 ? const SizedBox.shrink() : const SizedBox(height: 2),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        teamT.membersCount(count: members.length),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final member = sorted[index - 1];
            final isCurrentUser = member.uid == currentUid;
            final displayName = member.displayName;
            final email = member.email ?? member.uid;

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: colorScheme.surfaceContainerHighest,
                        image: member.photoURL != null
                            ? DecorationImage(
                                image: NetworkImage(member.photoURL!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: member.photoURL == null
                          ? Center(
                              child: Text(
                                _getInitials(displayName ?? email),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName ?? email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    teamT.you,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (displayName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isCurrentUser)
                      IconButton(
                        tooltip: teamT.removeMember,
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () => _removeMember(context, ref, member),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    TeamMember member,
  ) async {
    final team = ref.read(selectedTeamProvider).value;
    if (team == null) return;
    try {
      // Capture the authenticated connection before the confirmation dialog.
      final api = await ref.read(teamMembersApiProvider.future);
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.team.removeMember),
          content: Text(
            t.team.removeMemberConfirm(
              name: member.email ?? member.displayName ?? member.uid,
              teamName: team.name,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t.common.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t.common.delete),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await api.remove(team.id, member.uid);
      if (!context.mounted) return;
      ref.invalidate(teamMembersProvider);
      ref.invalidate(teamListProvider);
      context.showSnackBarMessage(t.team.removedSuccess);
    } catch (_) {
      if (context.mounted) context.showSnackBarMessage(t.team.operationFailed);
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'[\s@]+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}
