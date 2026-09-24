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

  test('creates the database without legacy log or heartbeat tables', () async {
    final jobs = await db.select(db.buildJobs).get();
    expect(jobs, isEmpty);

    final legacyTables = await db.customSelect('''
      SELECT name FROM sqlite_master
      WHERE name IN (
        'build_steps', 'build_step_logs', 'build_job_logs', 'worker_heartbeats'
      )
    ''').get();
    expect(legacyTables, isEmpty);
  });

  for (final version in [19, 22, 23]) {
    test('upgrades v$version while preserving jobs and runs', () async {
      await db.close();
      db = AppDatabase(
        NativeDatabase.memory(
          setup: (database) {
            // Keep only the legacy columns and constraints needed for the drop.
            database.execute('''
              PRAGMA foreign_keys = ON;
              PRAGMA user_version = $version;
              CREATE TABLE build_jobs (id TEXT PRIMARY KEY);
              CREATE TABLE build_runs (
                id TEXT PRIMARY KEY,
                build_job_id TEXT REFERENCES build_jobs (id)
              );
              CREATE TABLE worker_heartbeats (
                id TEXT PRIMARY KEY,
                version TEXT,
                platform TEXT,
                status TEXT,
                last_seen_at INTEGER NOT NULL
              );
              INSERT INTO build_jobs VALUES ('job-1');
              INSERT INTO build_runs VALUES ('run-1', 'job-1');
              INSERT INTO worker_heartbeats VALUES (
                'worker-1', '1.0.0', 'macos', 'idle', 0
              );
            ''');
            if (version < 23) {
              database.execute('''
                CREATE TABLE build_job_logs (
                  id INTEGER PRIMARY KEY,
                  run_id TEXT,
                  log_content TEXT
                );
                INSERT INTO build_job_logs VALUES (1, 'run-1', 'job log');
              ''');
            }
            if (version >= 20 && version < 23) {
              database.execute('''
                CREATE TABLE build_steps (
                  id TEXT PRIMARY KEY,
                  run_id TEXT REFERENCES build_runs (id) ON DELETE CASCADE
                );
                CREATE TABLE build_step_logs (
                  id INTEGER PRIMARY KEY,
                  step_id TEXT REFERENCES build_steps (id) ON DELETE CASCADE,
                  log_content TEXT
                );
                INSERT INTO build_steps VALUES ('step-1', 'run-1');
                INSERT INTO build_step_logs VALUES (1, 'step-1', 'step log');
              ''');
            }
          },
        ),
      );

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table'",
          )
          .get();
      expect(
        tables.map((row) => row.read<String>('name')),
        unorderedEquals(['build_jobs', 'build_runs']),
      );
      expect(
        (await db.customSelect('SELECT * FROM build_jobs').get()).single.data,
        {'id': 'job-1'},
      );
      expect(
        (await db.customSelect('SELECT * FROM build_runs').get()).single.data,
        {'id': 'run-1', 'build_job_id': 'job-1'},
      );
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        24,
      );
    });
  }

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
