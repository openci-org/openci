import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/consume_github_connection_session.dart';
import 'package:openci_server/github/create_github_connection_session.dart';
import 'package:openci_server/github/fetch_github_installations.dart';
import 'package:openci_server/github/github_connection_exception.dart';
import 'package:openci_server/github/github_connection_session_table.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_server/github/persist_github_connection.dart';
import 'package:openci_server/github/save_github_connection.dart';
import 'package:openci_server/github/save_github_connection_and_consume_session.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

void testPersistGitHubConnection(Future<AppDatabase> Function() openDatabase) {
  late AppDatabase db;
  late String reference;
  late DriftGitHubConnectionSession session;
  late Map<String, String> environment;
  late Map<String, dynamic> user;
  late List<Map<String, dynamic>> installations;
  late Map<String, dynamic> membership;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) respond;

  setUp(() async {
    db = await openDatabase();
    final now = DateTime.now().toUtc();
    final team = DriftTeam(
      id: 'team-1',
      name: 'OpenCI',
      installationIds: const [],
      aiEnabled: false,
      runNumber: 1,
      createdAt: now,
      updatedAt: now,
    );
    await db.teamDao.createTeamAndMember(team, 'user-1');
    await db.teamDao.addTeamMember('team-1', 'teammate');
    await db.teamDao.createTeamAndMember(team.copyWith(id: 'team-2'), 'user-1');

    environment = {
      'GITHUB_APP_ID': '42',
      'GITHUB_API_BASE_URL': 'https://api.github.com',
      'SECRET_ENCRYPTION_KEY': base64Encode(List<int>.filled(32, 1)),
    };
    final created = await createGitHubConnectionSession(
      db: db,
      crypter: SecretCrypter(environment['SECRET_ENCRYPTION_KEY']!),
      userId: 'user-1',
      teamId: 'team-1',
      githubUserId: 123,
      accessToken: 'private-github-token',
    );
    reference = created.reference;
    session = await db.select(db.gitHubConnectionSessions).getSingle();

    user = {'id': 123, 'login': 'octocat'};
    installations = [
      {
        'id': 100,
        'app_id': 42,
        'account': {'id': 123, 'type': 'User', 'login': 'octocat'},
        'suspended_at': null,
      },
      {
        'id': 200,
        'app_id': 42,
        'account': {'id': 789, 'type': 'Organization', 'login': 'acme'},
        'suspended_at': null,
      },
    ];
    membership = {
      'state': 'active',
      'role': 'admin',
      'user': {'id': 123},
      'organization': {'id': 789},
    };
    requests = [];
    respond = (request) async {
      if (request.url.path.endsWith('/user')) return _json(user);
      if (request.url.path.endsWith('/user/installations')) {
        return _json({
          'total_count': installations.length,
          'installations': installations,
        });
      }
      if (request.url.path.endsWith('/user/memberships/orgs/acme')) {
        return _json(membership);
      }
      fail('Unexpected GitHub request: ${request.url}');
    };
  });

  tearDown(() => db.close());

  Future<DriftGitHubConnection?> persist({
    String? connectionReference,
    String userId = 'user-1',
    String teamId = 'team-1',
    int installationId = 200,
  }) => http.runWithClient(
    () => persistGitHubConnection(
      db: db,
      reference: connectionReference ?? reference,
      userId: userId,
      teamId: teamId,
      installationId: installationId,
      environment: environment,
    ),
    () => MockClient((request) {
      requests.add(request);
      return respond(request);
    }),
  );

  Future<DriftGitHubConnection> seedConnection({
    String teamId = 'team-1',
  }) async => (await saveGitHubConnection(
    db: db,
    teamId: teamId,
    githubApiBaseUrl: environment['GITHUB_API_BASE_URL']!,
    verifiedInstallation: const GitHubInstallation(
      id: 200,
      appId: 42,
      accountId: 789,
      accountType: 'Organization',
      accountLogin: 'old-acme',
      suspendedAt: null,
    ),
    verifiedByUserId: 'previous-verifier',
    verifiedByGitHubUserId: 456,
    verifiedAt: session.createdAt.subtract(const Duration(days: 1)),
  ))!;

  Future<void> expectUnusedSession() async {
    final current = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(current.consumedAt, isNull);
    expect(current.encryptedAccessToken, session.encryptedAccessToken);
  }

  Future<void> removeMembership() =>
      (db.delete(db.teamMembers)..where(
            (member) =>
                member.teamId.equals('team-1') & member.userId.equals('user-1'),
          ))
          .go();

  final invalidSession = throwsA(
    isA<InvalidGitHubConnectionSessionException>(),
  );
  final permissionsRequired = throwsA(
    isA<GitHubConnectionException>().having(
      (error) => error.failure,
      'failure',
      GitHubConnectionFailure.permissionsRequired,
    ),
  );
  final decryptionFailure = throwsA(
    isA<StateError>().having(
      (error) => error.message,
      'safe error message',
      'Failed to decrypt GitHub connection token',
    ),
  );

  test(
    'verifies and saves an organization connection using its session',
    () async {
      final before = DateTime.now().toUtc();

      final connection = (await persist())!;

      expect(await db.select(db.gitHubConnections).getSingle(), connection);
      expect(connection.teamId, 'team-1');
      expect(connection.githubApiBaseUrl, 'https://api.github.com');
      expect(connection.githubAppId, 42);
      expect(connection.installationId, 200);
      expect(connection.accountId, 789);
      expect(connection.accountType, GitHubAccountType.organization);
      expect(connection.accountLogin, 'acme');
      expect(connection.verifiedByUserId, 'user-1');
      expect(connection.verifiedByGitHubUserId, 123);
      expect(connection.status, GitHubConnectionStatus.active);
      expect(
        connection.verifiedAt.isBefore(
          before.subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
      expect(connection.verifiedAt.isAfter(DateTime.now().toUtc()), isFalse);
      expect(requests.map((request) => request.url.path), [
        '/user',
        '/user/installations',
        '/user/memberships/orgs/acme',
      ]);
      expect(
        requests.every(
          (request) =>
              request.headers['Authorization'] == 'Bearer private-github-token',
        ),
        isTrue,
      );
      final consumed = await db.select(db.gitHubConnectionSessions).getSingle();
      expect(consumed.consumedAt, isNotNull);
      expect(consumed.encryptedAccessToken, isNull);
    },
  );

  test('saves the selected personal installation owned by the user', () async {
    final connection = (await persist(installationId: 100))!;

    expect(connection.installationId, 100);
    expect(connection.accountId, 123);
    expect(connection.accountType, GitHubAccountType.user);
    expect(requests, hasLength(2));
  });

  test('verifies and stores the operator-configured GHES endpoint', () async {
    environment['GITHUB_API_BASE_URL'] =
        'https://github.example:8443/prefix/api/v3/';

    final connection = (await persist())!;

    expect(
      connection.githubApiBaseUrl,
      'https://github.example:8443/prefix/api/v3',
    );
    expect(requests.map((request) => request.url.host).toSet(), {
      'github.example',
    });
    expect(requests.map((request) => request.url.port).toSet(), {8443});
    expect(requests.map((request) => request.url.path), [
      '/prefix/api/v3/user',
      '/prefix/api/v3/user/installations',
      '/prefix/api/v3/user/memberships/orgs/acme',
    ]);
  });

  test(
    'refreshes an existing connection with freshly verified metadata',
    () async {
      final original = await seedConnection();

      final connection = (await persist())!;

      expect(connection.id, original.id);
      expect(connection.accountLogin, 'acme');
      expect(connection.verifiedByUserId, 'user-1');
      expect(connection.verifiedByGitHubUserId, 123);
      expect(connection.verifiedAt.isAfter(original.verifiedAt), isTrue);
    },
  );

  test('rejects an unknown reference before contacting GitHub', () async {
    await expectLater(
      persist(connectionReference: 'unknown-reference'),
      invalidSession,
    );

    expect(requests, isEmpty);
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
  });

  test(
    'rejects a different member of the same team before contacting GitHub',
    () async {
      await expectLater(persist(userId: 'teammate'), invalidSession);

      expect(requests, isEmpty);
      expect(await db.select(db.gitHubConnections).get(), isEmpty);
      await expectUnusedSession();
    },
  );

  test('rejects another team even when the user belongs to both', () async {
    await expectLater(persist(teamId: 'team-2'), invalidSession);

    expect(requests, isEmpty);
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
  });

  test('rejects an expired session before contacting GitHub', () async {
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          GitHubConnectionSessionsCompanion(
            expiresAt: Value(
              DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
            ),
          ),
        );

    await expectLater(persist(), invalidSession);

    expect(requests, isEmpty);
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
  });

  test('rejects a GitHub user who differs from the session user', () async {
    user['id'] = 999;

    await expectLater(persist(), permissionsRequired);

    expect(requests, hasLength(1));
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
  });

  test(
    'preserves an existing connection when GitHub admin authority was revoked',
    () async {
      final original = await seedConnection();
      membership['role'] = 'member';

      await expectLater(persist(), permissionsRequired);

      expect(await db.select(db.gitHubConnections).getSingle(), original);
      await expectUnusedSession();
    },
  );

  test(
    'propagates token rejection without saving or exposing upstream details',
    () async {
      respond = (_) async => http.Response(
        'private-github-token and private upstream detail',
        HttpStatus.unauthorized,
      );

      await expectLater(
        persist(),
        throwsA(
          isA<GitHubConnectionException>()
              .having(
                (error) => error.failure,
                'failure',
                GitHubConnectionFailure.reauthorizationRequired,
              )
              .having(
                (error) => error.message,
                'safe error message',
                'Failed to fetch GitHub user',
              ),
        ),
      );

      expect(await db.select(db.gitHubConnections).get(), isEmpty);
      await expectUnusedSession();
    },
  );

  test(
    'sanitizes an invalid encryption key before contacting GitHub',
    () async {
      environment['SECRET_ENCRYPTION_KEY'] = 'private-invalid-key';

      await expectLater(persist(), decryptionFailure);

      expect(requests, isEmpty);
      expect(await db.select(db.gitHubConnections).get(), isEmpty);
      await expectUnusedSession();
    },
  );

  test(
    'sanitizes token decryption failures without consuming the session',
    () async {
      await db
          .update(db.gitHubConnectionSessions)
          .write(
            const GitHubConnectionSessionsCompanion(
              encryptedAccessToken: Value('private-invalid-ciphertext'),
            ),
          );

      await expectLater(persist(), decryptionFailure);

      expect(requests, isEmpty);
      expect(await db.select(db.gitHubConnections).get(), isEmpty);
      final current = await db.select(db.gitHubConnectionSessions).getSingle();
      expect(current.consumedAt, isNull);
      expect(current.encryptedAccessToken, 'private-invalid-ciphertext');
    },
  );

  test(
    'leaves another team connection and the session unchanged on conflict',
    () async {
      final original = await seedConnection(teamId: 'team-2');

      expect(await persist(), isNull);

      expect(await db.select(db.gitHubConnections).getSingle(), original);
      await expectUnusedSession();
    },
  );

  test(
    'rolls back insertion when the session expires during GitHub verification',
    () async {
      final original = respond;
      respond = (request) async {
        await db
            .update(db.gitHubConnectionSessions)
            .write(
              GitHubConnectionSessionsCompanion(
                expiresAt: Value(
                  DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
                ),
              ),
            );
        return original(request);
      };

      await expectLater(persist(), invalidSession);

      expect(requests, hasLength(3));
      expect(await db.select(db.gitHubConnections).get(), isEmpty);
      await expectUnusedSession();
    },
  );

  test(
    'rolls back a refresh when team membership is lost during verification',
    () async {
      final connection = await seedConnection();
      final original = respond;
      respond = (request) async {
        await removeMembership();
        return original(request);
      };

      await expectLater(persist(), invalidSession);

      expect(await db.select(db.gitHubConnections).getSingle(), connection);
      await expectUnusedSession();
    },
  );

  test(
    'rolls back a refresh when another request consumes the session',
    () async {
      final connection = await seedConnection();
      final original = respond;
      respond = (request) async {
        if (request.url.path.endsWith('/user')) {
          expect(
            await consumeGitHubConnectionSession(
              db: db,
              reference: reference,
              userId: 'user-1',
              teamId: 'team-1',
            ),
            isTrue,
          );
        }
        return original(request);
      };

      await expectLater(persist(), invalidSession);

      expect(await db.select(db.gitHubConnections).getSingle(), connection);
      final consumed = await db.select(db.gitHubConnectionSessions).getSingle();
      expect(consumed.consumedAt, isNotNull);
      expect(consumed.encryptedAccessToken, isNull);
    },
  );

  test(
    'rejects a repeated confirmation without contacting GitHub again',
    () async {
      final connection = await persist();
      requests.clear();

      await expectLater(persist(), invalidSession);

      expect(requests, isEmpty);
      expect(await db.select(db.gitHubConnections).getSingle(), connection);
    },
  );

  test(
    'leaves the session unused and reports sanitized database failures',
    () async {
      final original = respond;
      respond = (request) async {
        if (request.url.path.endsWith('/user')) {
          await db.customStatement('DROP TABLE github_connections');
        }
        return original(request);
      };

      await expectLater(
        persist(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'safe error message',
            'Failed to save GitHub connection and consume session',
          ),
        ),
      );

      await expectUnusedSession();
    },
  );
}

http.Response _json(Object? value) => http.Response(
  jsonEncode(value),
  HttpStatus.ok,
  headers: {HttpHeaders.contentTypeHeader: 'application/json'},
);
