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
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          child: teamListStream.when(
            data: (teams) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      teamT.deleteTeam,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: teamT.selectTeamLabel,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedTeamId.value,
                          isExpanded: true,
                          isDense: true,
                          hint: Text(teamT.selectTeamLabel),
                          onChanged: (value) {
                            selectedTeamId.value = value;
                          },
                          items: teams
                              .map(
                                (team) => DropdownMenuItem(
                                  value: team.id,
                                  child: Text(team.name),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    if (selectedTeamId.value != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                teamT.deleteTeamConfirm(
                                  teamName: teams
                                      .firstWhere(
                                        (t) => t.id == selectedTeamId.value,
                                      )
                                      .name,
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.error,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      onPressed:
                          selectedTeamId.value == null || isDeleting.value
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
                                final teamIdToDelete = selectedTeamId.value!;

                                // Switch to another team before deleting
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
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onError,
                              ),
                            )
                          : Text(commonT.delete),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
            error: asyncErrorWidget,
            loading: () => Center(child: CircularProgressIndicator.adaptive()),
          ),
        ),
      ),
    );
  }
}
