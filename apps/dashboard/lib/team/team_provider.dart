import 'dart:async';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/team_members_api.dart';
import 'package:dashboard/team/teams_connector_provider.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:openci_shared/openci_shared.dart' show Team;

part 'team_provider.g.dart';

@riverpod
Future<Team> selectedTeam(Ref ref) async {
  final teamList = await ref.watch(teamListProvider.future);
  if (teamList.isEmpty) {
    throw StateError('No teams available');
  }
  final selectedTeamId = await ref.watch(selectedTeamIdProvider.future);
  return teamList.firstWhere(
    (team) => team.id == selectedTeamId,
    orElse: () => teamList.first,
  );
}

@riverpod
Future<List<Team>> teamList(Ref ref) async {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) return const [];

  final connector = await ref.watch(teamsConnectorProvider.future);
  final result = await connector.getMyTeams().execute();
  return result.data.teams
      .map(
        (team) => Team(
          id: team.id,
          name: team.name,
          members: team.members.map((member) => member.userId).toList(),
          runNumber: team.runNumber.toInt(),
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            team.createdAt.toInt() * 1000,
            isUtc: true,
          ),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            team.updatedAt.toInt() * 1000,
            isUtc: true,
          ),
        ),
      )
      .toList();
}

@Riverpod(keepAlive: true)
TeamService teamService(Ref ref) => TeamService(ref);

class TeamService {
  final Ref _ref;
  TeamService(this._ref);

  Future<void> createInitialTeam(String userId) async {
    final connector = await _ref.read(teamsConnectorProvider.future);
    await connector.createTeam(id: userId, name: userId).execute();

    if (_ref.mounted) {
      _ref.invalidate(teamListProvider);
      await _ref
          .read(selectedTeamIdProvider.notifier)
          .saveSelectedTeamId(userId);
    }
  }

  Future<void> updateTeamName(String teamId, String newName) async {
    final connector = await _ref.read(teamsConnectorProvider.future);
    await connector.renameTeam(teamId: teamId, name: newName).execute();

    if (_ref.mounted) {
      _ref.invalidate(teamListProvider);
    }
  }

  Future<void> deleteTeam(String teamId) async {
    final apiService = await _ref.read(openciApiServiceProvider.future);
    final response = await apiService.deleteTeam(teamId);

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to delete team: ${response.statusCode} ${response.error}',
      );
    }

    if (_ref.mounted) {
      _ref.invalidate(teamListProvider);
    }
  }

  Future<void> inviteMember(String teamId, String email) async {
    final api = await _ref.read(teamMembersApiProvider.future);
    await api.add(teamId, email);
    if (_ref.mounted) _ref.invalidate(teamListProvider);
  }
}
