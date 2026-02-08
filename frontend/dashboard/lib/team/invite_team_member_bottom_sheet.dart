import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/firebase/functions_provider.dart';
import 'package:dashboard/team/team_provider.dart';
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                Text(
                  "Invite Team Member",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 40),
                teamListAsync.when(
                  data: (teams) => DropdownMenu<String>(
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Team'),
                    initialSelection: selectedTeamId.value,
                    onSelected: (value) => selectedTeamId.value = value,
                    dropdownMenuEntries: teams
                        .map(
                          (team) => DropdownMenuEntry(
                            value: team.id,
                            label: team.name,
                          ),
                        )
                        .toList(),
                  ),
                  error: (e, _) => Text('Error: $e'),
                  loading: () => const CircularProgressIndicator.adaptive(),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () async {
                    if (selectedTeamId.value == null ||
                        emailController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select a team and enter an email',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    try {
                      await ref
                          .read(functionsProvider)
                          .httpsCallable('inviteTeamMember')
                          .call({
                            'email': emailController.text.trim(),
                            'teamId': selectedTeamId.value,
                          });
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Team member invited successfully'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.of(context).pop();
                    } on FirebaseFunctionsException catch (e) {
                      debugPrint(
                        'FirebaseFunctionsException: ${e.code} ${e.message}',
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.message ?? 'An error occurred'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e, s) {
                      debugPrint(e.toString());
                      debugPrint(s.toString());

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Text("Invite"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
