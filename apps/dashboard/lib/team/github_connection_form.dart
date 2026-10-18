import 'package:dashboard/app_strings.dart';
import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openci_shared/openci_shared.dart';

class GitHubConnectionForm extends HookWidget {
  const GitHubConnectionForm({
    super.key,
    required this.teamName,
    required this.candidates,
    required this.onConfirm,
  });

  final String teamName;
  final List<GitHubConnectionCandidate> candidates;
  final Future<void> Function(int installationId) onConfirm;

  @override
  Widget build(BuildContext context) {
    final selectedId = useState<int?>(null);
    final submission = useState<AsyncValue<void>>(const AsyncData(null));
    final isSubmitting = submission.value.isLoading;
    final restartRequired =
        submission.value.error == GitHubConnectionReturnError.forbidden;
    final enabled = !isSubmitting && !restartRequired;

    return RadioGroup<int>(
      groupValue: selectedId.value,
      onChanged: (value) => selectedId.value = value,
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(t.team.gitHubConnectionTeam(name: teamName)),
          const SizedBox(height: 8),
          Text(t.team.gitHubConnectionVerified),
          const SizedBox(height: 16),
          Text(t.team.gitHubConnectionCandidates),
          for (final candidate in candidates)
            RadioListTile<int>(
              value: candidate.installationId,
              enabled: enabled,
              title: Text(candidate.accountLogin),
              secondary: Icon(
                candidate.accountType == 'Organization'
                    ? Icons.business
                    : Icons.person_outline,
              ),
            ),
          if (submission.value.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                restartRequired
                    ? t.team.gitHubConnectionRestartRequired
                    : t.team.gitHubConnectionConfirmFailed,
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: enabled && selectedId.value != null
                ? () => _submit(context, selectedId.value!, submission)
                : null,
            child: Text(
              isSubmitting
                  ? t.team.gitHubConnectionConfirming
                  : t.team.gitHubConnectionConfirm,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    int installationId,
    ValueNotifier<AsyncValue<void>> submission,
  ) async {
    if (submission.value.isLoading) return;
    submission.value = const AsyncLoading();
    try {
      await onConfirm(installationId);
      if (context.mounted) submission.value = const AsyncData(null);
    } catch (error) {
      if (context.mounted) {
        submission.value = AsyncError(
          error == GitHubConnectionReturnError.forbidden
              ? GitHubConnectionReturnError.forbidden
              : GitHubConnectionReturnError.connectionFailed,
          StackTrace.empty,
        );
      }
    }
  }
}
