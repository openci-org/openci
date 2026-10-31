import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../app_strings.dart';
import '../auth/auth_provider.dart';
import '../connections/active_connection_firebase_auth.dart';
import '../connections/local_development_connection.dart';
import '../generated/teams/teams.dart';
import 'teams_connector_provider.dart';

final teamMembersApiProvider = FutureProvider<TeamMembersApi>((ref) async {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) throw StateError(t.team.accessDenied);
  final auth = await ref.watch(activeConnectionFirebaseAuthProvider.future);
  final connector = await ref.watch(teamsConnectorProvider.future);
  final local = ref.watch(localDevelopmentConnectionProvider);
  bool isCurrent() => ref.mounted && auth.currentUser?.uid == user.uid;
  if (!isCurrent()) throw StateError(t.team.accessDenied);
  final functions = FirebaseFunctions.instanceFor(
    app: auth.app,
    region: 'asia-northeast1',
  );
  if (local != null) {
    functions.useFunctionsEmulator(local.emulatorHost, 5001);
  }
  return TeamMembersApi(
    callable: functions.httpsCallable('teamManagement'),
    connector: connector,
    isCurrent: isCurrent,
  );
});

class TeamMembersApi {
  TeamMembersApi({
    required this.callable,
    required this.connector,
    required this.isCurrent,
  });
  final HttpsCallable callable;
  final TeamsConnector connector;
  final bool Function() isCurrent;

  void _requireCurrent() {
    if (!isCurrent()) throw StateError(t.team.accessDenied);
  }

  Future<Map<String, dynamic>> _call(Map<String, dynamic> data) async {
    _requireCurrent();
    try {
      final response = await callable.call<Map<String, dynamic>>(data);
      _requireCurrent();
      if (response.data['success'] != true) throw const FormatException();
      return response.data;
    } on FirebaseFunctionsException catch (error) {
      throw StateError(switch (error.code) {
        'unauthenticated' || 'permission-denied' => t.team.accessDenied,
        'already-exists' => t.team.memberAlreadyAdded,
        'not-found' => t.team.memberNotRegistered,
        'invalid-argument' => t.team.enterValidEmail,
        'failed-precondition'
            when error.details is Map &&
                error.details['reason'] == 'email-not-verified' =>
          t.team.memberEmailNotVerified,
        'failed-precondition' => t.team.memberUnavailable,
        _ => t.team.operationFailed,
      });
    } catch (_) {
      _requireCurrent();
      throw StateError(t.team.operationFailed);
    }
  }

  Future<List<Map<String, dynamic>>> members(String teamId) async {
    final data = await _call({'action': 'members', 'teamId': teamId});
    try {
      return (data['members'] as List)
          .map((member) => Map<String, dynamic>.from(member as Map))
          .toList();
    } catch (_) {
      throw StateError(t.team.operationFailed);
    }
  }

  Future<void> add(String teamId, String email) async {
    await _call({'action': 'add', 'teamId': teamId, 'email': email.trim()});
  }

  Future<void> remove(String teamId, String userId) async {
    _requireCurrent();
    try {
      await connector
          .removeTeamMember(teamId: teamId, userId: userId)
          .execute();
    } catch (_) {
      throw StateError(t.team.operationFailed);
    }
    _requireCurrent();
  }
}
