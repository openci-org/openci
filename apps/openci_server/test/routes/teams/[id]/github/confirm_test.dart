import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/create_github_connection_session.dart';
import 'package:openci_server/github/fetch_github_installations.dart';
import 'package:openci_server/github/github_connection_session_table.dart';
import 'package:openci_server/github/save_github_connection.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

import '../../../../../routes/teams/[id]/github/confirm.dart' as route;

class _MockStdout extends Mock implements Stdout {}

void main() {
  late AppDatabase db;
  late String reference;
  late DriftGitHubConnectionSession session;
  late Map<String, String> environment;
  late Map<String, dynamic> user;
  late Map<String, dynamic> membership;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) respond;
  late _MockStdout errorOutput;

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
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
    membership = {
      'state': 'active',
      'role': 'admin',
      'user': {'id': 123},
      'organization': {'id': 789},
    };
    requests = [];
    errorOutput = _MockStdout();
    respond = (request) async {
      if (request.url.path.endsWith('/user')) return _json(user);
      if (request.url.path.endsWith('/user/installations')) {
        return _json({
          'total_count': 1,
          'installations': [
            {
              'id': 200,
              'app_id': 42,
              'account': {'id': 789, 'type': 'Organization', 'login': 'acme'},
              'suspended_at': null,
            },
          ],
        });
      }
      if (request.url.path.endsWith('/user/memberships/orgs/acme')) {
        return _json(membership);
      }
      fail('Unexpected GitHub request: ${request.url}');
    };
  });

  tearDown(() => db.close());

  Future<Response> post({
    String uid = 'user-1',
    String teamId = 'team-1',
    int installationId = 200,
    String? body,
  }) {
    final context = TestRequestContext(
      path: '/teams/$teamId/github/confirm',
      method: HttpMethod.post,
      body:
          body ??
          jsonEncode({
            'reference': reference,
            'installationId': installationId,
          }),
    );
    context.provide<AppDatabase>(db);
    context.provide<String?>(uid);
    context.provide<Map<String, String>>(environment);
    return IOOverrides.runZoned(
      () => http.runWithClient(
        () => route.onRequest(context.context, teamId),
        () => MockClient((request) {
          requests.add(request);
          return respond(request);
        }),
      ),
      stderr: () => errorOutput,
    );
  }

  void expectPrivateHeaders(Response response) {
    expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
    expect(response.headers['referrer-policy'], 'no-referrer');
  }

  Future<void> expectError(
    Response response,
    int statusCode,
    String message, {
    String? code,
  }) async {
    expect(response.statusCode, statusCode);
    expect(await response.json(), {
      'success': false,
      'error': message,
      'code': ?code,
    });
    expectPrivateHeaders(response);
  }

  Future<void> expectUnusedSession() async {
    final current = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(current.consumedAt, isNull);
    expect(current.encryptedAccessToken, session.encryptedAccessToken);
  }

  Future<void> expectInvalidBody(Map<String, dynamic> body) async {
    await expectError(
      await post(body: jsonEncode(body)),
      400,
      'Invalid GitHub connection request',
    );
    expect(requests, isEmpty);
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
    verifyZeroInteractions(errorOutput);
  }

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

  Future<void> removeMembership() =>
      (db.delete(db.teamMembers)..where(
            (member) =>
                member.teamId.equals('team-1') & member.userId.equals('user-1'),
          ))
          .go();

  Future<void> expectInternalError(Response response) async {
    await expectError(response, 500, 'Internal server error');
    final logged = verify(
      () => errorOutput.writeln(captureAny()),
    ).captured.join();
    expect(logged, isNot(contains(reference)));
    expect(logged, isNot(contains(session.referenceHash)));
    expect(logged, isNot(contains(session.encryptedAccessToken!)));
    expect(logged, isNot(contains(environment['SECRET_ENCRYPTION_KEY']!)));
    expect(logged, isNot(contains('private-github-token')));
    expect(logged, isNot(contains('private-ciphertext')));
    expect(logged, isNot(contains('no such table')));
  }

  test('requires authentication before reading the body or database', () async {
    final context = TestRequestContext(
      path: '/teams/team-1/github/confirm',
      method: HttpMethod.post,
    );
    context.provide<String?>(null);

    final response = await route.onRequest(context.context, 'team-1');

    await expectError(response, 401, 'Authentication required');
  });

  test(
    'rejects GET before reading authentication or database providers',
    () async {
      final context = TestRequestContext(path: '/teams/team-1/github/confirm');

      final response = await route.onRequest(context.context, 'team-1');

      expect(response.statusCode, 405);
      expectPrivateHeaders(response);
    },
  );

  test('confirms the connection and returns only success', () async {
    final response = await post();

    expect(response.statusCode, 200);
    expect(await response.json(), {'success': true});
    expectPrivateHeaders(response);
    final connection = await db.select(db.gitHubConnections).getSingle();
    expect(connection.teamId, 'team-1');
    expect(connection.installationId, 200);
    expect(connection.accountLogin, 'acme');
    expect(connection.verifiedByUserId, 'user-1');
    final consumed = await db.select(db.gitHubConnectionSessions).getSingle();
    expect(consumed.consumedAt, isNotNull);
    expect(consumed.encryptedAccessToken, isNull);
    verifyZeroInteractions(errorOutput);
  });

  test('uses the operator-configured GHES endpoint', () async {
    environment['GITHUB_API_BASE_URL'] =
        'https://github.example:8443/prefix/api/v3/';

    final response = await post();

    expect(response.statusCode, 200);
    final connection = await db.select(db.gitHubConnections).getSingle();
    expect(
      connection.githubApiBaseUrl,
      'https://github.example:8443/prefix/api/v3',
    );
    expect(requests.map((request) => request.url.path), [
      '/prefix/api/v3/user',
      '/prefix/api/v3/user/installations',
      '/prefix/api/v3/user/memberships/orgs/acme',
    ]);
    expect(
      requests.every(
        (request) =>
            request.url.host == 'github.example' && request.url.port == 8443,
      ),
      isTrue,
    );
  });

  test('rejects malformed JSON without logging the reference', () async {
    final response = await post(body: '{"reference":"$reference"');

    await expectError(response, 400, 'Invalid GitHub connection request');
    expect(requests, isEmpty);
    verifyZeroInteractions(errorOutput);
    await expectUnusedSession();
  });

  test('requires both reference and installation ID', () async {
    await expectInvalidBody({'reference': reference});
    await expectInvalidBody({'installationId': 200});
  });

  test('requires a nonempty string reference', () async {
    await expectInvalidBody({'reference': ' ', 'installationId': 200});
    await expectInvalidBody({'reference': 123, 'installationId': 200});
  });

  test(
    'requires a positive integer installation ID without coercion',
    () async {
      await expectInvalidBody({'reference': reference, 'installationId': 0});
      await expectInvalidBody({'reference': reference, 'installationId': -1});
      await expectInvalidBody({
        'reference': reference,
        'installationId': 200.0,
      });
      await expectInvalidBody({
        'reference': reference,
        'installationId': '200',
      });
    },
  );

  test(
    'rejects body-supplied identity, account metadata, and GitHub settings',
    () async {
      await expectInvalidBody({
        'reference': reference,
        'installationId': 200,
        'userId': 'user-1',
        'teamId': 'team-1',
        'accountLogin': 'forged-org',
        'githubApiBaseUrl': 'https://other.example',
      });
    },
  );

  test('rejects an unknown reference', () async {
    final response = await post(
      body: jsonEncode({
        'reference': 'unknown-reference',
        'installationId': 200,
      }),
    );

    await expectError(
      response,
      403,
      'Invalid or expired GitHub connection session',
    );
    expect(requests, isEmpty);
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
  });

  test('rejects a different member of the same team', () async {
    final response = await post(uid: 'teammate');

    await expectError(
      response,
      403,
      'Invalid or expired GitHub connection session',
    );
    expect(requests, isEmpty);
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
  });

  test('rejects another team even when the user belongs to both', () async {
    final response = await post(teamId: 'team-2');

    await expectError(
      response,
      403,
      'Invalid or expired GitHub connection session',
    );
    expect(requests, isEmpty);
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
  });

  test('rejects a user who left the team', () async {
    await removeMembership();

    final response = await post();

    await expectError(
      response,
      403,
      'Invalid or expired GitHub connection session',
    );
    expect(requests, isEmpty);
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
  });

  test('rejects a selected ID absent from verified candidates', () async {
    final response = await post(installationId: 999);

    await expectError(
      response,
      403,
      'GitHub permissions required',
      code: 'github_permissions_required',
    );
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
  });

  test('rejects a GitHub user different from the initiating user', () async {
    user['id'] = 999;

    final response = await post();

    await expectError(
      response,
      403,
      'GitHub permissions required',
      code: 'github_permissions_required',
    );
    expect(requests, hasLength(1));
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
  });

  test(
    'preserves the existing connection after GitHub authority is revoked',
    () async {
      final original = await seedConnection();
      membership['role'] = 'member';

      final response = await post();

      await expectError(
        response,
        403,
        'GitHub permissions required',
        code: 'github_permissions_required',
      );
      expect(await db.select(db.gitHubConnections).getSingle(), original);
      await expectUnusedSession();
    },
  );

  test(
    'reports a token rejected by GitHub as reauthorization required',
    () async {
      respond = (_) async =>
          http.Response('private-github-token upstream detail', 401);

      final response = await post();

      await expectError(
        response,
        409,
        'GitHub reauthorization required',
        code: 'github_reauthorization_required',
      );
      expect(await db.select(db.gitHubConnections).get(), isEmpty);
      await expectUnusedSession();
      verifyZeroInteractions(errorOutput);
    },
  );

  test('reports rate limiting as an upstream failure', () async {
    respond = (_) async => http.Response(
      'private-upstream-detail',
      403,
      headers: {'x-ratelimit-remaining': '0'},
    );

    final response = await post();

    await expectError(
      response,
      502,
      'Failed to confirm GitHub connection',
      code: 'github_unavailable',
    );
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
  });

  test('preserves an existing connection on GitHub server failure', () async {
    final original = await seedConnection();
    respond = (_) async => http.Response('private-upstream-detail', 503);

    final response = await post();

    await expectError(
      response,
      502,
      'Failed to confirm GitHub connection',
      code: 'github_unavailable',
    );
    expect(await db.select(db.gitHubConnections).getSingle(), original);
    await expectUnusedSession();
    verifyZeroInteractions(errorOutput);
  });

  test('does not expose network errors containing credentials', () async {
    respond = (_) async => throw const SocketException('private-github-token');

    final response = await post();

    await expectError(
      response,
      502,
      'Failed to confirm GitHub connection',
      code: 'github_unavailable',
    );
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
    verifyZeroInteractions(errorOutput);
  });

  test(
    'reports ownership conflict without exposing or modifying the other team',
    () async {
      final original = await seedConnection(teamId: 'team-2');

      final response = await post();

      await expectError(
        response,
        409,
        'GitHub connection conflict',
        code: 'github_connection_conflict',
      );
      expect(await db.select(db.gitHubConnections).getSingle(), original);
      await expectUnusedSession();
    },
  );

  test('rejects expired sessions without contacting GitHub', () async {
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          GitHubConnectionSessionsCompanion(
            expiresAt: Value(
              DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
            ),
          ),
        );

    final response = await post();

    await expectError(
      response,
      403,
      'Invalid or expired GitHub connection session',
    );
    expect(requests, isEmpty);
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    await expectUnusedSession();
  });

  test(
    'rolls back a refresh when membership is lost during verification',
    () async {
      final connection = await seedConnection();
      final original = respond;
      respond = (request) async {
        await removeMembership();
        return original(request);
      };

      final response = await post();

      await expectError(
        response,
        403,
        'Invalid or expired GitHub connection session',
      );
      expect(await db.select(db.gitHubConnections).getSingle(), connection);
      await expectUnusedSession();
    },
  );

  test(
    'rejects repeated confirmation without another GitHub request',
    () async {
      expect((await post()).statusCode, 200);
      final connection = await db.select(db.gitHubConnections).getSingle();
      requests.clear();

      final response = await post();

      await expectError(
        response,
        403,
        'Invalid or expired GitHub connection session',
      );
      expect(requests, isEmpty);
      expect(await db.select(db.gitHubConnections).getSingle(), connection);
    },
  );

  test('sanitizes database read failures', () async {
    await db.customStatement('DROP TABLE github_connection_sessions');

    final response = await post();

    await expectInternalError(response);
    expect(requests, isEmpty);
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
  });

  test('sanitizes decryption failures without consuming the session', () async {
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          const GitHubConnectionSessionsCompanion(
            encryptedAccessToken: Value('private-ciphertext'),
          ),
        );

    final response = await post();

    await expectInternalError(response);
    expect(requests, isEmpty);
    expect(await db.select(db.gitHubConnections).get(), isEmpty);
    expect(
      (await db.select(db.gitHubConnectionSessions).getSingle()).consumedAt,
      isNull,
    );
  });

  test(
    'rolls back a refresh when session consumption fails in the database',
    () async {
      final connection = await seedConnection();
      final original = respond;
      respond = (request) async {
        if (request.url.path.endsWith('/user')) {
          await db.customStatement('DROP TABLE github_connection_sessions');
        }
        return original(request);
      };

      final response = await post();

      await expectInternalError(response);
      expect(await db.select(db.gitHubConnections).getSingle(), connection);
    },
  );
}

http.Response _json(Object? value) => http.Response(
  jsonEncode(value),
  HttpStatus.ok,
  headers: {HttpHeaders.contentTypeHeader: 'application/json'},
);
