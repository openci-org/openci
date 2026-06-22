import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/database.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../routes/teams/[id]/workflows.dart' as workflows_route;

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
