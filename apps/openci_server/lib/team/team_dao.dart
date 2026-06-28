import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_table.dart';

part 'team_dao.g.dart';

@DriftAccessor(tables: [Teams, TeamMembers])
class TeamDao extends DatabaseAccessor<AppDatabase> with _$TeamDaoMixin {
  TeamDao(super.attachedDatabase);

  Future<List<DriftTeam>> getTeamsForUser(String uid) async {
    final query = select(teams).join([
      innerJoin(teamMembers, teamMembers.teamId.equalsExp(teams.id)),
    ])..where(teamMembers.userId.equals(uid));

    final rows = await query.get();
    return rows.map((row) => row.readTable(teams)).toList();
  }

  Future<bool> isTeamMember(String uid, String teamId) async {
    final query = select(teamMembers)
      ..where((t) => t.teamId.equals(teamId) & t.userId.equals(uid));
    final count = await query.get();
    return count.isNotEmpty;
  }

  Future<void> createTeamAndMember(DriftTeam team, String userId) async {
    await transaction(() async {
      await into(teams).insert(team);
      await into(teamMembers).insert(
        TeamMembersCompanion.insert(
          teamId: team.id,
          userId: userId,
        ),
      );
    });
  }

  Future<void> updateTeam(DriftTeam team) => update(teams).replace(team);

  Future<void> deleteTeam(String teamId) async {
    await transaction(() async {
      await (delete(teamMembers)..where((t) => t.teamId.equals(teamId))).go();
      await (delete(teams)..where((t) => t.id.equals(teamId))).go();
    });
  }

  Future<DriftTeam?> getTeamByInstallationId(int installationId) async {
    final allTeams = await select(teams).get();
    for (final team in allTeams) {
      if (team.installationIds.contains(installationId)) {
        return team;
      }
    }
    return null;
  }

  Future<DriftTeam?> getTeam(String teamId) {
    return (select(teams)..where((t) => t.id.equals(teamId))).getSingleOrNull();
  }
}
