import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/firebase/dart_function_urls.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class InviteTeamMemberBottomSheet extends HookConsumerWidget {
  const InviteTeamMemberBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final teamListAsync = ref.watch(teamListProvider);
    final selectedTeamId = useState<String?>(null);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final teamT = t.team;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  teamT.inviteTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              // ── Team selector ──
              teamListAsync.when(
                data: (teams) {
                  return Container(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text(
                            teamT.selectTeamLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.3),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
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
                            splashColor:
                                Colors.white.withValues(alpha: 0.05),
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
                                      color: selectedTeamId.value ==
                                              teams[i].id
                                          ? const Color(0xFF3B82F6)
                                              .withValues(alpha: 0.15)
                                          : const Color(0xFF252525),
                                      borderRadius:
                                          BorderRadius.circular(7),
                                    ),
                                    child: Center(
                                      child: Text(
                                        teams[i].name.isNotEmpty
                                            ? teams[i].name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: selectedTeamId.value ==
                                                  teams[i].id
                                              ? const Color(0xFF3B82F6)
                                              : Colors.white.withValues(
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
                                        fontWeight: selectedTeamId.value ==
                                                teams[i].id
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: selectedTeamId.value ==
                                                teams[i].id
                                            ? const Color(0xFF3B82F6)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (selectedTeamId.value == teams[i].id)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Color(0xFF3B82F6),
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
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: teamT.inviteEmail,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
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
                        color: Colors.white.withValues(alpha: 0.4),
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
                    foregroundColor: Colors.white,
                    backgroundColor: selectedTeamId.value != null
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withValues(alpha: 0.06),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: selectedTeamId.value == null
                          ? BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
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
                            final result = await FirebaseFunctions.instance
                                .httpsCallableFromUrl(
                                  dartFunctionUrl('invite-team-member'),
                                )
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
                          } on FirebaseFunctionsException catch (e) {
                            debugPrint(
                              'FirebaseFunctionsException: ${e.code} ${e.message}',
                            );
                            isLoading.value = false;
                            if (!context.mounted) return;
                            context.showSnackBarMessage(
                              e.message ??
                                  t.common.error(error: e.code),
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          t.common.invite,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selectedTeamId.value != null
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
