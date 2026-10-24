import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  final team = DriftTeam(
    id: 'team-a',
    name: 'Original team',
    installationIds: const [123],
    aiEnabled: true,
    runNumber: 1,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.teams).insert(team);
    await db.into(db.teams).insert(team.copyWith(id: 'team-b'));
  });

  Future<int> allocate(String teamId) =>
      db.transaction(() => db.teamDao.allocateRunNumber(teamId));

  test('allocates consecutive numbers independently for each team', () async {
    expect(await allocate('team-a'), 1);
    expect(await allocate('team-a'), 2);
    expect(await allocate('team-b'), 1);
    expect((await db.teamDao.getTeam('team-a'))!.runNumber, 3);
    expect((await db.teamDao.getTeam('team-b'))!.runNumber, 2);
  });

  test(
    'rolls back allocation when the surrounding transaction fails',
    () async {
      await expectLater(
        db.transaction(() async {
          expect(await db.teamDao.allocateRunNumber('team-a'), 1);
          throw StateError('Run creation failed');
        }),
        throwsStateError,
      );

      expect((await db.teamDao.getTeam('team-a'))!.runNumber, 1);
      expect(await allocate('team-a'), 1);
    },
  );

  for (final invalid in [0, -1]) {
    test('rejects counter $invalid without updating it', () async {
      await (db.update(
        db.teams,
      )..where((row) => row.id.equals('team-a'))).write(
        TeamsCompanion(runNumber: Value(invalid)),
      );

      await expectLater(
        db.teamDao.allocateRunNumber('team-a'),
        throwsStateError,
      );

      expect((await db.teamDao.getTeam('team-a'))!.runNumber, invalid);
      expect((await db.teamDao.getTeam('team-b'))!.runNumber, 1);
    });
  }

  test('rejects a missing team without modifying other counters', () async {
    await expectLater(allocate('missing'), throwsStateError);

    expect((await db.teamDao.getTeam('team-a'))!.runNumber, 1);
    expect((await db.teamDao.getTeam('team-b'))!.runNumber, 1);
  });

  test(
    'updates settings without restoring a stale counter or creation time',
    () async {
      final staleTeam = (await db.teamDao.getTeam('team-a'))!;
      await allocate('team-a');
      final changedSettings = staleTeam.copyWith(
        name: 'Renamed team',
        installationIds: const [456],
        aiEnabled: false,
        updatedAt: DateTime.utc(2026, 2),
      );

      await db.teamDao.updateTeam(
        changedSettings.copyWith(createdAt: DateTime.utc(2020)),
      );

      expect(
        (await db.teamDao.getTeam('team-a'))!.toJson(),
        changedSettings.copyWith(runNumber: 2).toJson(),
      );
      expect(
        (await db.teamDao.getTeam('team-b'))!.toJson(),
        team.copyWith(id: 'team-b').toJson(),
      );
      expect(await allocate('team-a'), 2);
    },
  );
}
