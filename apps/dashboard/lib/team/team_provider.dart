import 'dart:async';
import 'dart:convert';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
    final serverUrl = ref.watch(openciServerUrlProvider);
    final token = await ref.watch(authedFirebaseIdTokenProvider.future);

    final url = Uri.parse('$serverUrl/teams');
    final response = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to fetch teams: ${response.statusCode} ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((json) => Team.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<void> createTeam(String teamName) async {
    final serverUrl = ref.read(openciServerUrlProvider);
    final token = await ref.read(authedFirebaseIdTokenProvider.future);

    final url = Uri.parse('$serverUrl/teams');
    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name': teamName,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to create team: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final teamId = data['id'] as String;

    ref.invalidateSelf();
    await ref.read(selectedTeamIdProvider.notifier).saveSelectedTeamId(teamId);
  }

  Future<void> updateTeamName(String teamId, String newName) async {
    final serverUrl = ref.read(openciServerUrlProvider);
    final token = await ref.read(authedFirebaseIdTokenProvider.future);

    final url = Uri.parse('$serverUrl/teams/$teamId');
    final response = await http
        .patch(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name': newName,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to update team name: ${response.statusCode} ${response.body}',
      );
    }

    ref.invalidateSelf();
  }

  Future<void> updateGitHubSettings({
    required String teamId,
    String? githubBaseUrl,
    required List<int> installationIds,
  }) async {
    final serverUrl = ref.read(openciServerUrlProvider);
    final token = await ref.read(authedFirebaseIdTokenProvider.future);

    final url = Uri.parse('$serverUrl/teams/$teamId');
    final response = await http
        .patch(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'githubBaseUrl': _emptyToNull(githubBaseUrl),
            'installationIds': installationIds,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to update GitHub settings: ${response.statusCode} ${response.body}',
      );
    }

    ref.invalidateSelf();
  }

  Future<void> deleteTeam(String teamId) async {
    final serverUrl = ref.read(openciServerUrlProvider);
    final token = await ref.read(authedFirebaseIdTokenProvider.future);

    final url = Uri.parse('$serverUrl/teams/$teamId');
    final response = await http
        .delete(
          url,
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to delete team: ${response.statusCode} ${response.body}',
      );
    }

    ref.invalidateSelf();
  }
}

String? _emptyToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
