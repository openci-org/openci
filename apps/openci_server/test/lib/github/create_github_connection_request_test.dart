import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/create_github_connection_request.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

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

  test(
    'stores a request with a state hash and a ten-minute expiration',
    () async {
      final result = await createGitHubConnectionRequest(
        db: db,
        userId: 'user-1',
        teamId: 'team-1',
        now: DateTime.utc(2026, 10, 16, 12),
      );

      final savedRequest = await db
          .select(db.gitHubConnectionRequests)
          .getSingle();

      expect(savedRequest.id, result.id);
      expect(savedRequest.userId, 'user-1');
      expect(savedRequest.teamId, 'team-1');
      expect(result.state, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      expect(
        savedRequest.stateHash,
        sha256.convert(utf8.encode(result.state)).toString(),
      );
      expect(savedRequest.createdAt.toUtc(), DateTime.utc(2026, 10, 16, 12));
      expect(
        savedRequest.expiresAt.toUtc(),
        DateTime.utc(2026, 10, 16, 12, 10),
      );
      expect(result.expiresAt, DateTime.utc(2026, 10, 16, 12, 10));
    },
  );

  test(
    'returns an S256 challenge for the verifier stored in the database',
    () async {
      final result = await createGitHubConnectionRequest(
        db: db,
        userId: 'user-1',
        teamId: 'team-1',
      );

      final savedRequest = await db
          .select(db.gitHubConnectionRequests)
          .getSingle();

      expect(
        savedRequest.codeVerifier,
        matches(RegExp(r'^[A-Za-z0-9_-]{43}$')),
      );
      expect(savedRequest.codeVerifier, isNot(result.state));
      expect(result.codeChallenge, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      expect(
        base64Url.decode(base64Url.normalize(result.codeChallenge)),
        sha256.convert(ascii.encode(savedRequest.codeVerifier)).bytes,
      );
      expect(result.expiresAt.isUtc, isTrue);
    },
  );

  test(
    'creates new identifiers and verification values for each request',
    () async {
      final first = await createGitHubConnectionRequest(
        db: db,
        userId: 'user-1',
        teamId: 'team-1',
      );
      final second = await createGitHubConnectionRequest(
        db: db,
        userId: 'user-1',
        teamId: 'team-1',
      );

      expect(second.id, isNot(first.id));
      expect(second.state, isNot(first.state));
      expect(second.codeChallenge, isNot(first.codeChallenge));
      expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(2));
    },
  );

  test('propagates a failed save when the team does not exist', () async {
    await expectLater(
      createGitHubConnectionRequest(
        db: db,
        userId: 'user-1',
        teamId: 'missing-team',
      ),
      throwsException,
    );

    expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
  });
}
