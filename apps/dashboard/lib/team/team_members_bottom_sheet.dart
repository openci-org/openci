import 'dart:convert';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/utilities/openci_server_url_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  ref.keepAlive();
  final team = ref.watch(selectedTeamProvider).value;
  if (team == null) return [];

  final serverUrl = ref.watch(openciServerUrlProvider);
  final token = await ref.watch(authedFirebaseIdTokenProvider.future);

  final url = Uri.parse('$serverUrl/teams/${team.id}/members');
  final response = await http
      .get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      )
      .timeout(const Duration(seconds: 8));

  if (response.statusCode != 200) {
    throw StateError(
      'Failed to fetch team members: ${response.statusCode} ${response.body}',
    );
  }

  final Map<String, dynamic> data =
      jsonDecode(response.body) as Map<String, dynamic>;
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
            final email = member.email ?? teamT.noEmail;

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
                  ],
                ),
              ),
            );
          },
        );
      },
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
