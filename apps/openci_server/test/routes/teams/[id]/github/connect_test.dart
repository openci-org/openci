import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

import '../../../../../routes/teams/[id]/github/connect.dart' as route;

class _MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  test(
    'rejects unauthenticated callers even with a user ID in the body',
    () async {
      final context = TestRequestContext(
        path: '/teams/team-1/github/connect',
        method: HttpMethod.post,
        body: jsonEncode({'userId': 'user-1'}),
      );
      context.provide<String?>(null);

      final response = await route.onRequest(context.context, 'team-1');

      expect(response.statusCode, HttpStatus.unauthorized);
      expect(await response.json(), {
        'success': false,
        'error': 'Authentication required',
      });
    },
  );

  group('authenticated requests', () {
    late AppDatabase db;
    const testEnvironment = {
      'GITHUB_API_BASE_URL': 'https://api.github.com',
      'GITHUB_APP_CLIENT_ID': 'Iv1.test-client-id',
      'GITHUB_OAUTH_REDIRECT_URI': 'https://openci.example/github/callback',
    };

    setUp(() async {
      db = AppDatabase(
        NativeDatabase.memory(
          setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
        ),
      );

      await db.teamDao.createTeamAndMember(
        DriftTeam(
          id: 'team-1',
          name: 'team-1',
          installationIds: const [123],
          aiEnabled: true,
          runNumber: 1,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        'user-1',
      );

      await db.teamDao.createTeamAndMember(
        DriftTeam(
          id: 'team-2',
          name: 'team-2',
          installationIds: const [123],
          aiEnabled: true,
          runNumber: 1,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        'user-2',
      );
    });

    tearDown(() => db.close());

    Future<Response> post({
      String? uid = 'user-1',
      String teamId = 'team-1',
      String? body,
      Map<String, String>? environment,
    }) async {
      final context = TestRequestContext(
        path: '/teams/$teamId/github/connect',
        method: HttpMethod.post,
        body: body,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(uid);
      context.provide<Map<String, String>>(environment ?? testEnvironment);
      return route.onRequest(context.context, teamId);
    }

    test(
      'rejects a non-member even with a member user ID in the body',
      () async {
        final response = await post(
          uid: 'outsider',
          teamId: 'team-1',
          body: jsonEncode({'userId': 'user-1', 'teamId': 'team-1'}),
        );

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {'success': false, 'error': 'Forbidden'});
        expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
      },
    );

    test(
      'rejects access to another team even with own team ID in the body',
      () async {
        final response = await post(
          uid: 'user-1',
          teamId: 'team-2',
          body: jsonEncode({'userId': 'user-1', 'teamId': 'team-1'}),
        );

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {'success': false, 'error': 'Forbidden'});
        expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
      },
    );

    test(
      'rejects a missing team even with an existing team ID in the body',
      () async {
        final response = await post(
          uid: 'user-1',
          teamId: 'missing-team',
          body: jsonEncode({'userId': 'user-1', 'teamId': 'team-1'}),
        );

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {'success': false, 'error': 'Forbidden'});
        expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
      },
    );

    test(
      'stores a connection request and returns its authorization URL',
      () async {
        final response = await post();

        expect(response.statusCode, HttpStatus.ok);
        expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
        final body = await response.json() as Map<String, dynamic>;
        final url = Uri.parse(body['authorizationUrl'] as String);
        final expiresAt = DateTime.parse(body['expiresAt'] as String);
        final savedRequest = await db
            .select(db.gitHubConnectionRequests)
            .getSingle();

        expect(body['success'], isTrue);
        expect(
          body.keys,
          unorderedEquals([
            'success',
            'authorizationUrl',
            'expiresAt',
          ]),
        );
        expect(url.origin, 'https://github.com');
        expect(url.path, '/login/oauth/authorize');
        expect(url.queryParameters['client_id'], 'Iv1.test-client-id');
        expect(
          url.queryParameters['redirect_uri'],
          'https://openci.example/github/callback',
        );
        expect(url.queryParameters['code_challenge_method'], 'S256');
        expect(savedRequest.userId, 'user-1');
        expect(savedRequest.teamId, 'team-1');
        expect(
          savedRequest.stateHash,
          sha256.convert(utf8.encode(url.queryParameters['state']!)).toString(),
        );
        expect(
          base64Url.decode(
            base64Url.normalize(url.queryParameters['code_challenge']!),
          ),
          sha256.convert(ascii.encode(savedRequest.codeVerifier)).bytes,
        );
        expect(expiresAt.isUtc, isTrue);
        expect(
          savedRequest.expiresAt.difference(savedRequest.createdAt),
          const Duration(minutes: 10),
        );
        // SQLite stores these timestamps with second precision.
        expect(
          expiresAt.millisecondsSinceEpoch ~/ 1000,
          savedRequest.expiresAt.millisecondsSinceEpoch ~/ 1000,
        );
        expect(jsonEncode(body), isNot(contains(savedRequest.codeVerifier)));
      },
    );

    test(
      'ignores forged body values for identity and GitHub settings',
      () async {
        final response = await post(
          uid: 'user-2',
          teamId: 'team-2',
          body: jsonEncode({
            'userId': 'user-1',
            'teamId': 'team-1',
            'githubBaseUrl': 'https://attacker.example',
            'clientId': 'attacker-client',
            'redirectUri': 'https://attacker.example/callback',
            'state': 'forged-state',
            'codeVerifier': 'forged-verifier',
            'codeChallenge': 'forged-challenge',
          }),
        );

        expect(response.statusCode, HttpStatus.ok);
        final body = await response.json() as Map<String, dynamic>;
        final url = Uri.parse(body['authorizationUrl'] as String);
        final savedRequest = await db
            .select(db.gitHubConnectionRequests)
            .getSingle();

        expect(savedRequest.userId, 'user-2');
        expect(savedRequest.teamId, 'team-2');
        expect(savedRequest.codeVerifier, isNot('forged-verifier'));
        expect(url.origin, 'https://github.com');
        expect(url.queryParameters['client_id'], 'Iv1.test-client-id');
        expect(
          url.queryParameters['redirect_uri'],
          'https://openci.example/github/callback',
        );
        expect(url.queryParameters['state'], isNot('forged-state'));
        expect(
          url.queryParameters['code_challenge'],
          isNot('forged-challenge'),
        );
      },
    );

    test('uses the operator-configured GHES settings', () async {
      final response = await post(
        environment: {
          ...testEnvironment,
          'GITHUB_API_BASE_URL': 'https://github.enterprise.example/api/v3',
          'GITHUB_APP_CLIENT_ID': 'enterprise-client-id',
          'GITHUB_OAUTH_REDIRECT_URI':
              'https://openci.enterprise.example/github/callback',
        },
      );

      expect(response.statusCode, HttpStatus.ok);
      final body = await response.json() as Map<String, dynamic>;
      final url = Uri.parse(body['authorizationUrl'] as String);
      expect(url.origin, 'https://github.enterprise.example');
      expect(url.path, '/login/oauth/authorize');
      expect(url.queryParameters['client_id'], 'enterprise-client-id');
      expect(
        url.queryParameters['redirect_uri'],
        'https://openci.enterprise.example/github/callback',
      );
    });

    test('rejects a missing client ID without saving a request', () async {
      final response = await post(
        environment: Map.of(testEnvironment)..remove('GITHUB_APP_CLIENT_ID'),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
    });

    test('rejects a blank client ID without saving a request', () async {
      final response = await post(
        environment: {...testEnvironment, 'GITHUB_APP_CLIENT_ID': '   '},
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
    });

    test('rejects a missing callback URL without saving a request', () async {
      final response = await post(
        environment: Map.of(testEnvironment)
          ..remove('GITHUB_OAUTH_REDIRECT_URI'),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
    });

    test('rejects a callback URL without a host', () async {
      final response = await post(
        environment: {
          ...testEnvironment,
          'GITHUB_OAUTH_REDIRECT_URI': 'https:///github/callback',
        },
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
    });

    test('rejects a callback URL with a non-HTTP scheme', () async {
      final response = await post(
        environment: {
          ...testEnvironment,
          'GITHUB_OAUTH_REDIRECT_URI': 'file:///tmp/callback',
        },
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
    });

    test('rejects a callback URL containing credentials', () async {
      final response = await post(
        environment: {
          ...testEnvironment,
          'GITHUB_OAUTH_REDIRECT_URI':
              'https://user:password@openci.example/github/callback',
        },
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
    });

    test('rejects a callback URL containing query parameters', () async {
      final response = await post(
        environment: {
          ...testEnvironment,
          'GITHUB_OAUTH_REDIRECT_URI':
              'https://openci.example/github/callback?teamId=team-2',
        },
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
    });

    test('rejects a callback URL containing a fragment', () async {
      final response = await post(
        environment: {
          ...testEnvironment,
          'GITHUB_OAUTH_REDIRECT_URI':
              'https://openci.example/github/callback#team-2',
        },
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
    });

    test('rolls back the request when the API base URL is invalid', () async {
      final response = await post(
        environment: {
          ...testEnvironment,
          'GITHUB_API_BASE_URL': 'https://api.github.com?unexpected=value',
        },
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
    });

    test('returns a generic error when saving the request fails', () async {
      await db.customStatement('''
        CREATE TRIGGER fail_connection_save
        BEFORE INSERT ON github_connection_requests
        BEGIN
          SELECT RAISE(ABORT, 'private database insert detail');
        END;
      ''');

      final response = await post();

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
    });
  });

  test('returns 500 without leaking database error details', () async {
    final unavailableDb = _MockAppDatabase();
    when(() => unavailableDb.teamDao).thenThrow(
      StateError('private database connection detail'),
    );

    final context = TestRequestContext(
      path: '/teams/team-1/github/connect',
      method: HttpMethod.post,
    );
    context.provide<AppDatabase>(unavailableDb);
    context.provide<String?>('user-1');

    final response = await route.onRequest(context.context, 'team-1');

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(await response.json(), {
      'success': false,
      'error': 'Internal server error',
    });
    verify(() => unavailableDb.teamDao).called(1);
  });

  test('rejects PUT before accessing the database', () async {
    final unusedDb = _MockAppDatabase();
    final context = TestRequestContext(
      path: '/teams/team-1/github/connect',
      method: HttpMethod.put,
    );
    context.provide<AppDatabase>(unusedDb);

    final response = await route.onRequest(context.context, 'team-1');

    expect(response.statusCode, HttpStatus.methodNotAllowed);
    verifyZeroInteractions(unusedDb);
  });
}
