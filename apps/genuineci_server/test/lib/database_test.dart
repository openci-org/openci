import 'package:drift/native.dart';
import 'package:genuineci_server/database.dart';
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

  test('Can insert and retrieve DriftBuildJob', () async {
    final now = DateTime.now().toUtc();

    final job = DriftBuildJob(
      id: 'test-job-123',
      status: BuildJobStatus.QUEUED,
      owner: 'openci-org',
      repo: 'openci',
      workflowName: 'CI Workflow',
      workflowFileName: 'ci.yml',
      createdAt: now,
      updatedAt: now,
    );

    await db.into(db.buildJobs).insert(job);

    final retrievedJob = await (db.select(
      db.buildJobs,
    )..where((t) => t.id.equals('test-job-123'))).getSingle();

    expect(retrievedJob.owner, 'openci-org');
    expect(retrievedJob.status, BuildJobStatus.QUEUED);
  });

  group('loadDatabaseUrl Tests', () {
    test('uses DATABASE_URL environment variable if specified', () {
      final url = loadDatabaseUrl(
        environment: {
          'DATABASE_URL': 'postgres://test-db:5432/test',
        },
      );
      expect(
        url,
        equals('postgres://test-db:5432/test?sslmode=disable'),
      );
    });

    test('throws StateError if DATABASE_URL is missing', () {
      expect(
        () => loadDatabaseUrl(environment: {}),
        throwsStateError,
      );
    });
  });
}
