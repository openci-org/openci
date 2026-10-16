import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

import '../../../routes/_middleware.dart' as root;
import '../../../routes/github/callback.dart' as route;

void main() {
  late AppDatabase db;
  late Map<String, String> environment;
  late MockClient githubClient;
  late List<http.Request> tokenRequests;
  late http.Response tokenResponse;
  const state = 'connection-state';

  setUp(() async {
    environment = {
      'GITHUB_API_BASE_URL': 'https://api.github.com',
      'GITHUB_APP_CLIENT_ID': 'Iv1.test-client',
      'GITHUB_APP_CLIENT_SECRET': 'private-client-secret',
      'GITHUB_OAUTH_REDIRECT_URI': 'https://openci.example/github/callback',
    };
    tokenRequests = [];
    tokenResponse = http.Response(
      '{"access_token":"private-user-token","token_type":"bearer"}',
      HttpStatus.ok,
    );
    githubClient = MockClient((request) async {
      tokenRequests.add(request);
      return tokenResponse;
    });
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
    await db
        .into(db.gitHubConnectionRequests)
        .insert(
          DriftGitHubConnectionRequest(
            id: 'request-1',
            userId: 'user-1',
            teamId: 'team-1',
            stateHash: sha256.convert(utf8.encode(state)).toString(),
            codeVerifier: 'private-code-verifier',
            createdAt: now,
            expiresAt: now.add(const Duration(minutes: 10)),
          ),
        );
  });

  tearDown(() => db.close());

  Future<Response> callback(RequestContext context) {
    return http.runWithClient(
      () => route.onRequest(context),
      () => githubClient,
    );
  }

  Future<Response> get(String query) {
    final context = TestRequestContext(path: '/github/callback?$query');
    context.provide<AppDatabase>(db);
    context.provide<Map<String, String>>(environment);
    return callback(context.context);
  }

  test(
    'accepts the browser callback without a Firebase bearer token',
    () async {
      final handler = callback
          .use(root.databaseProvider(db))
          .use(root.authProvider(null))
          .use(provider<Map<String, String>>((_) => environment))
          .use(
            provider<InternalApiKeyValidator>(
              (_) => const InternalApiKeyValidator.forTesting(environment: {}),
            ),
          )
          .use(root.requestLoggingMiddleware());
      final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final client = http.Client();
      addTearDown(client.close);

      final response = await client.get(
        Uri(
          scheme: 'http',
          host: server.address.address,
          port: server.port,
          path: '/github/callback',
          queryParameters: {'state': state, 'code': 'authorization-code'},
        ),
      );

      expect(response.statusCode, HttpStatus.notImplemented);
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'GitHub connection completion is not implemented yet',
      });
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(response.headers['referrer-policy'], 'no-referrer');
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
      expect(tokenRequests.single.bodyFields['code'], 'authorization-code');
      expect(
        tokenRequests.single.bodyFields['code_verifier'],
        'private-code-verifier',
      );
    },
  );

  test(
    'uses the stored verifier and operator settings despite query overrides',
    () async {
      environment['GITHUB_API_BASE_URL'] = 'https://github.example/api/v3';

      final response = await get(
        'state=$state&code=authorization-code'
        '&code_verifier=forged-verifier&client_secret=forged-secret'
        '&client_id=forged-client&redirect_uri=https%3A%2F%2Fother.example'
        '&githubBaseUrl=https%3A%2F%2Fother.example',
      );

      expect(response.statusCode, HttpStatus.notImplemented);
      final request = tokenRequests.single;
      expect(
        request.url.toString(),
        'https://github.example/login/oauth/access_token',
      );
      expect(request.bodyFields, {
        'client_id': 'Iv1.test-client',
        'client_secret': 'private-client-secret',
        'redirect_uri': 'https://openci.example/github/callback',
        'code': 'authorization-code',
        'code_verifier': 'private-code-verifier',
      });
    },
  );

  test(
    'returns a safe 502 and prevents retry after an exchange failure',
    () async {
      tokenResponse = http.Response(
        '{"error":"bad_verification_code",'
        '"error_description":"private-upstream-detail"}',
        HttpStatus.ok,
      );

      final response = await get('state=$state&code=authorization-code');

      expect(response.statusCode, HttpStatus.badGateway);
      expect(await response.json(), {
        'success': false,
        'error': 'Failed to exchange GitHub authorization code',
      });
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(response.headers['referrer-policy'], 'no-referrer');
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);

      final repeated = await get('state=$state&code=authorization-code');

      expect(repeated.statusCode, HttpStatus.badRequest);
      expect(tokenRequests, hasLength(1));
    },
  );

  test('returns a safe 502 when the GitHub request fails', () async {
    githubClient = MockClient((request) async {
      tokenRequests.add(request);
      throw http.ClientException('private-client-secret and private-code');
    });

    final response = await get('state=$state&code=authorization-code');

    expect(response.statusCode, HttpStatus.badGateway);
    expect(await response.json(), {
      'success': false,
      'error': 'Failed to exchange GitHub authorization code',
    });
    expect(tokenRequests, hasLength(1));
  });

  test('returns a generic 500 when the client secret is missing', () async {
    environment.remove('GITHUB_APP_CLIENT_SECRET');

    final response = await get('state=$state&code=authorization-code');

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(await response.json(), {
      'success': false,
      'error': 'Internal server error',
    });
    expect(tokenRequests, isEmpty);
  });

  test('rejects a callback whose state was already consumed', () async {
    await get('state=$state&code=authorization-code');

    final response = await get('state=$state&code=authorization-code');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await response.json(), {
      'success': false,
      'error': 'Invalid or expired GitHub state',
    });
    expect(tokenRequests, hasLength(1));
  });

  test('rejects unknown state without consuming another request', () async {
    final response = await get('state=unknown&code=authorization-code');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
  });

  test('rejects expired state', () async {
    await db
        .update(db.gitHubConnectionRequests)
        .write(
          GitHubConnectionRequestsCompanion(
            expiresAt: Value(
              DateTime.now().subtract(const Duration(seconds: 1)),
            ),
          ),
        );

    final response = await get('state=$state&code=authorization-code');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await response.json(), {
      'success': false,
      'error': 'Invalid or expired GitHub state',
    });
    expect(tokenRequests, isEmpty);
  });

  test('rejects missing state', () async {
    final response = await get('code=authorization-code');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(tokenRequests, isEmpty);
  });

  test('rejects blank state', () async {
    final response = await get('state=%20&code=authorization-code');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(tokenRequests, isEmpty);
  });

  test('rejects missing code without consuming state', () async {
    final response = await get('state=$state');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
  });

  test('rejects blank code without consuming state', () async {
    final response = await get('state=$state&code=%20');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
  });

  test('rejects duplicate state parameters', () async {
    final response = await get('state=$state&state=other&code=code');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
  });

  test('rejects duplicate code parameters without consuming state', () async {
    final response = await get('state=$state&code=first&code=second');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
  });

  test(
    'consumes denied authorization without reflecting error details',
    () async {
      final response = await get(
        'state=$state&error=access_denied&error_description=private-detail',
      );

      expect(response.statusCode, HttpStatus.badRequest);
      expect(await response.json(), {
        'success': false,
        'error': 'GitHub authorization failed',
      });
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(response.headers['referrer-policy'], 'no-referrer');
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
      expect(tokenRequests, isEmpty);
    },
  );

  test('rejects duplicate error parameters without consuming state', () async {
    final response = await get('state=$state&error=first&error=second');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
  });

  test('rejects blank error without consuming state', () async {
    final response = await get('state=$state&error=');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
  });

  test('rejects conflicting code and error without consuming state', () async {
    final response = await get('state=$state&code=code&error=access_denied');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
  });

  test('rejects a removed member despite forged callback identity', () async {
    await db.delete(db.teamMembers).go();
    await db.teamDao.addTeamMember('team-1', 'other-user');

    final response = await get(
      'state=$state&code=code&userId=other-user&teamId=team-1',
    );

    expect(response.statusCode, HttpStatus.forbidden);
    expect(await response.json(), {'success': false, 'error': 'Forbidden'});
    expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
    expect(tokenRequests, isEmpty);
  });

  test(
    'returns a generic 500 response when the database query fails',
    () async {
      await db.customStatement('DROP TABLE github_connection_requests');

      final response = await get('state=$state&code=authorization-code');

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(response.headers['referrer-policy'], 'no-referrer');
      expect(tokenRequests, isEmpty);
    },
  );

  test('rejects POST before accessing the database', () async {
    final context = TestRequestContext(
      path: '/github/callback?state=$state&code=code',
      method: HttpMethod.post,
    );

    final response = await callback(context.context);

    expect(response.statusCode, HttpStatus.methodNotAllowed);
    expect(tokenRequests, isEmpty);
  });
}
