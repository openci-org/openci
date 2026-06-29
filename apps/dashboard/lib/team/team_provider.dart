import 'dart:async';
import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:openci_shared/openci_shared.dart' show Team;

part 'team_provider.g.dart';

final teamList = [
  Team(
    id: '1',
    name: 'Team A',
    members: ['1'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Team(
    id: '2',
    name: 'Team B',
    members: ['2'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

@riverpod
class TeamState extends _$TeamState {
  @override
  Stream<Team> build() {
    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    final teamList = ref.watch(teamListProvider).value ?? [];
    if (teamList.isEmpty) {
      return const Stream.empty();
    }
    final targetId = selectedTeamId.value;
    return Stream.value(
      teamList.firstWhere(
        (team) => team.id == targetId,
        orElse: () => teamList.first,
      ),
    );
  }
}

@riverpod
class TeamList extends _$TeamList {
  @override
  Stream<List<Team>> build() async* {
    yield await fetchTeamList().timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException(
        'Timed out while loading teams from openci_server',
      ),
    );

    yield* Stream.periodic(const Duration(seconds: 15)).asyncMap((_) async {
      try {
        return await fetchTeamList();
      } catch (e) {
        debugPrint('Failed to poll teams: $e');
        return state.value ?? const [];
      }
    });
  }

  Future<List<Team>> fetchTeamList() async {
    final apiService = ref.watch(openciApiServiceProvider);
    final response = await apiService.getTeams();

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to fetch teams: ${response.statusCode} ${response.error}',
      );
    }

    return response.body ?? const [];
  }

  Future<void> createTeam(String teamName) async {
    final apiService = ref.read(openciApiServiceProvider);
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

    ref.invalidateSelf();
    await ref.read(selectedTeamIdProvider.notifier).saveSelectedTeamId(teamId);
  }

  Future<void> updateTeamName(String teamId, String newName) async {
    final apiService = ref.read(openciApiServiceProvider);
    final response = await apiService.updateTeam(teamId, {
      'name': newName,
    });

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to update team name: ${response.statusCode} ${response.error}',
      );
    }

    ref.invalidateSelf();
  }

  Future<void> updateGitHubSettings({
    required String teamId,
    String? githubBaseUrl,
    required List<int> installationIds,
  }) async {
    final apiService = ref.read(openciApiServiceProvider);
    final response = await apiService.updateTeam(teamId, {
      'githubBaseUrl': _emptyToNull(githubBaseUrl),
      'installationIds': installationIds,
    });

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to update GitHub settings: ${response.statusCode} ${response.error}',
      );
    }

    ref.invalidateSelf();
  }

  Future<void> deleteTeam(String teamId) async {
    final apiService = ref.read(openciApiServiceProvider);
    final response = await apiService.deleteTeam(teamId);

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to delete team: ${response.statusCode} ${response.error}',
      );
    }

    ref.invalidateSelf();
  }

  Future<void> inviteMember(String teamId, String email) async {
    final apiService = ref.read(openciApiServiceProvider);
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
