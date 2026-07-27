import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_table.dart';

part 'seed_dao.g.dart';

@DriftAccessor(tables: [Teams])
class SeedDao extends DatabaseAccessor<AppDatabase> with _$SeedDaoMixin {
  SeedDao(super.attachedDatabase);

  Future<void> ensureTestTeam({
    String teamId = 'test-team',
    String name = 'Test Team',
    int installationId = 12345678,
  }) async {
    final existing = await (select(
      teams,
    )..where((t) => t.id.equals(teamId))).getSingleOrNull();
    if (existing != null) {
      return;
    }

    final now = DateTime.now().toUtc();
    try {
      await into(teams).insert(
        DriftTeam(
          id: teamId,
          name: name,
          installationIds: [installationId],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } catch (_) {
      // Ignore duplicate key errors if created concurrently or already exists
    }
  }
}
