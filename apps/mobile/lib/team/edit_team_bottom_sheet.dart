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
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Edit Team',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
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
                        onChanged: (value) {
                          selectedTeamId.value = value;
                          if (value != null) {
                            final team = teams.firstWhere(
                              (t) => t.id == value,
                            );
                            teamNameController.text = team.name;
                          }
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: teamNameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'New Team Name',
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
                        onPressed: selectedTeamId.value == null
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
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
                                    'Team name updated successfully',
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  context.showSnackBarMessage(e.toString());
                                }
                              },
                        child: const Text('Update Team Name'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
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
