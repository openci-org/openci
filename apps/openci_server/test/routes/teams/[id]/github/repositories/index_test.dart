import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../../../helpers/database_failure_checks.dart';
import '../../../../../../routes/teams/[id]/github/repositories/index.dart'
    as repositories_route;

const testRsaPrivateKey = '''
-----BEGIN PRIVATE KEY-----
MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBANiAAR187atVXowj
f+vCsYaoXkXkaxt1TPYiEa6r8NY1no2sQUa1X281FhNdYFlsCjAot4OBgGKe6GHx
R/qL2ifaSReCAf8DpqDi6SMMOjg+Owrya44E0Ld/SEVHyDy8PnLTmI2ijydhptjK
slf33COCWnIE88OQutWM3/OyMkrRAgMBAAECgYEAg/2OMH8gmusiCEgATijVeGYf
i3bVwdjCwfBFXXtgCgiIkJDq/wPGmhMAUXAFNJ9EmtXIA/mo3vdIb6XdHyeyKKi9
LRly8gHlowdJ5HTbjrBCJlpPTG/Hxo1+3Q+W50240LyuZLByOy7AABr86bIq8Xxo
F4U13aHYhPkI15pvEt0CQQDuLZvZ1i7JZB/KfUhM3pgsnApFxRFcGCwOG7bVXAM5
+fkLnAENP/yWzawD/HOctDxzQ7qdcSWlx0Ux2Ww9n4nDAkEA6LMkhxcnVAM7y6aQ
u6eKcHSJxDmFbHJoxVyyVlVynL9qDgKTckZvvzLopgBo7VawsqyC0YV7XZTxgsvV
wzK72wJAJjBR6N+aqNfQ8RqdWRXnuF9clks+uVF23tw6uIMEUWtvLxlYYdN8oIFh
r1HvB5UujByz80KNEsOcqJ1/6XGHGQJBANzLXhVwOrjUeKA7Y4kq54jcivvNOHQ1
+oOJ+Q1B9oYUeaThfNYpT060F1urd+P7JZ3jYh078lpRQPdCQYn9UZECQENnF2pp
Gl92V3wIHINZYD6o97L+/6Cw3H7TvkikX3bQf1vKy4P7+rE89jEAgA0jrMWPu6WG
Vtdh93Euj6RHtUE=
-----END PRIVATE KEY-----
''';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late File privateKeyFile;
  late Map<String, String> testEnv;
  late List<http.Request> requests;

  final connection = DriftGitHubConnection(
    id: 'connection-1',
    teamId: 'team-123',
    githubApiBaseUrl: 'https://api.github.com',
    githubAppId: 123456,
    installationId: 54321,
    accountId: 42,
    accountType: GitHubAccountType.organization,
    accountLogin: 'openci-org',
    verifiedByUserId: 'user-1',
    verifiedByGitHubUserId: 100,
    verifiedAt: DateTime.utc(2026),
    status: GitHubConnectionStatus.active,
  );

  Future<Response> get({
    http.Response Function(http.Request)? respond,
  }) async {
    final client = MockClient((request) async {
      requests.add(request);
      return respond?.call(request) ?? http.Response('Unexpected request', 500);
    });
    final context = TestRequestContext(
      path: '/teams/team-123/github/repositories',
      method: HttpMethod.get,
    );
    context.provide<AppDatabase>(db);
    context.provide<String?>('user-1');
    context.provide<Map<String, String>>(testEnv);
    context.provide<http.Client>(client);
    try {
      return await repositories_route.onRequest(context.context, 'team-123');
    } finally {
      client.close();
    }
  }

  setUp(() async {
    requests = [];
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-123',
        name: 'Test Team',
        installationIds: const [98765],
        aiEnabled: false,
        runNumber: 1,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
      'user-1',
    );

    tempDir = Directory.systemTemp.createTempSync('repositories_test_');
    privateKeyFile = File(p.join(tempDir.path, 'private_key.pem'));
    privateKeyFile.writeAsStringSync(testRsaPrivateKey);

    testEnv = {
      'GITHUB_APP_ID': '123456',
      'GITHUB_PRIVATE_KEY_PATH': privateKeyFile.path,
      'GITHUB_API_BASE_URL': 'https://api.github.com',
    };
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Repositories Endpoint', () {
    test('responds with 401 Unauthorized when uid is null', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/github/repositories',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(null);
      context.provide<Map<String, String>>(testEnv);

      final response = await repositories_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('responds with 403 Forbidden when user is not team member', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/github/repositories',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('non-member-user');
      context.provide<Map<String, String>>(testEnv);

      final response = await repositories_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test(
      'rejects legacy installation IDs without a verified connection',
      () async {
        final response = await get();

        expect(response.statusCode, equals(HttpStatus.badRequest));
        expect(await response.json(), {
          'success': false,
          'error': 'No active GitHub connection for this team',
        });
        expect(requests, isEmpty);
      },
    );

    test('lists repositories using a verified connection', () async {
      final team = (await db.teamDao.getTeam('team-123'))!;
      await db.teamDao.updateTeam(team.copyWith(installationIds: const []));
      await db.into(db.gitHubConnections).insert(connection);

      final mockHttpClient = MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST' &&
            request.url.path.endsWith('/access_tokens')) {
          return http.Response(
            jsonEncode({'token': 'ghs_mockedtoken123456'}),
            200,
          );
        }

        if (request.method == 'GET' &&
            request.url.path.endsWith('/installation/repositories')) {
          return http.Response(
            jsonEncode({
              'repositories': [
                {
                  'id': 1296269,
                  'name': 'Hello-World',
                  'full_name': 'octocat/Hello-World',
                  'private': true,
                  'owner': {
                    'login': 'octocat',
                  },
                  'default_branch': 'master',
                },
                {
                  'id': 99999,
                  'name': 'Spoon-Knife',
                  'full_name': 'octocat/Spoon-Knife',
                  'private': false,
                  'owner': {
                    'login': 'octocat',
                  },
                  'default_branch': 'main',
                },
              ],
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      addTearDown(mockHttpClient.close);
      final context = TestRequestContext(
        path: '/teams/team-123/github/repositories',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('user-1');
      context.provide<Map<String, String>>(testEnv);
      context.provide<http.Client>(mockHttpClient);

      final response = await repositories_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(requests.map((request) => request.url.toString()), [
        'https://api.github.com/app/installations/54321/access_tokens',
        'https://api.github.com/installation/repositories',
      ]);
      expect(
        requests.last.headers['authorization'],
        'Bearer ghs_mockedtoken123456',
      );

      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);
      final repositories = body['repositories'] as List<dynamic>;
      expect(repositories, hasLength(2));
      expect(repositories[0]['fullName'], equals('octocat/Hello-World'));
      expect(repositories[0]['name'], equals('Hello-World'));
      expect(repositories[0]['owner'], equals('octocat'));
      expect(repositories[0]['private'], isTrue);
      expect(repositories[0]['defaultBranch'], equals('master'));

      expect(repositories[1]['fullName'], equals('octocat/Spoon-Knife'));
      expect(repositories[1]['name'], equals('Spoon-Knife'));
      expect(repositories[1]['owner'], equals('octocat'));
      expect(repositories[1]['private'], isFalse);
      expect(repositories[1]['defaultBranch'], equals('main'));
    });

    test(
      'uses only matching active connections and combines their repositories',
      () async {
        final team = (await db.teamDao.getTeam('team-123'))!;
        await db.into(db.teams).insert(team.copyWith(id: 'other-team'));
        await db.batch((batch) {
          batch.insertAll(db.gitHubConnections, [
            connection,
            connection.copyWith(id: 'second-connection', installationId: 54322),
            connection.copyWith(
              id: 'other-team',
              teamId: 'other-team',
              installationId: 98765,
            ),
            connection.copyWith(
              id: 'suspended',
              installationId: 200,
              status: GitHubConnectionStatus.suspended,
            ),
            connection.copyWith(
              id: 'removed',
              installationId: 201,
              status: GitHubConnectionStatus.removed,
            ),
            connection.copyWith(
              id: 'other-host',
              installationId: 300,
              githubApiBaseUrl: 'https://github.example/api/v3',
            ),
            connection.copyWith(
              id: 'other-app',
              installationId: 400,
              githubAppId: 42,
            ),
          ]);
        });

        final response = await get(
          respond: (request) {
            if (request.method == 'POST') {
              return http.Response(jsonEncode({'token': 'ghs_test'}), 201);
            }
            return http.Response(
              jsonEncode({
                'repositories': [
                  {'full_name': 'openci-org/shared-repo'},
                ],
              }),
              200,
            );
          },
        );

        expect(response.statusCode, HttpStatus.ok);
        expect(
          requests
              .where((request) => request.method == 'POST')
              .map((request) => request.url.path),
          unorderedEquals([
            '/app/installations/54321/access_tokens',
            '/app/installations/54322/access_tokens',
          ]),
        );
        final body = await response.json() as Map<String, dynamic>;
        final repositories = body['repositories'] as List<dynamic>;
        expect(repositories, hasLength(1));
        expect(repositories.single['fullName'], 'openci-org/shared-repo');
      },
    );

    test('uses the normalized operator URL including its API path', () async {
      testEnv['GITHUB_API_BASE_URL'] =
          ' https://github.example:8443/api/v3/// ';
      await db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              githubApiBaseUrl: 'https://github.example:8443/api/v3',
            ),
          );

      final response = await get(
        respond: (request) => http.Response(
          jsonEncode(
            request.method == 'POST'
                ? {'token': 'ghs_test'}
                : {'repositories': []},
          ),
          200,
        ),
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(requests.map((request) => request.url.toString()), [
        'https://github.example:8443/api/v3/app/installations/54321/access_tokens',
        'https://github.example:8443/api/v3/installation/repositories',
      ]);
    });

    test('fails when GitHub rejects installation token creation', () async {
      await db.into(db.gitHubConnections).insert(connection);

      final response = await get(
        respond: (_) => http.Response('Installation removed', 404),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(requests.single.method, 'POST');
    });

    test('fails when GitHub rejects repository access', () async {
      await db.into(db.gitHubConnections).insert(connection);

      final response = await get(
        respond: (request) {
          if (request.method == 'POST') {
            return http.Response(jsonEncode({'token': 'ghs_test'}), 201);
          }
          return http.Response('Permission denied', 403);
        },
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(requests, hasLength(2));
    });

    test(
      'does not return partial success when another connection fails',
      () async {
        await db.into(db.gitHubConnections).insert(connection);
        await db
            .into(db.gitHubConnections)
            .insert(
              connection.copyWith(
                id: 'second-connection',
                installationId: 54322,
              ),
            );
        var tokenRequests = 0;

        final response = await get(
          respond: (request) {
            if (request.method == 'POST') {
              tokenRequests++;
              if (tokenRequests == 2) {
                return http.Response('Installation suspended', 403);
              }
              return http.Response(jsonEncode({'token': 'ghs_test'}), 201);
            }
            return http.Response(
              jsonEncode({
                'repositories': [
                  {'full_name': 'openci-org/first-repo'},
                ],
              }),
              200,
            );
          },
        );

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await response.json(), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(requests, hasLength(3));
      },
    );

    test(
      'rejects missing operator configuration before contacting GitHub',
      () async {
        await db.into(db.gitHubConnections).insert(connection);
        testEnv.remove('GITHUB_APP_ID');

        final response = await get();

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(requests, isEmpty);
      },
    );

    test(
      'reports connection lookup failures before contacting GitHub',
      () async {
        await db.customStatement('DROP TABLE github_connections');

        final response = await get();

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await response.json(), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(requests, isEmpty);
      },
    );
  });

  testDatabaseFailures([
    DatabaseFailureEndpoint(
      '/teams/team-1/github/repositories',
      HttpMethod.get,
      (c) => repositories_route.onRequest(c, 'team-1'),
    ),
  ]);
}
