import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/delete_expired_github_connection_sessions.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 10, 16, 12);
  final createdAt = now.subtract(const Duration(minutes: 10));
  final expiresAt = now.subtract(const Duration(seconds: 1));
  final session = GitHubConnectionSessionsCompanion.insert(
    id: 'expired-session',
    userId: 'user-1',
    teamId: 'team-1',
    githubUserId: 123,
    referenceHash: 'expired-reference-hash',
    encryptedAccessToken: const Value('encrypted-user-token'),
    createdAt: createdAt,
    expiresAt: expiresAt,
  );

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-1',
        name: 'OpenCI',
        installationIds: const [],
        aiEnabled: false,
        runNumber: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      'user-1',
    );
    await db.into(db.gitHubConnectionSessions).insert(session);
  });

  tearDown(() => db.close());

  test('deletes expired sessions and preserves active sessions', () async {
    final active = session.copyWith(
      id: const Value('active-session'),
      referenceHash: const Value('active-reference-hash'),
      expiresAt: Value(now.add(const Duration(seconds: 1))),
    );
    await db.into(db.gitHubConnectionSessions).insert(active);

    final deleted = await deleteExpiredGitHubConnectionSessions(
      db: db,
      now: now,
    );

    expect(deleted, 1);
    final saved = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(saved.id, active.id.value);
    expect(saved.referenceHash, active.referenceHash.value);
    expect(saved.encryptedAccessToken, active.encryptedAccessToken.value);
    expect(saved.expiresAt.toUtc(), active.expiresAt.value);
  });

  test('deletes a session at its exact expiration time', () async {
    final deleted = await deleteExpiredGitHubConnectionSessions(
      db: db,
      now: expiresAt,
    );

    expect(deleted, 1);
    expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
  });

  test('keeps a session before its expiration time', () async {
    final deleted = await deleteExpiredGitHubConnectionSessions(
      db: db,
      now: expiresAt.subtract(const Duration(seconds: 1)),
    );

    expect(deleted, 0);
    final saved = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(saved.id, session.id.value);
    expect(saved.encryptedAccessToken, session.encryptedAccessToken.value);
  });

  test(
    'deletes expired consumed sessions even when their token remains',
    () async {
      await db
          .update(db.gitHubConnectionSessions)
          .write(
            GitHubConnectionSessionsCompanion(consumedAt: Value(createdAt)),
          );

      final deleted = await deleteExpiredGitHubConnectionSessions(
        db: db,
        now: now,
      );

      expect(deleted, 1);
      expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
    },
  );

  test(
    'deletes expired sessions whose token has already been cleared',
    () async {
      await db
          .update(db.gitHubConnectionSessions)
          .write(
            const GitHubConnectionSessionsCompanion(
              encryptedAccessToken: Value(null),
            ),
          );

      final deleted = await deleteExpiredGitHubConnectionSessions(
        db: db,
        now: now,
      );

      expect(deleted, 1);
      expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
    },
  );

  test('cleans up all teams even after the initiator has left', () async {
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-2',
        name: 'Other team',
        installationIds: const [],
        aiEnabled: false,
        runNumber: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      'user-1',
    );
    await db
        .into(db.gitHubConnectionSessions)
        .insert(
          session.copyWith(
            id: const Value('other-session'),
            teamId: const Value('team-2'),
            referenceHash: const Value('other-reference-hash'),
          ),
        );
    await db.delete(db.teamMembers).go();

    final deleted = await deleteExpiredGitHubConnectionSessions(
      db: db,
      now: now,
    );

    expect(deleted, 2);
    expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
    expect(await db.select(db.teams).get(), hasLength(2));
  });

  test(
    'returns zero when cleanup is repeated with no expired sessions',
    () async {
      expect(await deleteExpiredGitHubConnectionSessions(db: db, now: now), 1);
      expect(await deleteExpiredGitHubConnectionSessions(db: db, now: now), 0);
    },
  );

  test('uses the current time when no test time is supplied', () async {
    final currentTime = DateTime.now().toUtc();
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          GitHubConnectionSessionsCompanion(
            expiresAt: Value(currentTime.subtract(const Duration(minutes: 1))),
          ),
        );
    await db
        .into(db.gitHubConnectionSessions)
        .insert(
          session.copyWith(
            id: const Value('active-session'),
            referenceHash: const Value('active-reference-hash'),
            expiresAt: Value(currentTime.add(const Duration(days: 1))),
          ),
        );

    final deleted = await deleteExpiredGitHubConnectionSessions(db: db);

    expect(deleted, 1);
    final saved = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(saved.id, 'active-session');
    expect(saved.encryptedAccessToken, session.encryptedAccessToken.value);
  });

  test('reports database failures without exposing query values', () async {
    await db.customStatement('DROP TABLE github_connection_sessions');

    await expectLater(
      deleteExpiredGitHubConnectionSessions(db: db, now: now),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Failed to delete expired GitHub connection sessions',
        ),
      ),
    );
  });
}
