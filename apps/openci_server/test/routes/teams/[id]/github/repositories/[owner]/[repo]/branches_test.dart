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

import '../../../../../../../helpers/database_failure_checks.dart';
import '../../../../../../../../routes/teams/[id]/github/repositories/[owner]/[repo]/branches.dart'
    as branches_route;

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
    accountLogin: 'owner',
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
      path: '/teams/team-123/github/repositories/owner/repo/branches',
      method: HttpMethod.get,
    );
    context.provide<AppDatabase>(db);
    context.provide<String?>('user-1');
    context.provide<Map<String, String>>(testEnv);
    context.provide<http.Client>(client);
    try {
      return await branches_route.onRequest(
        context.context,
        'team-123',
        'owner',
        'repo',
      );
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

    tempDir = Directory.systemTemp.createTempSync('branches_test_');
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

  group('Branches Endpoint', () {
    test(
      'rejects legacy installation IDs without a verified connection',
      () async {
        final response = await get();

        expect(response.statusCode, HttpStatus.badRequest);
        expect(await response.json(), {
          'success': false,
          'error': 'No active GitHub connection for this team',
        });
        expect(requests, isEmpty);
      },
    );

    test('responds with 401 Unauthorized when uid is null', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/github/repositories/owner/repo/branches',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(null);
      context.provide<Map<String, String>>(testEnv);

      final response = await branches_route.onRequest(
        context.context,
        'team-123',
        'owner',
        'repo',
      );
      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('responds with 403 Forbidden when user is not team member', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/github/repositories/owner/repo/branches',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('non-member-user');
      context.provide<Map<String, String>>(testEnv);

      final response = await branches_route.onRequest(
        context.context,
        'team-123',
        'owner',
        'repo',
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test('responds with 200 OK and lists branches from GitHub', () async {
      final team = (await db.teamDao.getTeam('team-123'))!;
      await db.teamDao.updateTeam(team.copyWith(installationIds: const []));
      await db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              id: 'unrelated-connection',
              installationId: 54322,
            ),
          );
      await db.into(db.gitHubConnections).insert(connection);

      final mockHttpClient = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET' &&
            request.url.path == '/repos/owner/repo/installation') {
          return http.Response(jsonEncode({'id': 54321}), 200);
        }
        if (request.method == 'POST' &&
            request.url.path.endsWith('/access_tokens')) {
          return http.Response(
            jsonEncode({'token': 'ghs_mockedtoken123456'}),
            200,
          );
        }

        if (request.method == 'GET' &&
            request.url.path.endsWith('/repos/owner/repo/branches')) {
          return http.Response(
            jsonEncode([
              {'name': 'main'},
              {'name': 'develop'},
              {'name': 'feature/test'},
            ]),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      addTearDown(mockHttpClient.close);
      final context = TestRequestContext(
        path: '/teams/team-123/github/repositories/owner/repo/branches',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('user-1');
      context.provide<Map<String, String>>(testEnv);
      context.provide<http.Client>(mockHttpClient);

      final response = await branches_route.onRequest(
        context.context,
        'team-123',
        'owner',
        'repo',
      );
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(requests.map((request) => request.url.toString()), [
        'https://api.github.com/repos/owner/repo/installation',
        'https://api.github.com/app/installations/54321/access_tokens',
        'https://api.github.com/repos/owner/repo/branches',
      ]);
      expect(
        requests.last.headers['authorization'],
        'Bearer ghs_mockedtoken123456',
      );

      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);
      final branches = body['branches'] as List<dynamic>;
      expect(branches, hasLength(3));
      expect(branches, containsAll(['main', 'develop', 'feature/test']));
    });

    test(
      'rejects another team installation even if listed in legacy IDs',
      () async {
        final team = (await db.teamDao.getTeam('team-123'))!;
        await db.into(db.teams).insert(team.copyWith(id: 'other-team'));
        await db.into(db.gitHubConnections).insert(connection);
        await db
            .into(db.gitHubConnections)
            .insert(
              connection.copyWith(
                id: 'other-team-connection',
                teamId: 'other-team',
                installationId: 98765,
              ),
            );

        final response = await get(
          respond: (_) => http.Response(jsonEncode({'id': 98765}), 200),
        );

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {'success': false, 'error': 'Forbidden'});
        expect(requests.single.url.path, '/repos/owner/repo/installation');
      },
    );

    test(
      'rejects a suspended target even with another active connection',
      () async {
        await db
            .into(db.gitHubConnections)
            .insert(
              connection.copyWith(status: GitHubConnectionStatus.suspended),
            );
        await db
            .into(db.gitHubConnections)
            .insert(
              connection.copyWith(
                id: 'other-connection',
                installationId: 54322,
              ),
            );

        final response = await get(
          respond: (_) => http.Response(jsonEncode({'id': 54321}), 200),
        );

        expect(response.statusCode, HttpStatus.forbidden);
        expect(requests.single.url.path, '/repos/owner/repo/installation');
      },
    );

    test('rejects matching installation IDs for another host or App', () async {
      await db.batch((batch) {
        batch.insertAll(db.gitHubConnections, [
          connection.copyWith(installationId: 54322),
          connection.copyWith(
            id: 'other-host',
            githubApiBaseUrl: 'https://github.example/api/v3',
          ),
          connection.copyWith(id: 'other-app', githubAppId: 42),
        ]);
      });

      final response = await get(
        respond: (_) => http.Response(jsonEncode({'id': 54321}), 200),
      );

      expect(response.statusCode, HttpStatus.forbidden);
      expect(requests.single.url.path, '/repos/owner/repo/installation');
    });

    test(
      'stops when GitHub rejects the repository installation lookup',
      () async {
        await db.into(db.gitHubConnections).insert(connection);

        final response = await get(
          respond: (_) => http.Response('Repository not accessible', 404),
        );

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await response.json(), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(requests.single.url.path, '/repos/owner/repo/installation');
      },
    );

    test('stops when GitHub returns an invalid installation ID', () async {
      await db.into(db.gitHubConnections).insert(connection);

      final response = await get(
        respond: (_) => http.Response(jsonEncode({'id': '54321'}), 200),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(requests.single.url.path, '/repos/owner/repo/installation');
    });

    test('stops when GitHub rejects token creation', () async {
      await db.into(db.gitHubConnections).insert(connection);

      final response = await get(
        respond: (request) {
          if (request.url.path.endsWith('/installation')) {
            return http.Response(jsonEncode({'id': 54321}), 200);
          }
          return http.Response('Installation suspended', 403);
        },
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(requests.map((request) => request.url.path), [
        '/repos/owner/repo/installation',
        '/app/installations/54321/access_tokens',
      ]);
    });

    test(
      'does not try another connection when branch access is rejected',
      () async {
        await db.into(db.gitHubConnections).insert(connection);
        await db
            .into(db.gitHubConnections)
            .insert(
              connection.copyWith(
                id: 'other-connection',
                installationId: 54322,
              ),
            );

        final response = await get(
          respond: (request) {
            if (request.url.path.endsWith('/installation')) {
              return http.Response(jsonEncode({'id': 54321}), 200);
            }
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
        expect(requests.map((request) => request.url.path), [
          '/repos/owner/repo/installation',
          '/app/installations/54321/access_tokens',
          '/repos/owner/repo/branches',
        ]);
      },
    );

    test('uses the normalized operator URL for every GitHub request', () async {
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
        respond: (request) {
          if (request.url.path.endsWith('/installation')) {
            return http.Response(jsonEncode({'id': 54321}), 200);
          }
          if (request.method == 'POST') {
            return http.Response(jsonEncode({'token': 'ghs_test'}), 201);
          }
          return http.Response('[]', 200);
        },
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.json(), {'success': true, 'branches': []});
      expect(requests.map((request) => request.url.toString()), [
        'https://github.example:8443/api/v3/repos/owner/repo/installation',
        'https://github.example:8443/api/v3/app/installations/54321/access_tokens',
        'https://github.example:8443/api/v3/repos/owner/repo/branches',
      ]);
    });
  });

  testDatabaseFailures([
    DatabaseFailureEndpoint(
      '/teams/team-1/github/repositories/owner/repo/branches',
      HttpMethod.get,
      (c) => branches_route.onRequest(c, 'team-1', 'owner', 'repo'),
    ),
  ]);
}
