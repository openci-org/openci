import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DeleteTeamBottomSheet extends HookConsumerWidget {
  const DeleteTeamBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamListStream = ref.watch(teamListProvider);
    final selectedTeamId = useState<String?>(null);
    final isDeleting = useState(false);
    final teamT = t.team;
    final commonT = t.common;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: teamListStream.when(
          data: (teams) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Text(
                    teamT.deleteTeam,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                // ── Team selector ──
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
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
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        InkWell(
                          onTap: () {
                            selectedTeamId.value = teams[i].id;
                          },
                          hoverColor: Colors.white.withValues(alpha: 0.03),
                          splashColor: Colors.white.withValues(alpha: 0.05),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: selectedTeamId.value == teams[i].id
                                        ? Colors.red.withValues(alpha: 0.15)
                                        : const Color(0xFF252525),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      teams[i].name.isNotEmpty
                                          ? teams[i].name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            selectedTeamId.value == teams[i].id
                                                ? Colors.red.withValues(
                                                    alpha: 0.9,
                                                  )
                                                : Colors.white.withValues(
                                                    alpha: 0.6,
                                                  ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    teams[i].name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          selectedTeamId.value == teams[i].id
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                      color:
                                          selectedTeamId.value == teams[i].id
                                              ? Colors.red.withValues(
                                                  alpha: 0.9,
                                                )
                                              : Colors.white,
                                    ),
                                  ),
                                ),
                                if (selectedTeamId.value == teams[i].id)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.red.withValues(alpha: 0.9),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // ── Warning + Delete button ──
                if (selectedTeamId.value != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.withValues(alpha: 0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            teamT.deleteTeamConfirm(
                              teamName: teams
                                  .firstWhere(
                                    (t) => t.id == selectedTeamId.value,
                                  )
                                  .name,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isDeleting.value
                          ? null
                          : () async {
                              if (teams.length <= 1) {
                                context.showSnackBarMessage(
                                  teamT.cannotDeleteLastTeam,
                                );
                                return;
                              }

                              isDeleting.value = true;
                              try {
                                final teamIdToDelete =
                                    selectedTeamId.value!;

                                final otherTeam = teams.firstWhere(
                                  (t) => t.id != teamIdToDelete,
                                );
                                await ref
                                    .read(userProvider.notifier)
                                    .updateSelectedTeamId(otherTeam.id);

                                await ref
                                    .read(teamListProvider.notifier)
                                    .deleteTeam(teamIdToDelete);

                                if (!context.mounted) return;
                                context.showSnackBarMessage(
                                  teamT.deletedSuccess,
                                );
                                Navigator.of(context).pop();
                              } catch (e) {
                                isDeleting.value = false;
                                if (!context.mounted) return;
                                context.showSnackBarMessage(e.toString());
                              }
                            },
                      child: isDeleting.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              commonT.delete,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            );
          },
          error: asyncErrorWidget,
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
    );
  }
}
