import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SelectTeamBottomSheet extends HookConsumerWidget {
  const SelectTeamBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamList = ref.watch(teamListProvider);
    final teamNameController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());

    return teamList.when(
      data: (data) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Scrollbar(
              thumbVisibility: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Select a team',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...data.map((team) {
                          return Card(
                            child: ListTile(
                              title: Text(team.name),
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        const Text(
                          'Create New Team',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: teamNameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Team Name',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a team name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            try {
                              await ref
                                  .read(teamListProvider.notifier)
                                  .createTeam(teamNameController.text);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Team created successfully'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.of(context).pop();
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Create Team'),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      error: (error, stackTrace) => const Center(
        child: Text('Error'),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}
