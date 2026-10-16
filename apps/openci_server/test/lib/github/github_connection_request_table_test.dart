import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  final request = DriftGitHubConnectionRequest(
    id: 'request-1',
    userId: 'user-1',
    teamId: 'team-1',
    stateHash: 'state-hash',
    codeVerifier: 'code-verifier',
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

  test('stores the caller, team, verification data, and expiration', () async {
    await db.into(db.gitHubConnectionRequests).insert(request);

    final savedRequest = await db
        .select(db.gitHubConnectionRequests)
        .getSingle();

    expect(savedRequest.id, request.id);
    expect(savedRequest.userId, request.userId);
    expect(savedRequest.teamId, request.teamId);
    expect(savedRequest.stateHash, request.stateHash);
    expect(savedRequest.codeVerifier, request.codeVerifier);
    expect(savedRequest.createdAt.toUtc(), request.createdAt);
    expect(savedRequest.expiresAt.toUtc(), request.expiresAt);
  });

  test('rejects a second request with the same state hash', () async {
    await db.into(db.gitHubConnectionRequests).insert(request);

    await expectLater(
      db
          .into(db.gitHubConnectionRequests)
          .insert(
            request.copyWith(id: 'request-2'),
          ),
      throwsException,
    );
  });

  test('rejects a request for a missing team', () async {
    await expectLater(
      db
          .into(db.gitHubConnectionRequests)
          .insert(
            request.copyWith(teamId: 'missing-team'),
          ),
      throwsException,
    );
  });

  test('deletes connection requests when their team is deleted', () async {
    await db.into(db.gitHubConnectionRequests).insert(request);

    await (db.delete(db.teams)..where((team) => team.id.equals('team-1'))).go();

    expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
  });
}
