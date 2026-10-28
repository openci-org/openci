import 'dart:async';
import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
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

  Future<void> createTeam(String teamName) async {
    final apiService = await _ref.read(openciApiServiceProvider.future);
    final response = await apiService.createTeam({
      'name': teamName,
    });

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to create team: ${response.statusCode} ${response.error}',
      );
    }

    final data = response.body ?? <String, dynamic>{};
    final teamId = data['id'] as String;

    if (_ref.mounted) {
      _ref.invalidate(teamListProvider);
      await _ref
          .read(selectedTeamIdProvider.notifier)
          .saveSelectedTeamId(teamId);
    }
  }

  Future<void> updateTeamName(String teamId, String newName) async {
    final apiService = await _ref.read(openciApiServiceProvider.future);
    final response = await apiService.updateTeam(teamId, {
      'name': newName,
    });

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to update team name: ${response.statusCode} ${response.error}',
      );
    }

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
    final apiService = await _ref.read(openciApiServiceProvider.future);
    final response = await apiService.inviteMember(teamId, {
      'email': email,
    });

    if (!response.isSuccessful) {
      String errorMessage = 'Failed to invite member';
      try {
        final errorBody = response.error as Map<String, dynamic>?;
        errorMessage = errorBody?['error'] as String? ?? errorMessage;
      } catch (_) {
        final errString = response.error?.toString();
        if (errString != null && errString.isNotEmpty) {
          try {
            final parsed = jsonDecode(errString) as Map<String, dynamic>;
            errorMessage = parsed['error'] as String? ?? errorMessage;
          } catch (_) {}
        }
      }
      throw StateError(errorMessage);
    }
  }
}
