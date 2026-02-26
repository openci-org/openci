import 'package:dashboard/supabase/supabase_provider.dart';
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
                    "Invite Team Member",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 40),
                  teamListAsync.when(
                    data: (teams) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Team',
                      ),
                      initialValue: selectedTeamId.value,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a team';
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
                    onPressed: selectedTeamId.value == null
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            try {
                              final supabase = ref.read(supabaseClientProvider);
                              await supabase.from('org_invitations').insert({
                                'org_id': selectedTeamId.value,
                                'invited_by': supabase.auth.currentUser!.id,
                                'email': emailController.text.trim(),
                                'role': 'member',
                              });
                              if (!context.mounted) return;
                              context.showSnackBarMessage(
                                'Team member invited successfully',
                              );
                              Navigator.of(context).pop();
                            } catch (e, s) {
                              debugPrint(e.toString());
                              debugPrint(s.toString());

                              if (!context.mounted) return;
                              context.showSnackBarMessage(e.toString());
                            }
                          },
                    child: Text("Invite"),
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
