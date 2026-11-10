import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/utilities/error_message.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/auth_provider.dart';
import '../connections/active_connection_firebase_auth.dart';
import '../connections/local_development_connection.dart';
import '../generated/teams/teams.dart';
import 'teams_connector_provider.dart';

final teamMembersApiProvider = FutureProvider<TeamMembersApi>((ref) async {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) throw DashboardException('team_access_denied');
  final auth = await ref.watch(activeConnectionFirebaseAuthProvider.future);
  final connector = await ref.watch(teamsConnectorProvider.future);
  final local = ref.watch(localDevelopmentConnectionProvider);
  bool isCurrent() => ref.mounted && auth.currentUser?.uid == user.uid;
  if (!isCurrent()) throw DashboardException('team_access_denied');
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
    if (!isCurrent()) throw DashboardException('team_access_denied');
  }

  Future<Map<String, dynamic>> _call(Map<String, dynamic> data) async {
    _requireCurrent();
    try {
      final response = await callable.call<Map<String, dynamic>>(data);
      _requireCurrent();
      if (response.data['success'] != true) throw const FormatException();
      return response.data;
    } on FirebaseFunctionsException catch (error) {
      throw DashboardException(switch (error.code) {
        'unauthenticated' || 'permission-denied' => 'team_access_denied',
        'already-exists' => 'member_already_added',
        'not-found' => 'member_not_registered',
        'invalid-argument' => 'invalid_email',
        'failed-precondition'
            when error.details is Map &&
                error.details['reason'] == 'email-not-verified' =>
          'member_email_not_verified',
        'failed-precondition' => 'member_unavailable',
        _ => 'team_operation_failed',
      });
    } catch (_) {
      _requireCurrent();
      throw DashboardException('team_operation_failed');
    }
  }

  Future<List<Map<String, dynamic>>> members(String teamId) async {
    final data = await _call({'action': 'members', 'teamId': teamId});
    try {
      return (data['members'] as List)
          .map((member) => Map<String, dynamic>.from(member as Map))
          .toList();
    } catch (_) {
      throw DashboardException('team_operation_failed');
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
      throw DashboardException('team_operation_failed');
    }
    _requireCurrent();
  }
}
