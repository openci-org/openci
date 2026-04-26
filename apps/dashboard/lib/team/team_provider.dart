import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/dataconnect.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

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
    return dataConnector.listMyTeams().ref().subscribe().map((result) {
      return result.data.teamMembers
          .map((membership) => membership.team)
          .map(
            (team) => Team(
              id: team.id,
              name: team.name,
              members: team.members ?? const [],
              installationIds: team.installationIds ?? const [],
              aiEnabled: team.aiEnabled ?? true,
              createdAt: dateTimeFromDataConnect(team.createdAt),
              updatedAt: dateTimeFromDataConnect(team.updatedAt),
            ),
          )
          .toList();
    });
  }

  Future<void> createTeam(String teamName) async {
    final auth = ref.read(authProvider);
    final currentUserId = auth.value?.uid;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    await dataConnector
        .createTeamForCurrentUser(
          id: const Uuid().v4(),
          name: teamName,
          userId: currentUserId,
        )
        .execute();
  }

  Future<void> updateTeamName(String teamId, String newName) async {
    await dataConnector.updateTeamName(teamId: teamId, name: newName).execute();
  }

  Future<void> updateAiEnabled(String teamId, bool enabled) async {
    await dataConnector
        .updateTeamAiEnabled(teamId: teamId, aiEnabled: enabled)
        .execute();
  }

  Future<void> deleteTeam(String teamId) async {
    await dataConnector.deleteTeam(teamId: teamId).execute();
  }
}
