import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/function_error_message.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class InviteTeamMemberBottomSheet extends HookConsumerWidget {
  const InviteTeamMemberBottomSheet({
    super.key,
    this.initialTeamId,
  });

  final String? initialTeamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final teamListAsync = ref.watch(teamListProvider);
    final currentSelectedTeamId = ref.watch(selectedTeamIdProvider).value;
    final selectedTeamId = useState<String?>(
      initialTeamId ?? currentSelectedTeamId,
    );
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final teamT = t.team;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // ── Team selector ──
            teamListAsync.when(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          teamT.selectTeamLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.of(context).textTertiary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
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
                          },
                          hoverColor: AppColors.of(context).borderSubtle,
                          splashColor: AppColors.of(context).borderSubtle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: selectedTeamId.value == teams[i].id
                                        ? AppColors.of(
                                            context,
                                          ).accent.withValues(alpha: 0.15)
                                        : AppColors.of(
                                            context,
                                          ).surfaceTertiary,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Center(
                                    child: Text(
                                      teams[i].name.isNotEmpty
                                          ? teams[i].name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            selectedTeamId.value == teams[i].id
                                            ? AppColors.of(context).accent
                                            : AppColors.of(
                                                context,
                                              ).textPrimary.withValues(
                                                alpha: 0.6,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    teams[i].name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          selectedTeamId.value == teams[i].id
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: selectedTeamId.value == teams[i].id
                                          ? AppColors.of(context).accent
                                          : AppColors.of(
                                              context,
                                            ).textPrimary,
                                    ),
                                  ),
                                ),
                                if (selectedTeamId.value == teams[i].id)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: AppColors.of(context).accent,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  t.common.error(error: e.toString()),
                  style: TextStyle(
                    color: Colors.red.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Email input ──
            Container(
              decoration: BoxDecoration(
                color: AppColors.of(context).surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.of(context).border,
                ),
              ),
              child: TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.of(context).textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: teamT.inviteEmail,
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
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      Icons.email_outlined,
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
                    return teamT.enterEmail;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            // ── Invite button ──
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: selectedTeamId.value != null
                      ? AppColors.of(context).accentOnAccent
                      : AppColors.of(context).textTertiary,
                  backgroundColor: selectedTeamId.value != null
                      ? AppColors.of(context).accent
                      : AppColors.of(context).divider,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: selectedTeamId.value == null
                        ? BorderSide(
                            color: AppColors.of(context).border,
                          )
                        : BorderSide.none,
                  ),
                ),
                onPressed: selectedTeamId.value == null || isLoading.value
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        isLoading.value = true;
                        try {
                          final result = await firebaseFunctions
                              .httpsCallable('inviteTeamMember')
                              .call({
                                'email': emailController.text.trim(),
                                'teamId': selectedTeamId.value,
                              });
                          if (!context.mounted) return;
                          final status =
                              (result.data as Map)['status'] as String?;
                          if (status == 'added') {
                            context.showSnackBarMessage(
                              teamT.addedSuccess,
                            );
                          } else {
                            context.showSnackBarMessage(
                              teamT.invitationSent,
                            );
                          }
                          Navigator.of(context).pop();
                        } on FirebaseFunctionsException catch (e, s) {
                          final errorMessage =
                              await FunctionErrorMessage.capture(
                                e,
                                stackTrace: s,
                              );
                          isLoading.value = false;
                          if (!context.mounted) return;
                          context.showSnackBarMessage(
                            errorMessage.message,
                          );
                        } catch (e, s) {
                          debugPrint(e.toString());
                          debugPrint(s.toString());
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
                          color: AppColors.of(context).accentOnAccent,
                        ),
                      )
                    : Text(
                        t.common.invite,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selectedTeamId.value != null
                              ? AppColors.of(context).accentOnAccent
                              : AppColors.of(context).textTertiary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
