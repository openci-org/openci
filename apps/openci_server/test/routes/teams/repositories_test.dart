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

import '../../../routes/teams/[id]/github/repositories.dart'
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
      'responds with 400 Bad Request when GitHub App installationIds is empty',
      () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-456',
                userId: 'user-1',
              ),
            );
        await db
            .into(db.teams)
            .insert(
              DriftTeam(
                id: 'team-456',
                name: 'Test Team 2',
                installationIds: const [],
                aiEnabled: false,
                runNumber: 1,
                createdAt: DateTime.now().toUtc(),
                updatedAt: DateTime.now().toUtc(),
              ),
            );

        final context = TestRequestContext(
          path: '/teams/team-456/github/repositories',
          method: HttpMethod.get,
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');
        context.provide<Map<String, String>>(testEnv);

        final response = await repositories_route.onRequest(
          context.context,
          'team-456',
        );
        expect(response.statusCode, equals(HttpStatus.badRequest));
        final body = await response.json() as Map<String, dynamic>;
        expect(
          body['error'],
          equals('GitHub App is not installed for this team'),
        );
      },
    );

    test('responds with 200 OK and lists repositories from GitHub', () async {
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
  });
}
