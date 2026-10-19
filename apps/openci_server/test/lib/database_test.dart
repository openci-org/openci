import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
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
    final columns = await db.customSelect('PRAGMA table_info(teams)').get();
    expect(
      columns.map((row) => row.read<String>('name')),
      isNot(contains('github_base_url')),
    );
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
              CREATE TABLE teams (id TEXT PRIMARY KEY, github_base_url TEXT);
              INSERT INTO teams VALUES ('team-1', 'https://untrusted.example');
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
        unorderedEquals([
          'build_jobs',
          'build_runs',
          'teams',
          'github_connection_requests',
          'github_connection_sessions',
          'github_connections',
          'billing_accounts',
        ]),
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
        29,
      );
      expect(
        (await db.customSelect('SELECT * FROM teams').getSingle()).data,
        {'id': 'team-1'},
      );
    });
  }

  test(
    'upgrades v24 teams without changing membership or build URLs',
    () async {
      await db.close();
      db = AppDatabase(
        NativeDatabase.memory(
          setup: (database) {
            database.execute('''
        PRAGMA foreign_keys = ON;
        PRAGMA user_version = 24;
        CREATE TABLE teams (
          id TEXT PRIMARY KEY, name TEXT NOT NULL, github_base_url TEXT,
          installation_ids TEXT NOT NULL, ai_enabled INTEGER NOT NULL,
          run_number INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
        );
        CREATE TABLE team_members (
          id INTEGER PRIMARY KEY, team_id TEXT REFERENCES teams(id),
          user_id TEXT NOT NULL
        );
        CREATE TABLE build_jobs (id TEXT PRIMARY KEY, github_base_url TEXT);
        INSERT INTO teams VALUES (
          'team-1', 'OpenCI', 'https://untrusted.example', '[123]', 1, 42, 0, 1
        );
        INSERT INTO team_members VALUES (1, 'team-1', 'user-1');
        INSERT INTO build_jobs VALUES ('job-1', 'https://legacy.example');
      ''');
          },
        ),
      );

      final team = await db.teamDao.getTeam('team-1');
      expect(team!.name, 'OpenCI');
      expect(team.installationIds, [123]);
      expect(team.aiEnabled, isTrue);
      expect(team.runNumber, 42);
      expect(
        (await db.teamDao.getTeamMembers('team-1')).single.userId,
        'user-1',
      );
      expect(
        (await db.customSelect('SELECT * FROM teams').getSingle()).data,
        isNot(contains('github_base_url')),
      );
      expect(
        (await db.customSelect('SELECT * FROM build_jobs').getSingle()).data,
        {'id': 'job-1', 'github_base_url': 'https://legacy.example'},
      );
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        29,
      );
    },
  );

  test('upgrades v25 while preserving existing data', () async {
    await db.close();
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) {
          database.execute('''
            PRAGMA foreign_keys = ON;
            PRAGMA user_version = 25;
            CREATE TABLE teams (
              id TEXT PRIMARY KEY, name TEXT NOT NULL,
              installation_ids TEXT NOT NULL, ai_enabled INTEGER NOT NULL,
              run_number INTEGER NOT NULL DEFAULT 1,
              created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
            );
            CREATE TABLE team_members (
              id INTEGER PRIMARY KEY, team_id TEXT REFERENCES teams(id),
              user_id TEXT NOT NULL
            );
            CREATE TABLE build_jobs (id TEXT PRIMARY KEY);
            CREATE TABLE build_runs (
              id TEXT PRIMARY KEY, build_job_id TEXT REFERENCES build_jobs(id)
            );
            INSERT INTO teams VALUES (
              'team-1', 'OpenCI', '[123]', 1, 42, 0, 1
            );
            INSERT INTO team_members VALUES (1, 'team-1', 'user-1');
            INSERT INTO build_jobs VALUES ('job-1');
            INSERT INTO build_runs VALUES ('run-1', 'job-1');
          ''');
        },
      ),
    );

    final requests = await db.select(db.gitHubConnectionRequests).get();
    expect(requests, isEmpty);
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      29,
    );
    expect(
      (await db.customSelect('SELECT * FROM teams').getSingle()).data,
      {
        'id': 'team-1',
        'name': 'OpenCI',
        'installation_ids': '[123]',
        'ai_enabled': 1,
        'run_number': 42,
        'created_at': 0,
        'updated_at': 1,
      },
    );
    expect(
      (await db.customSelect('SELECT * FROM team_members').getSingle()).data,
      {'id': 1, 'team_id': 'team-1', 'user_id': 'user-1'},
    );
    expect(
      (await db.customSelect('SELECT * FROM build_jobs').getSingle()).data,
      {'id': 'job-1'},
    );
    expect(
      (await db.customSelect('SELECT * FROM build_runs').getSingle()).data,
      {'id': 'run-1', 'build_job_id': 'job-1'},
    );

    final request = DriftGitHubConnectionRequest(
      id: 'request-1',
      userId: 'user-1',
      teamId: 'team-1',
      stateHash: 'state-hash',
      codeVerifier: 'code-verifier',
      createdAt: DateTime.utc(2026),
      expiresAt: DateTime.utc(2026, 1, 1, 0, 10),
    );
    await db.into(db.gitHubConnectionRequests).insert(request);

    final savedRequest = await db
        .select(db.gitHubConnectionRequests)
        .getSingle();
    expect(savedRequest.id, 'request-1');
    expect(savedRequest.userId, 'user-1');
    expect(savedRequest.teamId, 'team-1');
  });

  test('upgrades v26 without losing pending GitHub requests', () async {
    await db.close();
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) {
          database.execute('''
            PRAGMA foreign_keys = ON;
            PRAGMA user_version = 26;
            CREATE TABLE teams (
              id TEXT PRIMARY KEY, name TEXT NOT NULL,
              installation_ids TEXT NOT NULL, ai_enabled INTEGER NOT NULL,
              run_number INTEGER NOT NULL DEFAULT 1,
              created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
            );
            CREATE TABLE github_connection_requests (
              id TEXT NOT NULL PRIMARY KEY, user_id TEXT NOT NULL,
              team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
              state_hash TEXT NOT NULL UNIQUE, code_verifier TEXT NOT NULL,
              created_at INTEGER NOT NULL, expires_at INTEGER NOT NULL
            );
            INSERT INTO teams VALUES (
              'team-1', 'OpenCI', '[123]', 1, 42, 0, 1
            );
            INSERT INTO github_connection_requests VALUES (
              'request-1', 'user-1', 'team-1', 'state-hash', 'code-verifier',
              0, 600
            );
          ''');
        },
      ),
    );

    expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      29,
    );
    expect(
      (await db.customSelect('SELECT * FROM teams').getSingle()).data,
      {
        'id': 'team-1',
        'name': 'OpenCI',
        'installation_ids': '[123]',
        'ai_enabled': 1,
        'run_number': 42,
        'created_at': 0,
        'updated_at': 1,
      },
    );
    expect(
      (await db
              .customSelect(
                'SELECT * FROM github_connection_requests',
              )
              .getSingle())
          .data,
      {
        'id': 'request-1',
        'user_id': 'user-1',
        'team_id': 'team-1',
        'state_hash': 'state-hash',
        'code_verifier': 'code-verifier',
        'created_at': 0,
        'expires_at': 600,
      },
    );

    await db
        .into(db.gitHubConnectionSessions)
        .insert(
          GitHubConnectionSessionsCompanion.insert(
            id: 'session-1',
            userId: 'user-1',
            teamId: 'team-1',
            githubUserId: 123,
            referenceHash: 'new-reference-hash',
            encryptedAccessToken: const Value('encrypted-user-token'),
            createdAt: DateTime.utc(2026),
            expiresAt: DateTime.utc(2026, 1, 1, 0, 10),
          ),
        );
    final savedSession = await db
        .select(db.gitHubConnectionSessions)
        .getSingle();
    expect(savedSession.id, 'session-1');
    expect(savedSession.teamId, 'team-1');
  });

  test(
    'upgrades v27 without promoting legacy links or losing sessions',
    () async {
      await db.close();
      db = AppDatabase(
        NativeDatabase.memory(
          setup: (database) {
            database.execute('''
            PRAGMA foreign_keys = ON;
            PRAGMA user_version = 27;
            CREATE TABLE teams (
              id TEXT PRIMARY KEY, name TEXT NOT NULL,
              installation_ids TEXT NOT NULL, ai_enabled INTEGER NOT NULL,
              run_number INTEGER NOT NULL DEFAULT 1,
              created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
            );
            CREATE TABLE team_members (
              id INTEGER PRIMARY KEY, team_id TEXT REFERENCES teams(id),
              user_id TEXT NOT NULL
            );
            CREATE TABLE github_connection_requests (
              id TEXT PRIMARY KEY, user_id TEXT NOT NULL,
              team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
              state_hash TEXT NOT NULL UNIQUE, code_verifier TEXT NOT NULL,
              created_at INTEGER NOT NULL, expires_at INTEGER NOT NULL
            );
            CREATE TABLE github_connection_sessions (
              id TEXT PRIMARY KEY, user_id TEXT NOT NULL,
              team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
              github_user_id INTEGER NOT NULL, reference_hash TEXT NOT NULL UNIQUE,
              encrypted_access_token TEXT, created_at INTEGER NOT NULL,
              expires_at INTEGER NOT NULL, consumed_at INTEGER
            );
            INSERT INTO teams VALUES ('team-1', 'OpenCI', '[123]', 1, 42, 0, 1);
            INSERT INTO teams VALUES ('team-2', 'Other team', '[123]', 0, 1, 0, 1);
            INSERT INTO team_members VALUES (1, 'team-1', 'user-1');
            INSERT INTO github_connection_requests VALUES (
              'request-1', 'user-1', 'team-1', 'state-hash', 'code-verifier', 0, 600
            );
            INSERT INTO github_connection_sessions VALUES (
              'session-1', 'user-1', 'team-1', 123, 'reference-hash',
              'encrypted-user-token', 0, 600, NULL
            );
          ''');
          },
        ),
      );

      expect(await db.select(db.gitHubConnections).get(), isEmpty);
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        29,
      );
      expect((await db.teamDao.getTeam('team-1'))!.installationIds, [123]);
      expect((await db.teamDao.getTeam('team-2'))!.installationIds, [123]);
      expect((await db.teamDao.getTeam('team-1'))!.runNumber, 42);
      expect(
        (await db.teamDao.getTeamMembers('team-1')).single.userId,
        'user-1',
      );
      final request = await db.select(db.gitHubConnectionRequests).getSingle();
      expect(request.id, 'request-1');
      expect(request.codeVerifier, 'code-verifier');
      final session = await db.select(db.gitHubConnectionSessions).getSingle();
      expect(session.id, 'session-1');
      expect(session.referenceHash, 'reference-hash');
      expect(session.encryptedAccessToken, 'encrypted-user-token');
      expect(session.consumedAt, isNull);

      await db
          .into(db.gitHubConnections)
          .insert(
            GitHubConnectionsCompanion.insert(
              id: 'connection-1',
              teamId: 'team-1',
              githubApiBaseUrl: 'https://api.github.com',
              githubAppId: 1,
              installationId: 123,
              accountId: 456,
              accountType: GitHubAccountType.organization,
              accountLogin: 'openci-org',
              verifiedByUserId: 'user-1',
              verifiedByGitHubUserId: 123,
              verifiedAt: DateTime.utc(2026),
              status: GitHubConnectionStatus.active,
            ),
          );
      expect(
        (await db.select(db.gitHubConnections).getSingle()).teamId,
        'team-1',
      );
    },
  );

  test('stores one billing account per team', () async {
    const account = BillingAccount(teamId: 'team-1');
    await db.into(db.billingAccounts).insert(account);
    await expectLater(
      db.into(db.billingAccounts).insert(account),
      throwsA(isA<Exception>()),
    );
    await db
        .into(db.billingAccounts)
        .insert(account.copyWith(teamId: 'team-2'));
    expect(
      await db.select(db.billingAccounts).get(),
      unorderedEquals([account, account.copyWith(teamId: 'team-2')]),
    );
  });

  test('retains billing identity after team deletion', () async {
    await db.customStatement('PRAGMA foreign_keys = ON');
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-1',
        name: 'OpenCI',
        installationIds: const [],
        aiEnabled: false,
        runNumber: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      'member-1',
    );
    const account = BillingAccount(teamId: 'team-1');
    await db.into(db.billingAccounts).insert(account);

    await db.teamDao.deleteTeam('team-1');

    expect(await db.teamDao.getTeam('team-1'), isNull);
    expect(await db.teamDao.getTeamMembers('team-1'), isEmpty);
    expect(await db.select(db.billingAccounts).getSingle(), account);
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
