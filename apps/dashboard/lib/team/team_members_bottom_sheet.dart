import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/dart_function_urls.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

  final functions = FirebaseFunctions.instance;
  final result = await functions
      .httpsCallableFromUrl(dartFunctionUrl('get-team-members'))
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

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.group_outlined,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    teamT.members,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            teamT.membersCount(count: members.length),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.6),
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
              color: Colors.white.withValues(alpha: 0.06),
            ),
            // ── List ──
            Expanded(
              child: membersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final member = sorted[index];
                      final isCurrentUser = member.uid == currentUid;
                      final displayName = member.displayName;
                      final email = member.email ?? teamT.noEmail;

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
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
                                  color: const Color(0xFF252525),
                                  image: member.photoURL != null
                                      ? DecorationImage(
                                          image:
                                              NetworkImage(member.photoURL!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: member.photoURL == null
                                    ? Center(
                                        child: Text(
                                          _getInitials(
                                            displayName ?? email,
                                          ),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        if (isCurrentUser) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B82F6)
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color:
                                                    const Color(0xFF3B82F6)
                                                        .withValues(
                                                          alpha: 0.3,
                                                        ),
                                              ),
                                            ),
                                            child: Text(
                                              teamT.you,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF3B82F6),
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
                                          color: Colors.white.withValues(
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
