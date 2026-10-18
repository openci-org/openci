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
import 'package:openci_server/github/github_connection_session_table.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

import '../../../../../routes/teams/[id]/github/candidates.dart' as route;

class _MockStdout extends Mock implements Stdout {}

void main() {
  late AppDatabase db;
  late String reference;
  late DriftGitHubConnectionSession session;
  late Map<String, String> environment;
  late List<Map<String, dynamic>> installations;
  late Map<String, dynamic> membership;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) respond;

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    final now = DateTime.now().toUtc();
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-1',
        name: 'OpenCI',
        installationIds: const [],
        aiEnabled: false,
        runNumber: 1,
        createdAt: now,
        updatedAt: now,
      ),
      'user-1',
    );
    await db.teamDao.addTeamMember('team-1', 'teammate');
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-2',
        name: 'Other team',
        installationIds: const [],
        aiEnabled: false,
        runNumber: 1,
        createdAt: now,
        updatedAt: now,
      ),
      'user-1',
    );
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
      if (request.url.path.endsWith('/user')) {
        return _json({'id': 123, 'login': 'octocat'});
      }
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

  http.Client githubClient() => MockClient((request) {
    requests.add(request);
    return respond(request);
  });

  Future<Response> post({
    String? uid = 'user-1',
    String teamId = 'team-1',
    String? body,
  }) {
    final context = TestRequestContext(
      path: '/teams/$teamId/github/candidates',
      method: HttpMethod.post,
      body: body ?? jsonEncode({'reference': reference}),
    );
    context.provide<AppDatabase>(db);
    context.provide<String?>(uid);
    context.provide<Map<String, String>>(environment);
    return http.runWithClient(
      () => route.onRequest(context.context, teamId),
      githubClient,
    );
  }

  Future<void> expectInvalidSession(Response response) async {
    expect(response.statusCode, HttpStatus.forbidden);
    expect(await response.json(), {
      'success': false,
      'error': 'Invalid or expired GitHub connection session',
    });
    expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
    expect(response.headers['referrer-policy'], 'no-referrer');
    expect(requests, isEmpty);
  }

  Future<void> removeMembership() =>
      (db.delete(db.teamMembers)..where(
            (member) =>
                member.teamId.equals('team-1') & member.userId.equals('user-1'),
          ))
          .go();

  test('requires authentication before accessing providers', () async {
    final context = TestRequestContext(
      path: '/teams/team-1/github/candidates',
      method: HttpMethod.post,
    );
    context.provide<String?>(null);

    final response = await route.onRequest(context.context, 'team-1');

    expect(response.statusCode, HttpStatus.unauthorized);
    expect(await response.json(), {
      'success': false,
      'error': 'Authentication required',
    });
    expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
    expect(response.headers['referrer-policy'], 'no-referrer');
  });

  test('rejects GET before accessing providers', () async {
    final context = TestRequestContext(path: '/teams/team-1/github/candidates');

    final response = await route.onRequest(context.context, 'team-1');

    expect(response.statusCode, HttpStatus.methodNotAllowed);
    expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
    expect(response.headers['referrer-policy'], 'no-referrer');
  });

  test(
    'returns only verified candidates and leaves the session pending',
    () async {
      environment['GITHUB_API_BASE_URL'] = 'https://github.example/api/v3';
      environment['GITHUB_APP_INSTALLATION_URL'] =
          'https://github.example/apps/openci/installations/new';
      final response = await post(
        body: jsonEncode({
          'reference': reference,
          'userId': 'forged-user',
          'teamId': 'team-2',
          'accessToken': 'forged-token',
          'githubBaseUrl': 'https://attacker.example',
          'installationUrl': 'https://attacker.example/install',
        }),
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.json(), {
        'success': true,
        'installationUrl':
            'https://github.example/apps/openci/installations/new',
        'candidates': [
          {
            'installationId': 100,
            'accountLogin': 'octocat',
            'accountType': 'User',
          },
          {
            'installationId': 200,
            'accountLogin': 'acme',
            'accountType': 'Organization',
          },
        ],
      });
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(response.headers['referrer-policy'], 'no-referrer');
      expect(requests, hasLength(3));
      for (final request in requests) {
        expect(request.url.host, 'github.example');
        expect(request.url.path, startsWith('/api/v3/'));
        expect(request.headers['Authorization'], 'Bearer private-github-token');
      }
      final saved = await db.select(db.gitHubConnectionSessions).getSingle();
      expect(saved.toJson(), session.toJson());
      expect((await db.teamDao.getTeam('team-1'))!.installationIds, isEmpty);
    },
  );

  test('returns an empty array when the user has no installations', () async {
    installations.clear();

    final response = await post(
      body: jsonEncode({
        'reference': reference,
        'installationUrl': 'https://attacker.example/install',
      }),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(await response.json(), {'success': true, 'candidates': []});
    expect(requests, hasLength(2));
  });

  test(
    'returns the configured installation URL even with no candidates',
    () async {
      installations.clear();
      environment['GITHUB_APP_INSTALLATION_URL'] =
          '  https://github.com/apps/openci/installations/new  ';

      final response = await post();

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.json(), {
        'success': true,
        'installationUrl': 'https://github.com/apps/openci/installations/new',
        'candidates': [],
      });
      expect(requests, hasLength(2));
      expect(
        requests.every((request) => request.url.host == 'api.github.com'),
        isTrue,
      );
    },
  );

  test('omits an invalid installation URL without losing candidates', () async {
    environment['GITHUB_APP_INSTALLATION_URL'] =
        'https://user:private-password@github.com/apps/openci';

    final response = await post();
    final body = await response.json();

    expect(response.statusCode, HttpStatus.ok);
    expect(body['success'], isTrue);
    expect(body['candidates'], hasLength(2));
    expect(body, isNot(contains('installationUrl')));
    expect(jsonEncode(body), isNot(contains('private-password')));
  });

  test('excludes organizations where the user is an ordinary member', () async {
    installations.removeAt(0);
    membership['role'] = 'member';

    final response = await post();

    expect(response.statusCode, HttpStatus.ok);
    expect(await response.json(), {'success': true, 'candidates': []});
  });

  test('rejects another member despite a forged initiating UID', () async {
    await expectInvalidSession(
      await post(
        uid: 'teammate',
        body: jsonEncode({'reference': reference, 'userId': 'user-1'}),
      ),
    );
  });

  test('rejects another team even if the initiator belongs to it', () async {
    await expectInvalidSession(await post(teamId: 'team-2'));
  });

  test('rejects an initiator who has left the team', () async {
    await removeMembership();

    await expectInvalidSession(await post());
  });

  test('rejects an unknown reference without contacting GitHub', () async {
    await expectInvalidSession(
      await post(body: jsonEncode({'reference': 'unknown-reference'})),
    );
  });

  test('does not accept the stored hash in place of the reference', () async {
    await expectInvalidSession(
      await post(body: jsonEncode({'reference': session.referenceHash})),
    );
  });

  test('rejects an expired session without contacting GitHub', () async {
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          GitHubConnectionSessionsCompanion(
            expiresAt: Value(
              DateTime.now().subtract(const Duration(minutes: 1)),
            ),
          ),
        );

    await expectInvalidSession(await post());
  });

  test('rejects a consumed session without contacting GitHub', () async {
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          GitHubConnectionSessionsCompanion(consumedAt: Value(DateTime.now())),
        );

    await expectInvalidSession(await post());
  });

  test('rejects a session whose token has been erased', () async {
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          const GitHubConnectionSessionsCompanion(
            encryptedAccessToken: Value(null),
          ),
        );

    await expectInvalidSession(await post());
  });

  test('requires a reference in the JSON body', () async {
    final response = await post(body: '{}');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(requests, isEmpty);
  });

  test('rejects a non-string reference', () async {
    final response = await post(body: jsonEncode({'reference': 123}));

    expect(response.statusCode, HttpStatus.badRequest);
    expect(requests, isEmpty);
  });

  test('rejects a blank reference', () async {
    final response = await post(body: jsonEncode({'reference': '  '}));

    expect(response.statusCode, HttpStatus.badRequest);
    expect(requests, isEmpty);
  });

  test('rejects a reference supplied only in the URL', () async {
    final context = TestRequestContext(
      path: '/teams/team-1/github/candidates?reference=$reference',
      method: HttpMethod.post,
      body: '{}',
    );
    context.provide<String?>('user-1');

    final response = await route.onRequest(context.context, 'team-1');

    expect(response.statusCode, HttpStatus.badRequest);
  });

  test(
    'does not return or log malformed JSON containing a reference',
    () async {
      final errorOutput = _MockStdout();

      final response = await IOOverrides.runZoned(
        () => post(body: '{"reference":"$reference'),
        stderr: () => errorOutput,
      );

      expect(response.statusCode, HttpStatus.badRequest);
      expect(await response.json(), {
        'success': false,
        'error': 'Invalid GitHub connection reference',
      });
      verifyZeroInteractions(errorOutput);
      expect(requests, isEmpty);
    },
  );

  Future<Response> postWithoutErrorLogs() async {
    final errorOutput = _MockStdout();
    final response = await IOOverrides.runZoned(
      () => post(),
      stderr: () => errorOutput,
    );
    expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
    expect(response.headers['referrer-policy'], 'no-referrer');
    verifyZeroInteractions(errorOutput);
    return response;
  }

  Future<void> expectGitHubFailure() async {
    final response = await postWithoutErrorLogs();
    expect(response.statusCode, HttpStatus.badGateway);
    expect(await response.json(), {
      'success': false,
      'error': 'Failed to fetch GitHub connection candidates',
      'code': 'github_unavailable',
    });
  }

  test('requires GitHub reauthorization when its token is rejected', () async {
    respond = (_) async => http.Response('private-upstream-error', 401);

    final response = await postWithoutErrorLogs();

    expect(response.statusCode, HttpStatus.conflict);
    expect(await response.json(), {
      'success': false,
      'error': 'GitHub reauthorization required',
      'code': 'github_reauthorization_required',
    });
  });

  test('distinguishes missing installation permissions', () async {
    final success = respond;
    respond = (request) async => request.url.path == '/user/installations'
        ? http.Response('private-upstream-error', 403)
        : success(request);

    final response = await postWithoutErrorLogs();

    expect(response.statusCode, HttpStatus.forbidden);
    expect(await response.json(), {
      'success': false,
      'error': 'GitHub permissions required',
      'code': 'github_permissions_required',
    });
  });

  test(
    'omits an organization when its membership is not found',
    () async {
      final success = respond;
      respond = (request) async => request.url.path.contains('/memberships/')
          ? http.Response('private-upstream-error', 404)
          : success(request);

      final response = await postWithoutErrorLogs();

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.json(), {
        'success': true,
        'candidates': [
          {
            'installationId': 100,
            'accountLogin': 'octocat',
            'accountType': 'User',
          },
        ],
      });
    },
  );

  test(
    'preserves reauthorization errors from membership verification',
    () async {
      final success = respond;
      respond = (request) async => request.url.path.contains('/memberships/')
          ? http.Response('private-upstream-error', 401)
          : success(request);

      final response = await postWithoutErrorLogs();

      expect(response.statusCode, HttpStatus.conflict);
      expect(await response.json(), {
        'success': false,
        'error': 'GitHub reauthorization required',
        'code': 'github_reauthorization_required',
      });
    },
  );

  test('classifies primary rate limits as upstream failures', () async {
    respond = (_) async => http.Response(
      'private-upstream-error',
      403,
      headers: {'x-ratelimit-remaining': '0'},
    );

    await expectGitHubFailure();
  });

  test(
    'does not omit an organization when membership is rate limited',
    () async {
      final success = respond;
      respond = (request) async => request.url.path.contains('/memberships/')
          ? http.Response(
              'private-upstream-error',
              403,
              headers: {'x-ratelimit-remaining': '0'},
            )
          : success(request);

      await expectGitHubFailure();
    },
  );

  test('recognizes secondary rate limits without rate limit headers', () async {
    respond = (_) async => http.Response(
      jsonEncode({'message': 'You have exceeded a secondary rate limit.'}),
      403,
    );

    await expectGitHubFailure();
  });

  test('recognizes rate limits with a Retry-After header', () async {
    respond = (_) async => http.Response(
      'private-upstream-error',
      403,
      headers: {'retry-after': '60'},
    );

    await expectGitHubFailure();
  });

  test('classifies HTTP 429 as an upstream failure', () async {
    respond = (_) async => http.Response('private-upstream-error', 429);

    await expectGitHubFailure();
  });

  test('sanitizes a GitHub server failure', () async {
    respond = (_) async => http.Response('private-upstream-error', 503);

    await expectGitHubFailure();
  });

  test('sanitizes a network error containing credentials', () async {
    respond = (_) async => throw const SocketException('private-github-token');

    await expectGitHubFailure();
  });

  test(
    'does not return partial candidates after malformed membership JSON',
    () async {
      final success = respond;
      respond = (request) async => request.url.path.contains('/memberships/')
          ? http.Response('private-upstream-error', 200)
          : success(request);

      await expectGitHubFailure();
    },
  );

  Future<void> expectInternalError() async {
    final errorOutput = _MockStdout();
    final response = await IOOverrides.runZoned(
      () => post(),
      stderr: () => errorOutput,
    );
    expect(response.statusCode, HttpStatus.internalServerError);
    expect(await response.json(), {
      'success': false,
      'error': 'Internal server error',
    });
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
    expect(requests, isEmpty);
  }

  test('sanitizes database failures', () async {
    await db.customStatement('DROP TABLE github_connection_sessions');

    await expectInternalError();
  });

  test('sanitizes invalid encryption configuration', () async {
    environment['SECRET_ENCRYPTION_KEY'] = 'private-invalid-key';

    await expectInternalError();
  });

  test('rejects a different encryption key', () async {
    environment['SECRET_ENCRYPTION_KEY'] = base64Encode(
      List<int>.filled(32, 2),
    );

    await expectInternalError();
  });

  test('sanitizes invalid encrypted token data', () async {
    await db
        .update(db.gitHubConnectionSessions)
        .write(
          const GitHubConnectionSessionsCompanion(
            encryptedAccessToken: Value('private-ciphertext'),
          ),
        );

    await expectInternalError();
  });

  test(
    'rejects invalid GitHub configuration before contacting GitHub',
    () async {
      environment['GITHUB_APP_ID'] = 'invalid';

      await expectInternalError();
    },
  );

  test('rechecks membership after the GitHub requests', () async {
    final success = respond;
    respond = (request) async {
      await removeMembership();
      return success(request);
    };

    final response = await post();

    expect(response.statusCode, HttpStatus.forbidden);
    expect(
      (await response.json())['error'],
      'Invalid or expired GitHub connection session',
    );
    expect(requests, isNotEmpty);
  });

  test('rechecks expiry after the GitHub requests', () async {
    final success = respond;
    respond = (request) async {
      await db
          .update(db.gitHubConnectionSessions)
          .write(
            GitHubConnectionSessionsCompanion(
              expiresAt: Value(
                DateTime.now().subtract(const Duration(minutes: 1)),
              ),
            ),
          );
      return success(request);
    };

    final response = await post();

    expect(response.statusCode, HttpStatus.forbidden);
    expect(requests, isNotEmpty);
  });

  test('rechecks consumption after the GitHub requests', () async {
    final success = respond;
    respond = (request) async {
      await db
          .update(db.gitHubConnectionSessions)
          .write(
            GitHubConnectionSessionsCompanion(
              consumedAt: Value(DateTime.now()),
              encryptedAccessToken: const Value(null),
            ),
          );
      return success(request);
    };

    final response = await post();

    expect(response.statusCode, HttpStatus.forbidden);
    expect(requests, isNotEmpty);
  });
}

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  HttpStatus.ok,
  headers: {HttpHeaders.contentTypeHeader: 'application/json'},
);
