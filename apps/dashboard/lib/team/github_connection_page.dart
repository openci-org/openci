import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/team/current_github_connection_context_provider.dart';
import 'package:dashboard/team/fetch_github_connection_session.dart';
import 'package:dashboard/team/github_connection_context.dart';
import 'package:dashboard/team/github_connection_storage.dart';
import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:dashboard/team/pending_github_connection_return_provider.dart';
import 'package:dashboard/team/read_github_connection_reference.dart';
import 'package:dashboard/team/team_provider.dart';
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
    final session = useFuture(
      useMemoized(() => _loadSession(ref, result, initiatingContext)),
    );
    final error =
        session.error ??
        (initiatingContext != currentContext
            ? GitHubConnectionReturnError.forbidden
            : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.team.connectGitHub),
        leading: CloseButton(onPressed: () => context.go('/')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: session.connectionState != ConnectionState.done
              ? const CircularProgressIndicator.adaptive()
              : Text(
                  error == null
                      ? t.team.gitHubConnectionVerified
                      : _errorMessage(error),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }

  Future<GitHubConnectionSession> _loadSession(
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
      final session = await fetchGitHubConnectionSession(
        api: api,
        initiatingContext: initiatingContext,
        reference: reference,
      );
      _requireMatchingContext(ref, initiatingContext);
      return session;
    } on GitHubConnectionReturnError {
      rethrow;
    } catch (_) {
      throw GitHubConnectionReturnError.connectionFailed;
    }
  }

  Future<OpenCIApiService> _prepareClient(
    WidgetRef ref,
    GitHubConnectionContext initiatingContext,
  ) async {
    final store = ref.read(connectionStoreProvider);
    await ref.read(activeConnectionProfileProvider(store).future);
    if (!ref.context.mounted) throw GitHubConnectionReturnError.forbidden;
    await ref.read(selectedTeamProvider.future);
    _requireMatchingContext(ref, initiatingContext);
    return ref.read(openciApiServiceProvider.future);
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
