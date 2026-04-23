import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'team_provider.freezed.dart';
part 'team_provider.g.dart';

@freezed
abstract class Team with _$Team {
  const factory Team({
    required String id,
    required String name,
    required List<String> members,
    @Default([]) List<int> installationIds,
    @Default(1) int runNumber,
    @Default(true) bool aiEnabled,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _Team;

  factory Team.fromJson(Map<String, Object?> json) => _$TeamFromJson(json);
}

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
    return Stream.value(
      teamList.firstWhere((team) => team.id == user.selectedTeamId),
    );
  }
}

@riverpod
class TeamList extends _$TeamList {
  @override
  Stream<List<Team>> build() {
    return fetchTeamList();
  }

  Stream<List<Team>> fetchTeamList() {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    return firestore
        .collection(teamsCollection)
        .where('members', arrayContains: currentUserId)
        .withConverter(
          fromFirestore: (snapshot, _) => Team.fromJson(snapshot.data()!),
          toFirestore: (model, _) => model.toJson(),
        )
        .snapshots()
        .map((qs) => qs.docs.map((d) => d.data()).toList());
  }

  Future<void> createTeam(String teamName) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    final docRef = firestore.collection(teamsCollection).doc();
    await docRef.set(
      Team(
        id: docRef.id,
        name: teamName,
        members: [currentUserId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toJson(),
    );
  }

  Future<void> updateTeamName(String teamId, String newName) async {
    await firestore.collection(teamsCollection).doc(teamId).update({
      'name': newName,
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> updateAiEnabled(String teamId, bool enabled) async {
    await firestore.collection(teamsCollection).doc(teamId).update({
      'aiEnabled': enabled,
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> deleteTeam(String teamId) async {
    await firestore.collection(teamsCollection).doc(teamId).delete();
  }
}
