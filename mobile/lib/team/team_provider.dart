import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/supabase/supabase_provider.dart';
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
    final supabase = ref.read(supabaseClientProvider);
    final auth = ref.read(authProvider.notifier);
    final currentUserId = auth.currentUserId;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }

    return supabase
        .from('team_members')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .asyncMap((memberRows) async {
          if (memberRows.isEmpty) return <Team>[];
          final teamIds = memberRows
              .map((r) => r['team_id'] as String)
              .toList();
          final teams = await supabase
              .from('teams')
              .select()
              .inFilter('id', teamIds);

          return teams.map((team) {
            final teamMembers = memberRows
                .where((m) => m['team_id'] == team['id'])
                .map((m) => m['user_id'] as String)
                .toList();
            return Team(
              id: team['id'] as String,
              name: team['name'] as String,
              members: teamMembers,
              createdAt: DateTime.parse(team['created_at'] as String),
              updatedAt: DateTime.parse(team['updated_at'] as String),
            );
          }).toList();
        });
  }

  Future<void> createTeam(String teamName) async {
    final supabase = ref.read(supabaseClientProvider);
    final auth = ref.read(authProvider.notifier);
    final currentUserId = auth.currentUserId;
    if (currentUserId == null) {
      throw Exception('User is not authenticated');
    }
    final slug = teamName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');

    final teamRow = await supabase
        .from('teams')
        .insert({'name': teamName, 'slug': slug})
        .select()
        .single();

    await supabase.from('team_members').insert({
      'team_id': teamRow['id'],
      'user_id': currentUserId,
      'role': 'owner',
    });
  }

  Future<void> updateTeamName(String teamId, String newName) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('teams').update({'name': newName}).eq('id', teamId);
  }
}
