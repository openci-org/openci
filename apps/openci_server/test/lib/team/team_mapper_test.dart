import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_mapper.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  test(
    'team database round trip preserves settings without a GitHub URL',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final team = Team(
        id: 'team-1',
        name: '開発チーム',
        members: ['user-1'],
        installationIds: [123, 456],
        aiEnabled: false,
        runNumber: 42,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 2, 1),
      );

      await db.teamDao.createTeamAndMember(team.toDrift(), 'user-1');
      final stored = await db.teamDao.getTeam(team.id);
      final members = await db.teamDao.getTeamMembers(team.id);

      expect(stored, isNotNull);
      expect(
        stored!
            .toShared(members: members.map((m) => m.userId).toList())
            .toJson(),
        team.toJson(),
      );
    },
  );
}
