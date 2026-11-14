import 'package:dashboard/app_strings.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

class CreateTeamBottomSheet extends HookConsumerWidget {
  const CreateTeamBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamId = useMemoized(() => const Uuid().v4());
    final nameController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final submission = useState<AsyncValue<void>>(const AsyncData(null));
    final strings = context.t.team;

    Future<void> submit() async {
      if (submission.value.isLoading || !formKey.currentState!.validate()) {
        return;
      }
      final retry = submission.value.hasError;
      submission.value = const AsyncLoading();
      final result = await AsyncValue.guard(
        () => ref
            .read(teamServiceProvider)
            .createTeam(
              id: teamId,
              name: nameController.text.trim(),
              retry: retry,
            ),
      );
      if (!context.mounted) return;
      submission.value = result;
      if (result.hasError) return;
      context.showSnackBarMessage(strings.createdSuccess);
      Navigator.of(context).pop();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: nameController,
              enabled: !submission.value.isLoading,
              decoration: InputDecoration(
                labelText: strings.teamName,
                prefixIcon: const Icon(Icons.group_add_outlined),
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? strings.enterTeamName
                  : null,
              onFieldSubmitted: (_) => submit(),
            ),
            if (submission.value.hasError) ...[
              const SizedBox(height: 8),
              Text(
                strings.operationFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: submission.value.isLoading ? null : submit,
              child: submission.value.isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.createTeam),
            ),
          ],
        ),
      ),
    );
  }
}
