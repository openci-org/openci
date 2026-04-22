import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/theme/app_colors.dart';

import 'package:dashboard/team/team_provider.dart';

import 'package:dashboard/utilities/async_error_widget.dart';

import 'package:dashboard/utilities/snack_bar_extension.dart';

import 'package:flutter/material.dart';

import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';


class EditTeamBottomSheet extends HookConsumerWidget {
  const EditTeamBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamListStream = ref.watch(teamListProvider);
    final teamNameController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final selectedTeamId = useState<String?>(null);
    final isLoading = useState(false);
    final teamT = t.team;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: teamListStream.when(
          data: (teams) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Text(
                    teamT.editTeam,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                ),
                // ── Team selector ──
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
                        InkWell(
                          onTap: () {
                            selectedTeamId.value = teams[i].id;
                            teamNameController.text = teams[i].name;
                          },
                          hoverColor: AppColors.of(context).borderSubtle,
                          splashColor: AppColors.of(context).borderSubtle,
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
                                        ? AppColors.of(context).accent
                                            .withValues(alpha: 0.15)
                                        : AppColors.of(context).surfaceTertiary,
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
                                                ? AppColors.of(context).accent
                                                : AppColors.of(context).textPrimary.withValues(
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
                                              ? AppColors.of(context).accent
                                              : AppColors.of(context).textPrimary,
                                    ),
                                  ),
                                ),
                                if (selectedTeamId.value == teams[i].id)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: AppColors.of(context).accent,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // ── Rename field ──
                if (selectedTeamId.value != null) ...[
                  const SizedBox(height: 16),
                  Form(
                    key: formKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.of(context).surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.of(context).border,
                        ),
                      ),
                      child: TextFormField(
                        controller: teamNameController,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.of(context).textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: teamT.newTeamName,
                          hintStyle: TextStyle(
                            color: AppColors.of(context).textTertiary,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Padding(
                            padding:
                                const EdgeInsets.only(left: 12, right: 8),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.of(context).textTertiary,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return teamT.enterTeamName;
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.of(context).textPrimary,
                        backgroundColor: AppColors.of(context).accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isLoading.value
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              isLoading.value = true;
                              try {
                                Navigator.of(context).pop();
                                await ref
                                    .read(teamListProvider.notifier)
                                    .updateTeamName(
                                      selectedTeamId.value!,
                                      teamNameController.text,
                                    );
                                if (!context.mounted) return;
                                context.showSnackBarMessage(
                                  teamT.updatedSuccess,
                                );
                              } catch (e) {
                                isLoading.value = false;
                                if (!context.mounted) return;
                                context.showSnackBarMessage(e.toString());
                              }
                            },
                      child: isLoading.value
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.of(context).textPrimary,
                              ),
                            )
                          : Text(
                              teamT.editTeam,
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
