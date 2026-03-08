import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CreateTeamBottomSheet extends HookConsumerWidget {
  const CreateTeamBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamListStream = ref.watch(teamListProvider);
    final teamNameController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final teamT = t.team;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          child: teamListStream.when(
            data: (data) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Text(
                        teamT.createNewTeam,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: teamNameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: teamT.teamName,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return teamT.enterTeamName;
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
                            context.showSnackBarMessage(
                              teamT.createdSuccess,
                            );
                            Navigator.of(context).pop();
                          } catch (e) {
                            if (!context.mounted) return;
                            context.showSnackBarMessage(e.toString());
                          }
                        },
                        child: Text(teamT.createTeam),
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
