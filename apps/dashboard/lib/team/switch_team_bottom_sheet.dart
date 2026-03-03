import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SwitchTeamBottomSheet extends HookConsumerWidget {
  const SwitchTeamBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamListStream = ref.watch(teamListProvider);
    final formKey = useMemoized(() => GlobalKey<FormState>());

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
                            onTap: () async {
                              try {
                                // TODO(mafreud: fix this to use FDC
                                // await ref
                                //     .read(userProvider.notifier)
                                //     .updateSelectedTeamId(team.id);
                                if (!context.mounted) return;
                                context.showSnackBarMessage(
                                  'Team selected successfully',
                                );
                                Navigator.of(context).pop();
                              } catch (e) {
                                if (!context.mounted) return;
                                context.showSnackBarMessage(e.toString());
                              }
                            },
                          ),
                        );
                      }),
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
