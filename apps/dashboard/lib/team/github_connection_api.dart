import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openci_shared/openci_shared.dart';

import '../connections/active_connection_firebase_auth.dart';
import '../connections/local_development_connection.dart';
import 'current_github_connection_context_provider.dart';
import 'github_connection_context.dart';
import 'parse_github_connection_return.dart';

final githubConnectionApiProvider = FutureProvider<GitHubConnectionApi>((
  ref,
) async {
  final context = ref.watch(currentGitHubConnectionContextProvider);
  if (context == null) throw GitHubConnectionReturnError.forbidden;
  final auth = await ref.watch(activeConnectionFirebaseAuthProvider.future);
  final local = ref.watch(localDevelopmentConnectionProvider);
  bool isCurrent() =>
      ref.mounted &&
      ref.read(currentGitHubConnectionContextProvider) == context &&
      auth.currentUser?.uid == context.userId;
  if (!isCurrent()) throw GitHubConnectionReturnError.forbidden;
  final functions = FirebaseFunctions.instanceFor(
    app: auth.app,
    region: 'asia-northeast1',
  );
  if (local != null) {
    functions.useFunctionsEmulator(local.emulatorHost, 5001);
  }
  return GitHubConnectionApi(
    context: context,
    callable: functions.httpsCallable(
      'githubConnection',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
    ),
    isCurrent: isCurrent,
  );
});

class GitHubConnectionApi {
  GitHubConnectionApi({
    required this.context,
    required this.callable,
    required this.isCurrent,
  });
  final GitHubConnectionContext context;
  final HttpsCallable callable;
  final bool Function() isCurrent;

  Future<Map<String, dynamic>> _call(
    String action, [
    Map<String, dynamic> data = const {},
  ]) async {
    try {
      if (!isCurrent()) throw GitHubConnectionReturnError.forbidden;
      final result = await callable.call<Map<String, dynamic>>({
        'action': action,
        'teamId': context.teamId,
        ...data,
      });
      if (!isCurrent()) throw GitHubConnectionReturnError.forbidden;
      if (result.data['success'] != true) {
        throw GitHubConnectionReturnError.connectionFailed;
      }
      return result.data;
    } on FirebaseFunctionsException catch (error) {
      if ([
        'unauthenticated',
        'permission-denied',
        'failed-precondition',
        'already-exists',
      ].contains(error.code)) {
        throw GitHubConnectionReturnError.forbidden;
      }
      throw GitHubConnectionReturnError.connectionFailed;
    } on GitHubConnectionReturnError {
      rethrow;
    } catch (_) {
      throw GitHubConnectionReturnError.connectionFailed;
    }
  }

  Future<Map<String, dynamic>> start() => _call('start');
  Future<GitHubConnectionSession> session(String reference) async =>
      GitHubConnectionSessionResult.fromJson(
        await _call('session', {'reference': reference}),
      ).session;
  Future<GitHubConnectionCandidatesResult> candidates(String reference) async =>
      GitHubConnectionCandidatesResult.fromJson(
        await _call('candidates', {'reference': reference}),
      );
  Future<void> confirm(String reference, int installationId) async {
    await _call('confirm', {
      'reference': reference,
      'installationId': installationId,
    });
  }
}
