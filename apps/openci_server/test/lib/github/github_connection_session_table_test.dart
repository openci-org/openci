import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  final session = GitHubConnectionSessionsCompanion.insert(
    id: 'session-1',
    userId: 'user-1',
    teamId: 'team-1',
    githubUserId: 4294967296,
    referenceHash: 'reference-hash',
    encryptedAccessToken: const Value('encrypted-user-token'),
    createdAt: DateTime.utc(2026),
    expiresAt: DateTime.utc(2026, 1, 1, 0, 10),
  );

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await db
        .into(db.teams)
        .insert(
          DriftTeam(
            id: 'team-1',
            name: 'OpenCI',
            installationIds: const [],
            aiEnabled: false,
            runNumber: 1,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
  });

  tearDown(() => db.close());

  test('stores the caller, team, GitHub user, token, and expiration', () async {
    await db.into(db.gitHubConnectionSessions).insert(session);

    final savedSession = await db
        .select(db.gitHubConnectionSessions)
        .getSingle();

    expect(savedSession.id, 'session-1');
    expect(savedSession.userId, 'user-1');
    expect(savedSession.teamId, 'team-1');
    expect(savedSession.githubUserId, 4294967296);
    expect(savedSession.referenceHash, 'reference-hash');
    expect(savedSession.encryptedAccessToken, 'encrypted-user-token');
    expect(savedSession.createdAt.toUtc(), DateTime.utc(2026));
    expect(savedSession.expiresAt.toUtc(), DateTime.utc(2026, 1, 1, 0, 10));
    expect(savedSession.consumedAt, isNull);
  });

  test('can record consumption and clear the stored token', () async {
    await db.into(db.gitHubConnectionSessions).insert(session);
    final consumedAt = DateTime.utc(2026, 1, 1, 0, 5);

    await (db.update(
      db.gitHubConnectionSessions,
    )..where((table) => table.id.equals('session-1'))).write(
      GitHubConnectionSessionsCompanion(
        consumedAt: Value(consumedAt),
        encryptedAccessToken: const Value(null),
      ),
    );

    final savedSession = await db
        .select(db.gitHubConnectionSessions)
        .getSingle();
    expect(savedSession.consumedAt?.toUtc(), consumedAt);
    expect(savedSession.encryptedAccessToken, isNull);
  });

  test('rejects a second session with the same reference hash', () async {
    await db.into(db.gitHubConnectionSessions).insert(session);

    await expectLater(
      db
          .into(db.gitHubConnectionSessions)
          .insert(
            session.copyWith(id: const Value('session-2')),
          ),
      throwsException,
    );
  });

  test('rejects a session for a missing team', () async {
    await expectLater(
      db
          .into(db.gitHubConnectionSessions)
          .insert(
            session.copyWith(teamId: const Value('missing-team')),
          ),
      throwsException,
    );
  });

  test('deletes sessions when their team is deleted', () async {
    await db.into(db.gitHubConnectionSessions).insert(session);

    await (db.delete(db.teams)..where((team) => team.id.equals('team-1'))).go();

    expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
  });

  test(
    'redacts the token and reference hash from JSON and diagnostics',
    () async {
      await db.into(db.gitHubConnectionSessions).insert(session);
      final savedSession = await db
          .select(db.gitHubConnectionSessions)
          .getSingle();

      final json = jsonEncode(savedSession);
      expect(json, isNot(contains('encrypted-user-token')));
      expect(json, isNot(contains('reference-hash')));
      expect(jsonDecode(json)['encryptedAccessToken'], '[REDACTED]');
      expect(jsonDecode(json)['referenceHash'], '[REDACTED]');
      expect(savedSession.toString(), isNot(contains('encrypted-user-token')));
      expect(savedSession.toString(), isNot(contains('reference-hash')));
      expect(savedSession.toString(), contains('session-1'));
    },
  );
}
