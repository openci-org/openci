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

  test('Database schema migrations run successfully', () async {
    final jobs = await db.select(db.buildJobs).get();
    expect(jobs, isEmpty);

    final logs = await db.select(db.buildJobLogs).get();
    expect(logs, isEmpty);
  });

  test('Can insert and retrieve DriftBuildJob and DriftBuildJobLog', () async {
    final now = DateTime.now().toUtc();

    final job = DriftBuildJob(
      id: 'test-job-123',
      status: BuildJobStatus.QUEUED,
      owner: 'openci-org',
      repo: 'openci',
      workflowName: 'CI Workflow',
      createdAt: now,
      updatedAt: now,
    );

    await db.into(db.buildJobs).insert(job);

    final retrievedJob = await (db.select(
      db.buildJobs,
    )..where((t) => t.id.equals('test-job-123'))).getSingle();

    expect(retrievedJob.owner, 'openci-org');
    expect(retrievedJob.status, BuildJobStatus.QUEUED);

    await db.buildJobDao.insertBuildJobLog(
      'test-run-456',
      'Initializing build environment...\n',
    );
    await db.buildJobDao.insertBuildJobLog(
      'test-run-456',
      'Running pub get...\nSuccess!',
    );

    final retrievedLogs = await db.buildJobDao.getBuildJobLogs('test-run-456');
    expect(retrievedLogs, hasLength(2));
    expect(retrievedLogs[0].logContent, contains('Initializing'));
    expect(retrievedLogs[1].logContent, contains('Success!'));
  });
}
