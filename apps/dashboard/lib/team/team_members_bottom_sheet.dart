import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openci_shared/callable_function_names.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'team_members_bottom_sheet.g.dart';

class TeamMember {
  const TeamMember({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      uid: map['uid'] as String,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      photoURL: map['photoURL'] as String?,
    );
  }
}

@riverpod
Future<List<TeamMember>> teamMembers(Ref ref) async {
  final team = ref.watch(teamStateProvider).value;
  if (team == null) return [];

  final result = await FirebaseFunctions.instanceFor(region: 'asia-northeast1')
      .httpsCallable(getTeamMembersFunction)
      .call<Map<String, dynamic>>({'teamId': team.id});

  final data = result.data;
  final membersList = (data['members'] as List<dynamic>?) ?? [];

  return membersList
      .map((m) => TeamMember.fromMap(Map<String, dynamic>.from(m as Map)))
      .toList();
}

class TeamMembersBottomSheet extends ConsumerWidget {
  const TeamMembersBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider);
    final currentUid = ref.watch(authProvider).value?.uid;
    final teamT = t.team;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.group_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    teamT.members,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  membersAsync.whenOrNull(
                        data: (members) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            teamT.membersCount(count: members.length),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ) ??
                      const SizedBox.shrink(),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            // List
            Expanded(
              child: membersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      e.toString(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (members) {
                  // Put current user first
                  final sorted = [...members]..sort((a, b) {
                      if (a.uid == currentUid) return -1;
                      if (b.uid == currentUid) return 1;
                      return 0;
                    });

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 72,
                      color:
                          colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final member = sorted[index];
                      final isCurrentUser = member.uid == currentUid;
                      final displayName = member.displayName;
                      final email = member.email ?? teamT.noEmail;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundImage: member.photoURL != null
                              ? NetworkImage(member.photoURL!)
                              : null,
                          backgroundColor:
                              colorScheme.primaryContainer.withValues(
                            alpha: 0.6,
                          ),
                          child: member.photoURL == null
                              ? Text(
                                  _getInitials(displayName ?? email),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName ?? email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
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
                                  color: colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  teamT.you,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: displayName != null
                            ? Text(
                                email,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'[\s@]+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}
