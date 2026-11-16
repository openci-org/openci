import 'package:dashboard/app_strings.dart';
import 'package:dashboard/team/github_connection_help.dart';
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
    required this.installationUrl,
    required this.onConfirm,
  });

  final String teamName;
  final List<GitHubConnectionCandidate> candidates;
  final String? installationUrl;
  final Future<void> Function(GitHubConnectionCandidate candidate) onConfirm;

  @override
  Widget build(BuildContext context) {
    final selectedId = useState<int?>(null);
    final isConnecting = useState(false);
    final submission = useState<AsyncValue<void>>(const AsyncData(null));
    final isSubmitting = submission.value.isLoading;
    final restartRequired =
        submission.value.error == GitHubConnectionReturnError.forbidden;
    final enabled = !isSubmitting && !isConnecting.value && !restartRequired;

    return RadioGroup<int>(
      groupValue: selectedId.value,
      onChanged: (value) => selectedId.value = value,
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(context.t.team.gitHubConnectionTeam(name: teamName)),
          const SizedBox(height: 8),
          Text(context.t.team.gitHubConnectionVerified),
          const SizedBox(height: 16),
          Text(context.t.team.gitHubConnectionCandidates),
          const SizedBox(height: 8),
          Text(context.t.team.gitHubConnectionAccountScope),
          for (final candidate in candidates)
            RadioListTile<int>(
              value: candidate.repositoryId,
              enabled: enabled,
              title: Text(
                [candidate.accountLogin, candidate.repositoryName].join('/'),
              ),
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
                    ? context.t.team.gitHubConnectionRestartRequired
                    : context.t.team.gitHubConnectionConfirmFailed,
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: enabled && selectedId.value != null
                ? () => _submit(
                    context,
                    candidates.firstWhere(
                      (candidate) => candidate.repositoryId == selectedId.value,
                    ),
                    submission,
                  )
                : null,
            child: Text(
              isSubmitting
                  ? context.t.team.gitHubConnectionConfirming
                  : context.t.team.gitHubConnectionConfirm,
            ),
          ),
          const SizedBox(height: 24),
          GitHubConnectionHelp(
            installationUrl: installationUrl,
            enabled: !isSubmitting && !isConnecting.value,
            onConnectingChanged: (value) => isConnecting.value = value,
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    GitHubConnectionCandidate candidate,
    ValueNotifier<AsyncValue<void>> submission,
  ) async {
    if (submission.value.isLoading) return;
    submission.value = const AsyncLoading();
    try {
      await onConfirm(candidate);
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
