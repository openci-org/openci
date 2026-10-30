import 'package:dashboard/app_strings.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/team/connect_github_button.dart';
import 'package:dashboard/team/current_github_connection_context_provider.dart';
import 'package:dashboard/team/fetch_github_connection_session.dart';
import 'package:dashboard/team/github_app_installation_link.dart';
import 'package:dashboard/team/github_connection_api.dart';
import 'package:dashboard/team/github_connection_context.dart';
import 'package:dashboard/team/github_connection_form.dart';
import 'package:dashboard/team/github_connection_storage.dart';
import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:dashboard/team/pending_github_connection_return_provider.dart';
import 'package:dashboard/team/read_github_connection_reference.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openci_shared/openci_shared.dart';

class GitHubConnectionPage extends HookConsumerWidget {
  const GitHubConnectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = useMemoized(
      () => ref.read(pendingGitHubConnectionReturnProvider).take(),
    );
    final initiatingContext = useMemoized(takeGitHubConnectionContext);
    final currentContext = ref.watch(currentGitHubConnectionContextProvider);
    final candidates = useFuture(
      useMemoized(() => _loadCandidates(ref, result, initiatingContext)),
    );
    final error =
        candidates.error ??
        (initiatingContext != currentContext
            ? GitHubConnectionReturnError.forbidden
            : null);
    final Widget content;
    if (candidates.connectionState != ConnectionState.done) {
      content = const CircularProgressIndicator.adaptive();
    } else if (error != null) {
      content = Text(_errorMessage(error), textAlign: TextAlign.center);
    } else if (candidates.requireData.candidates.isEmpty) {
      content = ListView(
        shrinkWrap: true,
        children: [
          Text(
            t.team.gitHubConnectionTeam(
              name: ref.watch(selectedTeamProvider).requireValue.name,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            t.team.gitHubConnectionNoCandidates,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GitHubAppInstallationLink(
            installationUrl: candidates.requireData.installationUrl,
          ),
          const SizedBox(height: 16),
          const ConnectGitHubButton(),
        ],
      );
    } else {
      content = GitHubConnectionForm(
        teamName: ref.watch(selectedTeamProvider).requireValue.name,
        candidates: candidates.requireData.candidates,
        onConfirm: (installationId) => _confirm(
          ref,
          initiatingContext!,
          result!.reference!,
          installationId,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.team.connectGitHub),
        leading: CloseButton(onPressed: () => context.go('/')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: content,
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(
    WidgetRef ref,
    GitHubConnectionContext initiatingContext,
    String reference,
    int installationId,
  ) async {
    final context = ref.context;
    final api = await _prepareClient(ref, initiatingContext);
    _requireMatchingContext(ref, initiatingContext);
    if (api.context != initiatingContext) {
      throw GitHubConnectionReturnError.forbidden;
    }
    await api.confirm(
      reference,
      installationId,
    );
    _requireMatchingContext(ref, initiatingContext);
    if (!context.mounted) return;
    ref.invalidate(teamListProvider);
    context.showSnackBarMessage(t.team.gitHubConnectionCompleted);
    context.go('/');
  }

  Future<GitHubConnectionCandidatesResult> _loadCandidates(
    WidgetRef ref,
    GitHubConnectionReturn? result,
    GitHubConnectionContext? initiatingContext,
  ) async {
    if (result?.error != null) throw result!.error!;
    if (result?.reference == null || initiatingContext == null) {
      throw GitHubConnectionReturnError.invalidResult;
    }
    try {
      final api = await _prepareClient(ref, initiatingContext);
      _requireMatchingContext(ref, initiatingContext);
      final reference = readGitHubConnectionReference(
        result: result,
        initiatingContext: initiatingContext,
        currentContext: ref.read(currentGitHubConnectionContextProvider),
      );
      await fetchGitHubConnectionSession(
        api: api,
        initiatingContext: initiatingContext,
        reference: reference,
      );
      _requireMatchingContext(ref, initiatingContext);
      final candidates = await _fetchCandidates(
        api,
        initiatingContext.teamId,
        reference,
      );
      _requireMatchingContext(ref, initiatingContext);
      return candidates;
    } on GitHubConnectionReturnError {
      rethrow;
    } catch (_) {
      throw GitHubConnectionReturnError.connectionFailed;
    }
  }

  Future<GitHubConnectionCandidatesResult> _fetchCandidates(
    GitHubConnectionApi api,
    String teamId,
    String reference,
  ) async {
    if (api.context.teamId != teamId) {
      throw GitHubConnectionReturnError.forbidden;
    }
    return api.candidates(reference);
  }

  Future<GitHubConnectionApi> _prepareClient(
    WidgetRef ref,
    GitHubConnectionContext initiatingContext,
  ) async {
    final store = ref.read(connectionStoreProvider);
    await ref.read(activeConnectionProfileProvider(store).future);
    if (!ref.context.mounted) throw GitHubConnectionReturnError.forbidden;
    await ref.read(selectedTeamProvider.future);
    _requireMatchingContext(ref, initiatingContext);
    return ref.read(githubConnectionApiProvider.future);
  }

  void _requireMatchingContext(
    WidgetRef ref,
    GitHubConnectionContext initiatingContext,
  ) {
    if (!ref.context.mounted ||
        ref.read(currentGitHubConnectionContextProvider) != initiatingContext) {
      throw GitHubConnectionReturnError.forbidden;
    }
  }

  String _errorMessage(Object? error) => switch (error) {
    GitHubConnectionReturnError.accessDenied =>
      t.team.gitHubConnectionCancelled,
    GitHubConnectionReturnError.connectionFailed =>
      t.team.gitHubConnectionCheckFailed,
    _ => t.team.gitHubConnectionRestartRequired,
  };
}
