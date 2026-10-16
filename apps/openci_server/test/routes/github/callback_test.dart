import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

import '../../../routes/_middleware.dart' as root;
import '../../../routes/github/callback.dart' as route;

class _MockStdout extends Mock implements Stdout {}

void main() {
  late AppDatabase db;
  late Map<String, String> environment;
  late MockClient githubClient;
  late List<http.Request> tokenRequests;
  late List<http.Request> userRequests;
  late http.Response tokenResponse;
  late http.Response userResponse;
  const state = 'connection-state';

  setUp(() async {
    environment = {
      'GITHUB_API_BASE_URL': 'https://api.github.com',
      'GITHUB_APP_CLIENT_ID': 'Iv1.test-client',
      'GITHUB_APP_CLIENT_SECRET': 'private-client-secret',
      'GITHUB_OAUTH_REDIRECT_URI': 'https://openci.example/github/callback',
      'GITHUB_CONNECTION_RETURN_URL':
          'https://dashboard.example/github/connection',
      'SECRET_ENCRYPTION_KEY': base64Encode(List<int>.filled(32, 1)),
    };
    tokenRequests = [];
    userRequests = [];
    tokenResponse = http.Response(
      '{"access_token":"private-user-token","token_type":"bearer"}',
      HttpStatus.ok,
    );
    userResponse = http.Response(
      '{"id":123,"login":"octocat"}',
      HttpStatus.ok,
    );
    githubClient = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.path.endsWith('/login/oauth/access_token')) {
        tokenRequests.add(request);
        return tokenResponse;
      }
      if (request.method == 'GET' && request.url.path.endsWith('/user')) {
        userRequests.add(request);
        return userResponse;
      }
      fail('Unexpected GitHub request: ${request.method} ${request.url.path}');
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
    'redirects the browser callback without exposing the reference to the Dashboard server',
    () async {
      final dashboardRequests = <Uri>[];
      final dashboard = await serve(
        (context) {
          dashboardRequests.add(context.request.uri);
          return Response(body: 'Dashboard');
        },
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => dashboard.close(force: true));
      environment['GITHUB_CONNECTION_RETURN_URL'] = Uri(
        scheme: 'http',
        host: dashboard.address.address,
        port: dashboard.port,
        path: '/github/connection',
      ).toString();

      final handler = callback
          .use(root.databaseProvider(db))
          .use(root.authProvider(null))
          .use(provider<Map<String, String>>((_) => environment))
          .use(
            provider<InternalApiKeyValidator>(
              (_) => const InternalApiKeyValidator(environment: {}),
            ),
          )
          .use(root.requestLoggingMiddleware());
      final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final client = http.Client();
      addTearDown(client.close);

      final request = http.Request(
        'GET',
        Uri(
          scheme: 'http',
          host: server.address.address,
          port: server.port,
          path: '/github/callback',
          queryParameters: {'state': state, 'code': 'authorization-code'},
        ),
      )..followRedirects = false;
      final response = await http.Response.fromStream(
        await client.send(request),
      );

      expect(response.statusCode, HttpStatus.seeOther);
      expect(response.body, isEmpty);
      final location = Uri.parse(response.headers[HttpHeaders.locationHeader]!);
      expect(
        location.removeFragment().toString(),
        environment['GITHUB_CONNECTION_RETURN_URL'],
      );
      expect(location.hasQuery, isFalse);
      final fragment = Uri.splitQueryString(location.fragment);
      expect(fragment, {
        'reference': isA<String>(),
      });
      final reference = fragment['reference']!;
      expect(reference, matches(r'^[A-Za-z0-9_-]{43}$'));
      expect(reference, isNot(state));
      expect(reference, isNot('request-1'));
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(response.headers['referrer-policy'], 'no-referrer');
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
      expect(tokenRequests.single.bodyFields['code'], 'authorization-code');
      expect(
        tokenRequests.single.bodyFields['code_verifier'],
        'private-code-verifier',
      );
      final userRequest = userRequests.single;
      expect(userRequest.method, 'GET');
      expect(userRequest.url.toString(), 'https://api.github.com/user');
      expect(userRequest.headers['Authorization'], 'Bearer private-user-token');
      final session = await db.select(db.gitHubConnectionSessions).getSingle();
      expect(session.userId, 'user-1');
      expect(session.teamId, 'team-1');
      expect(session.githubUserId, 123);
      expect(
        session.referenceHash,
        sha256.convert(utf8.encode(reference)).toString(),
      );
      expect(session.encryptedAccessToken, isNot('private-user-token'));
      expect(
        await SecretCrypter(environment['SECRET_ENCRYPTION_KEY']!).decrypt(
          session.encryptedAccessToken!,
        ),
        'private-user-token',
      );
      expect(
        session.expiresAt.difference(session.createdAt),
        const Duration(minutes: 10),
      );
      expect(session.consumedAt, isNull);
      expect((await db.teamDao.getTeam('team-1'))!.installationIds, isEmpty);

      final landing = await client.get(location);

      expect(landing.statusCode, HttpStatus.ok);
      expect(landing.body, 'Dashboard');
      final dashboardRequest = dashboardRequests.single;
      expect(dashboardRequest.path, '/github/connection');
      expect(dashboardRequest.hasQuery, isFalse);
      expect(dashboardRequest.hasFragment, isFalse);
      expect(dashboardRequest.toString(), isNot(contains(reference)));
    },
  );

  test(
    'uses the stored verifier and operator settings despite query and header overrides',
    () async {
      environment['GITHUB_API_BASE_URL'] = 'https://github.example/api/v3';

      final context = TestRequestContext(
        path:
            '/github/callback?state=$state&code=authorization-code'
            '&code_verifier=forged-verifier&client_secret=forged-secret'
            '&client_id=forged-client&redirect_uri=https%3A%2F%2Fother.example'
            '&githubBaseUrl=https%3A%2F%2Fother.example'
            '&access_token=forged-token&githubUserId=999&login=forged-login'
            '&userId=forged-user&teamId=forged-team&reference=forged-reference'
            '&returnUrl=https%3A%2F%2Fother.example',
        headers: {
          HttpHeaders.hostHeader: 'other.example',
          'Origin': 'https://other.example',
          HttpHeaders.refererHeader: 'https://other.example/',
          'X-Forwarded-Host': 'other.example',
        },
      );
      context.provide<AppDatabase>(db);
      context.provide<Map<String, String>>(environment);

      final response = await callback(context.context);

      expect(response.statusCode, HttpStatus.seeOther);
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
      final userRequest = userRequests.single;
      expect(
        userRequest.url.toString(),
        'https://github.example/api/v3/user',
      );
      expect(userRequest.headers['Authorization'], 'Bearer private-user-token');
      final session = await db.select(db.gitHubConnectionSessions).getSingle();
      expect(session.userId, 'user-1');
      expect(session.teamId, 'team-1');
      expect(session.githubUserId, 123);
      expect(
        await SecretCrypter(environment['SECRET_ENCRYPTION_KEY']!).decrypt(
          session.encryptedAccessToken!,
        ),
        'private-user-token',
      );
      final location = Uri.parse(response.headers[HttpHeaders.locationHeader]!);
      expect(
        location.removeFragment().toString(),
        environment['GITHUB_CONNECTION_RETURN_URL'],
      );
      final fragment = Uri.splitQueryString(location.fragment);
      expect(fragment['reference'], isNot('forged-reference'));
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
      expect(response.headers[HttpHeaders.locationHeader], isNull);
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
      expect(userRequests, isEmpty);
      expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
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
    expect(userRequests, isEmpty);
  });

  test(
    'returns a safe 502 and prevents retry after user lookup fails',
    () async {
      userResponse = http.Response(
        '{"message":"private-user-token and private-upstream-detail"}',
        HttpStatus.unauthorized,
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      );

      final response = await get('state=$state&code=authorization-code');

      expect(response.statusCode, HttpStatus.badGateway);
      expect(await response.json(), {
        'success': false,
        'error': 'Failed to fetch GitHub user',
      });
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(response.headers['referrer-policy'], 'no-referrer');
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);

      final repeated = await get('state=$state&code=authorization-code');

      expect(repeated.statusCode, HttpStatus.badRequest);
      expect(tokenRequests, hasLength(1));
      expect(userRequests, hasLength(1));
      expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
    },
  );

  test('returns a safe 502 when the user lookup cannot connect', () async {
    githubClient = MockClient((request) async {
      if (request.method == 'POST') {
        tokenRequests.add(request);
        return tokenResponse;
      }
      userRequests.add(request);
      throw http.ClientException('private-user-token and private-user-detail');
    });

    final response = await get('state=$state&code=authorization-code');

    expect(response.statusCode, HttpStatus.badGateway);
    expect(await response.json(), {
      'success': false,
      'error': 'Failed to fetch GitHub user',
    });
    expect(tokenRequests, hasLength(1));
    expect(userRequests, hasLength(1));
  });

  test(
    'rejects an invalid GitHub identity despite forged query values',
    () async {
      userResponse = http.Response('{"login":"octocat"}', HttpStatus.ok);

      final response = await get(
        'state=$state&code=authorization-code'
        '&userId=user-1&githubUserId=123&id=123&login=forged-login',
      );

      expect(response.statusCode, HttpStatus.badGateway);
      expect(await response.json(), {
        'success': false,
        'error': 'Failed to fetch GitHub user',
      });
      expect(tokenRequests, hasLength(1));
      expect(userRequests, hasLength(1));
    },
  );

  test('returns a generic 500 when the client secret is missing', () async {
    environment.remove('GITHUB_APP_CLIENT_SECRET');

    final response = await get('state=$state&code=authorization-code');

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(await response.json(), {
      'success': false,
      'error': 'Internal server error',
    });
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
  });

  test('rejects a callback whose state was already consumed', () async {
    final first = await get('state=$state&code=authorization-code');
    expect(first.statusCode, HttpStatus.seeOther);

    final response = await get('state=$state&code=authorization-code');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(response.headers[HttpHeaders.locationHeader], isNull);
    expect(await response.json(), {
      'success': false,
      'error': 'Invalid or expired GitHub state',
    });
    expect(tokenRequests, hasLength(1));
    expect(userRequests, hasLength(1));
    expect(await db.select(db.gitHubConnectionSessions).get(), hasLength(1));
  });

  test('rejects a missing return URL without consuming state', () async {
    environment.remove('GITHUB_CONNECTION_RETURN_URL');

    final response = await get(
      'state=$state&code=authorization-code'
      '&returnUrl=https%3A%2F%2Fother.example',
    );

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(response.headers[HttpHeaders.locationHeader], isNull);
    expect(await response.json(), {
      'success': false,
      'error': 'Internal server error',
    });
    expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
    expect(response.headers['referrer-policy'], 'no-referrer');
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
  });

  test(
    'rejects an unsafe return URL without logging its credentials',
    () async {
      environment['GITHUB_CONNECTION_RETURN_URL'] =
          'https://user:private-password@dashboard.example/';
      final errorOutput = _MockStdout();

      final response = await IOOverrides.runZoned(
        () => get('state=$state&code=authorization-code'),
        stderr: () => errorOutput,
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(response.headers[HttpHeaders.locationHeader], isNull);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      final logged = verify(
        () => errorOutput.writeln(captureAny()),
      ).captured.join('\n');
      expect(logged, contains('GITHUB_CONNECTION_RETURN_URL'));
      expect(logged, isNot(contains('private-password')));
      expect(tokenRequests, isEmpty);
      expect(userRequests, isEmpty);
      expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
      expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
    },
  );

  test('rejects a missing encryption key before contacting GitHub', () async {
    environment.remove('SECRET_ENCRYPTION_KEY');

    final response = await get('state=$state&code=authorization-code');

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(await response.json(), {
      'success': false,
      'error': 'Internal server error',
    });
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
    expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
    expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
  });

  test(
    'does not expose an invalid encryption key in responses or logs',
    () async {
      environment['SECRET_ENCRYPTION_KEY'] = 'private-encryption-key!';
      final errorOutput = _MockStdout();

      final response = await IOOverrides.runZoned(
        () => get('state=$state&code=authorization-code'),
        stderr: () => errorOutput,
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      final logged = verify(
        () => errorOutput.writeln(captureAny()),
      ).captured.join('\n');
      expect(
        logged,
        contains('GitHub connection encryption is not configured'),
      );
      expect(logged, isNot(contains('private-encryption-key!')));
      expect(tokenRequests, isEmpty);
      expect(userRequests, isEmpty);
      expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
    },
  );

  test(
    'does not create a session if membership is removed during GitHub lookup',
    () async {
      githubClient = MockClient((request) async {
        if (request.method == 'POST') {
          tokenRequests.add(request);
          return tokenResponse;
        }
        userRequests.add(request);
        await db.delete(db.teamMembers).go();
        return userResponse;
      });

      final response = await get('state=$state&code=authorization-code');

      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.json(), {'success': false, 'error': 'Forbidden'});
      expect(tokenRequests, hasLength(1));
      expect(userRequests, hasLength(1));
      expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
    },
  );

  test(
    'does not return a reference or leak details when session storage fails',
    () async {
      await db.customStatement('''
      CREATE TRIGGER reject_connection_session
      BEFORE INSERT ON github_connection_sessions
      BEGIN
        SELECT RAISE(ABORT, 'private-user-token database detail');
      END
    ''');
      final errorOutput = _MockStdout();

      final response = await IOOverrides.runZoned(
        () => get('state=$state&code=authorization-code'),
        stderr: () => errorOutput,
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      final logged = verify(
        () => errorOutput.writeln(captureAny()),
      ).captured.join('\n');
      expect(logged, contains('Failed to create GitHub connection session'));
      expect(logged, isNot(contains('private-user-token')));
      expect(response.headers[HttpHeaders.locationHeader], isNull);
      expect(tokenRequests, hasLength(1));
      expect(userRequests, hasLength(1));
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
      expect(await db.select(db.gitHubConnectionSessions).get(), isEmpty);
      expect((await db.teamDao.getTeam('team-1'))!.installationIds, isEmpty);
    },
  );

  test('rejects unknown state without consuming another request', () async {
    final response = await get('state=unknown&code=authorization-code');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
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
    expect(userRequests, isEmpty);
  });

  test('rejects missing state', () async {
    final response = await get('code=authorization-code');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
  });

  test('rejects blank state', () async {
    final response = await get('state=%20&code=authorization-code');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
  });

  test('rejects missing code without consuming state', () async {
    final response = await get('state=$state');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
  });

  test('rejects blank code without consuming state', () async {
    final response = await get('state=$state&code=%20');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
  });

  test('rejects duplicate state parameters', () async {
    final response = await get('state=$state&state=other&code=code');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
  });

  test('rejects duplicate code parameters without consuming state', () async {
    final response = await get('state=$state&code=first&code=second');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
  });

  test(
    'consumes denied authorization without reflecting error details',
    () async {
      final response = await get(
        'state=$state&error=access_denied&error_description=private-detail',
      );

      expect(response.statusCode, HttpStatus.badRequest);
      expect(response.headers[HttpHeaders.locationHeader], isNull);
      expect(await response.json(), {
        'success': false,
        'error': 'GitHub authorization failed',
      });
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(response.headers['referrer-policy'], 'no-referrer');
      expect(await db.select(db.gitHubConnectionRequests).get(), isEmpty);
      expect(tokenRequests, isEmpty);
      expect(userRequests, isEmpty);
    },
  );

  test('rejects duplicate error parameters without consuming state', () async {
    final response = await get('state=$state&error=first&error=second');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
  });

  test('rejects blank error without consuming state', () async {
    final response = await get('state=$state&error=');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
  });

  test('rejects conflicting code and error without consuming state', () async {
    final response = await get('state=$state&code=code&error=access_denied');

    expect(response.statusCode, HttpStatus.badRequest);
    expect(await db.select(db.gitHubConnectionRequests).get(), hasLength(1));
    expect(tokenRequests, isEmpty);
    expect(userRequests, isEmpty);
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
    expect(userRequests, isEmpty);
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
      expect(userRequests, isEmpty);
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
    expect(userRequests, isEmpty);
  });
}
