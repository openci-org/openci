import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'BuildJobDao watchBuildJobsForTeam streams updates in real-time',
    () async {
      final stream = db.buildJobDao.watchBuildJobsForTeam(teamId: 'team-1');

      expect(
        stream,
        emitsThrough(hasLength(1)),
      );

      await db
          .into(db.buildJobs)
          .insert(
            BuildJobsCompanion.insert(
              id: 'job-1',
              status: BuildJobStatus.QUEUED,
              owner: 'openci',
              repo: 'app',
              workflowName: 'CI',
              teamId: const Value('team-1'),
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    },
  );
}
