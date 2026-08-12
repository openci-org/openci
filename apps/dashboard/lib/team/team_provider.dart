import 'dart:async';
import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/team/selected_team_provider.dart';
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
  final apiService = ref.watch(openciApiServiceProvider);
  final response = await apiService.getTeams();

  if (!response.isSuccessful) {
    throw StateError(
      'Failed to fetch teams: ${response.statusCode} ${response.error}',
    );
  }

  return response.body ?? const [];
}

@Riverpod(keepAlive: true)
TeamService teamService(Ref ref) => TeamService(ref);

class TeamService {
  final Ref _ref;
  TeamService(this._ref);

  Future<void> createTeam(String teamName) async {
    final apiService = _ref.read(openciApiServiceProvider);
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
    final apiService = _ref.read(openciApiServiceProvider);
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

  Future<void> updateGitHubSettings({
    required String teamId,
    String? githubBaseUrl,
    required List<int> installationIds,
  }) async {
    final apiService = _ref.read(openciApiServiceProvider);
    final response = await apiService.updateTeam(teamId, {
      'githubBaseUrl': _emptyToNull(githubBaseUrl),
      'installationIds': installationIds,
    });

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to update GitHub settings: ${response.statusCode} ${response.error}',
      );
    }

    if (_ref.mounted) {
      _ref.invalidate(teamListProvider);
    }
  }

  Future<void> deleteTeam(String teamId) async {
    final apiService = _ref.read(openciApiServiceProvider);
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
    final apiService = _ref.read(openciApiServiceProvider);
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

String? _emptyToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
