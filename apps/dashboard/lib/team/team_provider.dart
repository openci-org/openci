import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/users/user_provider.dart';
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
    final user = ref.watch(userProvider).value;
    final teamList = ref.watch(teamListProvider).value;
    if (user == null || teamList == null) {
      return const Stream.empty();
    }
    if (teamList.isEmpty) {
      return const Stream.empty();
    }
    return Stream.value(
      teamList.firstWhere(
        (team) => team.id == user.selectedTeamId,
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
        'Timed out while loading teams from Firestore',
      ),
    );

    yield* watchTeamList();
  }

  Future<List<Team>> fetchTeamList() async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    final snapshot = await firestore
        .collection(teamsCollection)
        .where('members', arrayContains: currentUserId)
        .get();
    return _teamsFromDocs(snapshot.docs);
  }

  Stream<List<Team>> watchTeamList() {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) return Stream.value([]);
    return firestore
        .collection(teamsCollection)
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) => _teamsFromDocs(snapshot.docs));
  }

  Future<void> createTeam(String teamName) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
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
    batch.set(
      firestore.collection(usersCollection).doc(currentUserId),
      {
        'id': currentUserId,
        'email': auth.value?.email ?? '',
        'selectedTeamId': teamId,
        'updatedAt': timestamp,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
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
    String? githubApiBaseUrl,
    required List<int> installationIds,
  }) async {
    await firestore.collection(teamsCollection).doc(teamId).update({
      'githubBaseUrl': _emptyToNull(githubBaseUrl),
      'githubApiBaseUrl': _emptyToNull(githubApiBaseUrl),
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

List<Team> _teamsFromDocs(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  return docs.map((doc) {
    final data = doc.data();
    return Team(
      id: doc.id,
      name: data['name'] as String? ?? 'Untitled Team',
      members:
          (data['members'] as List?)?.whereType<String>().toList() ?? const [],
      installationIds:
          (data['installationIds'] as List?)?.whereType<int>().toList() ??
          const [],
      aiEnabled: data['aiEnabled'] as bool? ?? true,
      githubBaseUrl: data['githubBaseUrl'] as String?,
      githubApiBaseUrl: data['githubApiBaseUrl'] as String?,
      createdAt: dateTimeFromFirestore(data['createdAt']),
      updatedAt: dateTimeFromFirestore(data['updatedAt']),
    );
  }).toList();
}
