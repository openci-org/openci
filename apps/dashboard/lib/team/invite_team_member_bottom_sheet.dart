import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/functions_provider.dart';
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
    final teamT = t.team;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  Text(
                    teamT.inviteTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 40),
                  teamListAsync.when(
                    data: (teams) => DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: teamT.selectTeamLabel,
                      ),
                      initialValue: selectedTeamId.value,
                      validator: (value) {
                        if (value == null) {
                          return teamT.selectTeamValidation;
                        }
                        return null;
                      },
                      onChanged: (value) => selectedTeamId.value = value,
                      items: teams
                          .map(
                            (team) => DropdownMenuItem(
                              value: team.id,
                              child: Text(team.name),
                            ),
                          )
                          .toList(),
                    ),
                    error: (e, _) => Text(t.common.error(error: e.toString())),
                    loading: () => const CircularProgressIndicator.adaptive(),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: teamT.inviteEmail,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return teamT.enterEmail;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: selectedTeamId.value == null
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            try {
                              await ref
                                  .read(functionsProvider)
                                  .httpsCallable(inviteTeamMemberFunction)
                                  .call({
                                    'email': emailController.text.trim(),
                                    'teamId': selectedTeamId.value,
                                  });
                              if (!context.mounted) return;
                              context.showSnackBarMessage(
                                teamT.invitedSuccess,
                              );
                              Navigator.of(context).pop();
                            } on FirebaseFunctionsException catch (e) {
                              debugPrint(
                                'FirebaseFunctionsException: ${e.code} ${e.message}',
                              );
                              if (!context.mounted) return;
                              context.showSnackBarMessage(
                                e.message ?? t.common.error(error: e.code),
                              );
                            } catch (e, s) {
                              debugPrint(e.toString());
                              debugPrint(s.toString());

                              if (!context.mounted) return;
                              context.showSnackBarMessage(e.toString());
                            }
                          },
                    child: Text(t.common.invite),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
