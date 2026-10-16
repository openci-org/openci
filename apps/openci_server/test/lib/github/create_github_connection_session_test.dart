import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/create_github_connection_request.dart';
import 'package:openci_server/github/create_github_connection_session.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late SecretCrypter crypter;

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    crypter = SecretCrypter(base64Encode(List<int>.filled(32, 1)));
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

  test('stores the verified identity with a ten-minute expiration', () async {
    final result = await createGitHubConnectionSession(
      db: db,
      crypter: crypter,
      userId: 'user-1',
      teamId: 'team-1',
      githubUserId: 123,
      accessToken: 'github-user-token',
      now: DateTime.utc(2026, 10, 16, 12),
    );

    final session = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(session.userId, 'user-1');
    expect(session.teamId, 'team-1');
    expect(session.githubUserId, 123);
    expect(session.createdAt.toUtc(), DateTime.utc(2026, 10, 16, 12));
    expect(session.expiresAt.toUtc(), DateTime.utc(2026, 10, 16, 12, 10));
    expect(session.consumedAt, isNull);
    expect(result.expiresAt, session.expiresAt.toUtc());
    expect(result.expiresAt.isUtc, isTrue);
  });

  test('stores only a hash of the newly issued reference', () async {
    final request = await createGitHubConnectionRequest(
      db: db,
      userId: 'user-1',
      teamId: 'team-1',
    );

    final result = await createGitHubConnectionSession(
      db: db,
      crypter: crypter,
      userId: 'user-1',
      teamId: 'team-1',
      githubUserId: 123,
      accessToken: 'github-user-token',
    );

    final session = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(result.reference, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(result.reference, isNot(request.state));
    expect(result.reference, isNot(request.id));
    expect(
      session.referenceHash,
      sha256.convert(utf8.encode(result.reference)).toString(),
    );
    final row = await db
        .customSelect('SELECT * FROM github_connection_sessions')
        .getSingle();
    expect(row.data.values, isNot(contains(result.reference)));
  });

  test('encrypts the access token before saving it', () async {
    final result = await createGitHubConnectionSession(
      db: db,
      crypter: crypter,
      userId: 'user-1',
      teamId: 'team-1',
      githubUserId: 123,
      accessToken: 'github-user-token',
    );

    final session = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(session.encryptedAccessToken, isNot('github-user-token'));
    expect(
      await crypter.decrypt(session.encryptedAccessToken!),
      'github-user-token',
    );
    final row = await db
        .customSelect('SELECT * FROM github_connection_sessions')
        .getSingle();
    expect(row.data.values, isNot(contains('github-user-token')));
    expect(jsonEncode(session), isNot(contains(session.encryptedAccessToken!)));
    expect(session.toString(), isNot(contains('github-user-token')));
    expect(result.toString(), isNot(contains('github-user-token')));
    expect(result.toString(), isNot(contains(result.reference)));
  });

  test('generates independent sessions for repeated authorizations', () async {
    final first = await createGitHubConnectionSession(
      db: db,
      crypter: crypter,
      userId: 'user-1',
      teamId: 'team-1',
      githubUserId: 123,
      accessToken: 'github-user-token',
    );
    final second = await createGitHubConnectionSession(
      db: db,
      crypter: crypter,
      userId: 'user-1',
      teamId: 'team-1',
      githubUserId: 123,
      accessToken: 'github-user-token',
    );

    final sessions = await db.select(db.gitHubConnectionSessions).get();
    expect(second.reference, isNot(first.reference));
    expect(sessions, hasLength(2));
    expect(sessions[0].id, isNot(sessions[1].id));
    expect(
      sessions[0].encryptedAccessToken,
      isNot(sessions[1].encryptedAccessToken),
    );
  });

  test('uses the current time when no testing override is provided', () async {
    final before = DateTime.now().toUtc();
    final result = await createGitHubConnectionSession(
      db: db,
      crypter: crypter,
      userId: 'user-1',
      teamId: 'team-1',
      githubUserId: 123,
      accessToken: 'github-user-token',
    );
    final after = DateTime.now().toUtc();

    expect(
      result.expiresAt.isBefore(before.add(const Duration(minutes: 10))),
      isFalse,
    );
    expect(
      result.expiresAt.isAfter(after.add(const Duration(minutes: 10))),
      isFalse,
    );
  });

  test(
    'does not save a session or expose database errors for a missing team',
    () async {
      await expectLater(
        createGitHubConnectionSession(
          db: db,
          crypter: crypter,
          userId: 'user-1',
          teamId: 'missing-team',
          githubUserId: 123,
          accessToken: 'github-user-token',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Failed to create GitHub connection session',
          ),
        ),
      );

      expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
    },
  );

  test('does not save a session or expose encryption error details', () async {
    await expectLater(
      createGitHubConnectionSession(
        db: db,
        crypter: _FailingSecretCrypter(),
        userId: 'user-1',
        teamId: 'team-1',
        githubUserId: 123,
        accessToken: 'github-user-token',
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Failed to create GitHub connection session',
        ),
      ),
    );

    expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
  });

  test('rejects an invalid GitHub user ID without saving a session', () async {
    await expectLater(
      createGitHubConnectionSession(
        db: db,
        crypter: crypter,
        userId: 'user-1',
        teamId: 'team-1',
        githubUserId: 0,
        accessToken: 'github-user-token',
      ),
      throwsArgumentError,
    );

    expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
  });

  test('rejects an empty access token without saving a session', () async {
    await expectLater(
      createGitHubConnectionSession(
        db: db,
        crypter: crypter,
        userId: 'user-1',
        teamId: 'team-1',
        githubUserId: 123,
        accessToken: '   ',
      ),
      throwsArgumentError,
    );

    expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
  });
}

class _FailingSecretCrypter extends SecretCrypter {
  _FailingSecretCrypter() : super(base64Encode(List<int>.filled(32, 1)));

  @override
  Future<String> encrypt(String plainText) async {
    throw StateError('Could not encrypt $plainText');
  }
}
