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

    final log = DriftBuildJobLog(
      runId: 'test-run-456',
      logContent:
          'Initializing build environment...\nRunning pub get...\nSuccess!',
      createdAt: now,
    );

    await db.into(db.buildJobLogs).insert(log);

    final retrievedLog = await (db.select(
      db.buildJobLogs,
    )..where((t) => t.runId.equals('test-run-456'))).getSingle();

    expect(retrievedLog.logContent, contains('Success!'));
  });
}
