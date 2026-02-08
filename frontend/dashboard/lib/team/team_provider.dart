import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
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
    return Stream.value(teamList.first);
  }
}

@riverpod
class TeamList extends _$TeamList {
  @override
  Stream<List<Team>> build() {
    return Stream.value(teamList);
  }

  Future<void> createTeam(String teamName) async {
    final firestore = ref.read(firestoreProvider);
    final auth = ref.read(authProvider);
    final currentUserId = auth.requireValue?.uid;
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
}
