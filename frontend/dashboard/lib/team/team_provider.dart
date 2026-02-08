import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'team_provider.g.dart';

class Team {
  final String id;
  final String name;

  const Team({required this.id, required this.name});
}

const teamList = [
  Team(id: '1', name: 'Team A'),
  Team(id: '2', name: 'Team B'),
  Team(id: '3', name: 'Team C'),
  Team(id: '4', name: 'Team D'),
  Team(id: '5', name: 'Team E'),
  Team(id: '6', name: 'Team F'),
  Team(id: '7', name: 'Team G'),
  Team(id: '8', name: 'Team H'),
  Team(id: '9', name: 'Team I'),
  Team(id: '10', name: 'Team J'),
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

  Future<void> selectTeam(String teamId) async {
    // Call Firestore to update the selected team
  }
}
