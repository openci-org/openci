import 'package:dashboard/auth/auth_provider.dart';
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
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _Team;

  factory Team.fromJson(Map<String, Object?> json) => _$TeamFromJson(json);
}

@riverpod
class TeamState extends _$TeamState {
  @override
  Stream<Team> build() {
    final teamList = ref.watch(teamListProvider).requireValue;
    final auth = ref.read(authProvider.notifier);
    final currentUserId = auth.currentUserId;
    if (currentUserId == null || teamList.isEmpty) {
      throw Exception('User is not authenticated or has no teams');
    }
    return Stream.value(teamList.first);
  }
}

@riverpod
class TeamList extends _$TeamList {
  @override
  Stream<List<Team>> build() {
    return fetchTeamList();
  }

  Stream<List<Team>> fetchTeamList() {
    final auth = ref.read(authProvider.notifier);
    final currentUserId = auth.currentUserId;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }

    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
  }

  Future<void> createTeam(String teamName) async {
    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
  }

  Future<void> updateTeamName(String teamId, String newName) async {
    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
  }
}
