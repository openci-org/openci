import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/database.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../../routes/teams/[id]/workflows.dart' as workflows_route;

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

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.teams)
        .insert(
          DriftTeam(
            id: 'team-123',
            name: 'Test Team',
            installationIds: const [98765],
            aiEnabled: false,
            runNumber: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

    tempDir = Directory.systemTemp.createTempSync('workflows_test_');
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

  group('workflow lookup failures and installations', () {
    setUp(() => db.teamDao.addTeamMember('team-123', 'user-1'));

    Future<Response> fetch({
      Object? graphqlBody,
      int statusCode = 200,
      http.Client? client,
      HttpMethod method = HttpMethod.get,
      String branch = 'feature/builds',
    }) {
      final httpClient =
          client ??
          MockClient((request) async {
            if (request.url.path.endsWith('/access_tokens')) {
              return http.Response(jsonEncode({'token': 'test-token'}), 200);
            }
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['variables']['expression'], '$branch:.openci');
            return http.Response(jsonEncode(graphqlBody), statusCode);
          });
      addTearDown(httpClient.close);
      final context = TestRequestContext(
        path: '/teams/team-123/workflows?repository=owner/repo&branch=$branch',
        method: method,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('user-1');
      context.provide<Map<String, String>>(testEnv);
      context.provide<http.Client>(httpClient);
      return Future.value(
        workflows_route.onRequest(context.context, 'team-123'),
      );
    }

    test('rejects unsupported methods', () async {
      expect(
        (await fetch(method: HttpMethod.post)).statusCode,
        HttpStatus.methodNotAllowed,
      );
    });

    test(
      'reports a missing GitHub installation before making requests',
      () async {
        await db
            .update(db.teams)
            .write(
              const TeamsCompanion(installationIds: Value([])),
            );
        final response = await fetch(
          client: MockClient((_) async {
            fail('No GitHub request should be made without an installation');
          }),
        );
        expect(response.statusCode, HttpStatus.badRequest);
        expect(await response.json(), {
          'success': false,
          'error': 'GitHub App is not installed for this team',
        });
      },
    );

    for (final payload in [
      {
        'data': {
          'repository': {'object': null},
        },
      },
      {
        'errors': [
          {'message': 'Could not resolve to an object at this path'},
        ],
      },
    ]) {
      test(
        'returns an empty workflow list for a missing tree: $payload',
        () async {
          final response = await fetch(graphqlBody: payload);
          expect(response.statusCode, HttpStatus.ok);
          expect(await response.json(), {'success': true, 'files': []});
        },
      );
    }

    test('reports a repository absent from all installations', () async {
      final response = await fetch(
        graphqlBody: {
          'data': {'repository': null},
        },
      );
      expect(response.statusCode, HttpStatus.notFound);
      expect(await response.json(), {
        'success': false,
        'error': 'Repository not found in any installation',
      });
    });

    for (final (status, payload) in [
      (503, {'message': 'private upstream detail'}),
      (
        200,
        {
          'errors': [
            {'message': 'private upstream detail'},
          ],
        },
      ),
    ]) {
      test(
        'hides upstream failure details for HTTP $status: $payload',
        () async {
          final response = await fetch(
            statusCode: status,
            graphqlBody: payload,
          );
          expect(response.statusCode, HttpStatus.internalServerError);
          expect(await response.json(), {
            'success': false,
            'error': 'Internal server error',
          });
        },
      );
    }

    test('tries the next installation when the first request fails', () async {
      await db
          .update(db.teams)
          .write(
            const TeamsCompanion(installationIds: Value([111, 222])),
          );
      final tokenPaths = <String>[];
      var graphRequests = 0;
      final response = await fetch(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/access_tokens')) {
            tokenPaths.add(request.url.path);
            return http.Response(jsonEncode({'token': 'test-token'}), 200);
          }
          if (++graphRequests == 1) return http.Response('unavailable', 503);
          return http.Response(
            jsonEncode({
              'data': {
                'repository': {
                  'object': {
                    'entries': [
                      {
                        'type': 'blob',
                        'name': 'build.yml',
                        'object': {'text': 'steps: []'},
                      },
                    ],
                  },
                },
              },
            }),
            200,
          );
        }),
      );
      expect(response.statusCode, HttpStatus.ok);
      expect(tokenPaths, [
        '/app/installations/111/access_tokens',
        '/app/installations/222/access_tokens',
      ]);
      expect(graphRequests, 2);
      expect(await response.json(), {
        'success': true,
        'files': [
          {
            'name': 'build.yml',
            'path': '.openci/build.yml',
            'content': 'steps: []',
          },
        ],
      });
    });

    for (final (baseUrl, graphUrl) in [
      ('https://github.com/', 'https://api.github.com/graphql'),
      ('https://github.example.com/', 'https://github.example.com/api/graphql'),
    ]) {
      test('uses the GraphQL endpoint for $baseUrl', () async {
        await db
            .update(db.teams)
            .write(
              TeamsCompanion(githubBaseUrl: Value(baseUrl)),
            );
        var queriedGraph = false;
        final response = await fetch(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/access_tokens')) {
              return http.Response(jsonEncode({'token': 'test-token'}), 200);
            }
            queriedGraph = true;
            expect(request.url.toString(), graphUrl);
            return http.Response(
              jsonEncode({
                'data': {
                  'repository': {
                    'object': {'entries': []},
                  },
                },
              }),
              200,
            );
          }),
        );
        expect(queriedGraph, isTrue);
        expect(response.statusCode, HttpStatus.ok);
        expect(await response.json(), {'success': true, 'files': []});
      });
    }
  });

  group('Workflows Endpoint', () {
    test('responds with 401 Unauthorized when uid is null', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/workflows?repository=owner/repo',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(null);
      context.provide<Map<String, String>>(testEnv);

      final response = await workflows_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('responds with 403 Forbidden when user is not team member', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/workflows?repository=owner/repo',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('non-member-user');
      context.provide<Map<String, String>>(testEnv);

      final response = await workflows_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test('responds with 400 Bad Request when repository is missing', () async {
      await db
          .into(db.teamMembers)
          .insert(
            TeamMembersCompanion.insert(
              teamId: 'team-123',
              userId: 'user-1',
            ),
          );

      final context = TestRequestContext(
        path: '/teams/team-123/workflows',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('user-1');
      context.provide<Map<String, String>>(testEnv);

      final response = await workflows_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.badRequest));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['error'], equals('repository is required'));
    });

    test(
      'responds with 400 Bad Request when repository format is invalid',
      () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-123',
                userId: 'user-1',
              ),
            );

        final context = TestRequestContext(
          path: '/teams/team-123/workflows?repository=invalid-format',
          method: HttpMethod.get,
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');
        context.provide<Map<String, String>>(testEnv);

        final response = await workflows_route.onRequest(
          context.context,
          'team-123',
        );
        expect(response.statusCode, equals(HttpStatus.badRequest));
        final body = await response.json() as Map<String, dynamic>;
        expect(
          body['error'],
          equals('repository must be in owner/repo format'),
        );
      },
    );

    test('responds with 200 OK and lists workflow files from GitHub', () async {
      await db
          .into(db.teamMembers)
          .insert(
            TeamMembersCompanion.insert(
              teamId: 'team-123',
              userId: 'user-1',
            ),
          );

      final mockHttpClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.endsWith('/access_tokens')) {
          return http.Response(
            jsonEncode({'token': 'ghs_mockedtoken123456'}),
            200,
          );
        }

        if (request.method == 'POST' && request.url.path.endsWith('/graphql')) {
          final reqBody = jsonDecode(request.body) as Map<String, dynamic>;
          expect(reqBody['variables']['owner'], equals('owner'));
          expect(reqBody['variables']['repo'], equals('repo'));
          expect(reqBody['variables']['expression'], equals('HEAD:.openci'));

          return http.Response(
            jsonEncode({
              'data': {
                'repository': {
                  'object': {
                    'entries': [
                      {
                        'name': 'ci.yaml',
                        'type': 'blob',
                        'object': {'text': 'ci workflow content'},
                      },
                      {
                        'name': 'not-yaml.txt',
                        'type': 'blob',
                        'object': {'text': 'ignored'},
                      },
                      {
                        'name': 'subfolder',
                        'type': 'tree',
                        'object': null,
                      },
                    ],
                  },
                },
              },
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final context = TestRequestContext(
        path: '/teams/team-123/workflows?repository=owner/repo',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('user-1');
      context.provide<Map<String, String>>(testEnv);
      context.provide<http.Client>(mockHttpClient);

      final response = await workflows_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.ok));

      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);
      final files = body['files'] as List<dynamic>;
      expect(files, hasLength(1));
      expect(files[0]['name'], equals('ci.yaml'));
      expect(files[0]['path'], equals('.openci/ci.yaml'));
      expect(files[0]['content'], equals('ci workflow content'));
    });
  });
}
