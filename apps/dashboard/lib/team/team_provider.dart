import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

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
    final currentUserId = ref.watch(currentUserIdProvider);
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    final teamId = const Uuid().v4();
    final timestamp = FieldValue.serverTimestamp();
    final batch = firestore.batch();
    batch.set(firestore.collection(teamsCollection).doc(teamId), {
      'id': teamId,
      'name': teamName,
      'members': [currentUserId],
      'installationIds': <int>[],
      'aiEnabled': true,
      'createdAt': timestamp,
      'updatedAt': timestamp,
    });
    await batch.commit();
    await ref.read(selectedTeamIdProvider.notifier).saveSelectedTeamId(teamId);
  }

  Future<void> updateTeamName(String teamId, String newName) async {
    await firestore.collection(teamsCollection).doc(teamId).update({
      'name': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAiEnabled(String teamId, bool enabled) async {
    await firestore.collection(teamsCollection).doc(teamId).update({
      'aiEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGitHubSettings({
    required String teamId,
    String? githubBaseUrl,
    required List<int> installationIds,
  }) async {
    await firestore.collection(teamsCollection).doc(teamId).update({
      'githubBaseUrl': _emptyToNull(githubBaseUrl),
      'installationIds': installationIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTeam(String teamId) async {
    await firestore.collection(teamsCollection).doc(teamId).delete();
  }
}

String? _emptyToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
