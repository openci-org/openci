import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

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
  group('GitHubService', () {
    late Directory tempDir;
    late File privateKeyFile;
    late Map<String, String> testEnv;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('github_service_test_');
      privateKeyFile = File(p.join(tempDir.path, 'private_key.pem'));
      privateKeyFile.writeAsStringSync(testRsaPrivateKey);

      testEnv = {
        'GITHUB_APP_ID': '123456',
        'GITHUB_PRIVATE_KEY_PATH': privateKeyFile.path,
        'GITHUB_API_BASE_URL': 'https://api.github.com',
      };
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('generateJwt', () {
      test('generates a valid JWT string signed with RS256', () {
        final jwt = GitHubService.generateJwt('123456', testRsaPrivateKey);
        expect(jwt, isNotEmpty);
        expect(jwt.split('.'), hasLength(3)); // Header, Payload, Signature
      });
    });

    group('getInstallationToken', () {
      test(
        'successfully retrieves token when GitHub API returns 200',
        () async {
          final mockClient = MockClient((request) async {
            expect(request.method, equals('POST'));
            expect(
              request.url.toString(),
              equals(
                'https://api.github.com/app/installations/98765/access_tokens',
              ),
            );
            expect(request.headers['Authorization'], startsWith('Bearer '));
            expect(
              request.headers['Accept'],
              equals('application/vnd.github+json'),
            );
            expect(
              request.headers['X-GitHub-Api-Version'],
              equals('2022-11-28'),
            );
            expect(request.headers['User-Agent'], equals('OpenCI-Server'));

            return http.Response(
              jsonEncode({'token': 'ghs_mockedtoken123456'}),
              200,
            );
          });

          final token = await GitHubService.getInstallationToken(
            installationIdStr: '98765',
            environment: testEnv,
            client: mockClient,
          );

          expect(token, equals('ghs_mockedtoken123456'));
        },
      );

      test('throws StateError when GITHUB_APP_ID is missing', () async {
        testEnv.remove('GITHUB_APP_ID');

        expect(
          () => GitHubService.getInstallationToken(
            installationIdStr: '98765',
            environment: testEnv,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('GITHUB_APP_ID environment variable is not configured'),
            ),
          ),
        );
      });

      test('throws StateError when GITHUB_PRIVATE_KEY_PATH is missing', () async {
        testEnv.remove('GITHUB_PRIVATE_KEY_PATH');

        expect(
          () => GitHubService.getInstallationToken(
            installationIdStr: '98765',
            environment: testEnv,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(
                'GITHUB_PRIVATE_KEY_PATH environment variable is not configured',
              ),
            ),
          ),
        );
      });

      test('throws StateError when GITHUB_API_BASE_URL is missing', () async {
        testEnv.remove('GITHUB_API_BASE_URL');

        expect(
          () => GitHubService.getInstallationToken(
            installationIdStr: '98765',
            environment: testEnv,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(
                'GITHUB_API_BASE_URL environment variable is not configured',
              ),
            ),
          ),
        );
      });

      test('throws StateError when private key file does not exist', () async {
        testEnv['GITHUB_PRIVATE_KEY_PATH'] = p.join(
          tempDir.path,
          'non_existent.pem',
        );

        expect(
          () => GitHubService.getInstallationToken(
            installationIdStr: '98765',
            environment: testEnv,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('GitHub private key file not found'),
            ),
          ),
        );
      });

      test(
        'throws HttpException when GitHub API returns error status code',
        () async {
          final mockClient = MockClient((request) async {
            return http.Response('Bad Request', 400);
          });

          expect(
            () => GitHubService.getInstallationToken(
              installationIdStr: '98765',
              environment: testEnv,
              client: mockClient,
            ),
            throwsA(
              isA<HttpException>().having(
                (e) => e.message,
                'message',
                contains(
                  'Failed to retrieve installation token from GitHub: 400 Bad Request',
                ),
              ),
            ),
          );
        },
      );
    });

    group('updateGitHubCheckRun', () {
      test('successfully updates check run (queued/in_progress)', () async {
        var tokenRequested = false;
        var patchRequested = false;

        final mockClient = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/access_tokens')) {
            tokenRequested = true;
            return http.Response(
              jsonEncode({'token': 'ghs_mockedtoken123456'}),
              200,
            );
          }

          if (request.method == 'PATCH' &&
              request.url.path.endsWith(
                '/repos/my-owner/my-repo/check-runs/99999',
              )) {
            patchRequested = true;

            expect(
              request.headers['Authorization'],
              equals('Bearer ghs_mockedtoken123456'),
            );
            expect(request.headers['Content-Type'], equals('application/json'));

            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['status'], equals('in_progress'));
            expect(body['conclusion'], isNull);
            expect(body.containsKey('completed_at'), isFalse);

            return http.Response(jsonEncode({'id': 99999}), 200);
          }

          return http.Response('Not Found', 404);
        });

        await GitHubService.updateGitHubCheckRun(
          owner: 'my-owner',
          repo: 'my-repo',
          checkRunIdStr: '99999',
          installationIdStr: '98765',
          runStatus: 'in_progress',
          environment: testEnv,
          client: mockClient,
        );

        expect(tokenRequested, isTrue);
        expect(patchRequested, isTrue);
      });

      test('successfully updates check run (completed)', () async {
        final mockClient = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/access_tokens')) {
            return http.Response(
              jsonEncode({'token': 'ghs_mockedtoken123456'}),
              200,
            );
          }

          if (request.method == 'PATCH' &&
              request.url.path.endsWith(
                '/repos/my-owner/my-repo/check-runs/99999',
              )) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['status'], equals('completed'));
            expect(body['conclusion'], equals('success'));
            expect(body.containsKey('completed_at'), isTrue);
            final completedAt = DateTime.parse(body['completed_at'] as String);
            expect(completedAt.isUtc, isTrue);

            return http.Response(jsonEncode({'id': 99999}), 200);
          }

          return http.Response('Not Found', 404);
        });

        await GitHubService.updateGitHubCheckRun(
          owner: 'my-owner',
          repo: 'my-repo',
          checkRunIdStr: '99999',
          installationIdStr: '98765',
          runStatus: 'completed',
          conclusion: 'success',
          environment: testEnv,
          client: mockClient,
        );
      });

      test(
        'throws StateError when GITHUB_API_BASE_URL is missing in updateGitHubCheckRun',
        () async {
          final mockClient = MockClient((request) async {
            if (request.method == 'POST' &&
                request.url.path.endsWith('/access_tokens')) {
              return http.Response(
                jsonEncode({'token': 'ghs_mockedtoken123456'}),
                200,
              );
            }
            return http.Response('Not Found', 404);
          });

          final badEnv = Map<String, String>.from(testEnv)
            ..remove('GITHUB_API_BASE_URL');

          expect(
            () => GitHubService.updateGitHubCheckRun(
              owner: 'my-owner',
              repo: 'my-repo',
              checkRunIdStr: '99999',
              installationIdStr: '98765',
              runStatus: 'in_progress',
              environment: badEnv,
              client: mockClient,
            ),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                contains(
                  'GITHUB_API_BASE_URL environment variable is not configured',
                ),
              ),
            ),
          );
        },
      );

      test('throws HttpException when update request fails', () async {
        final mockClient = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/access_tokens')) {
            return http.Response(
              jsonEncode({'token': 'ghs_mockedtoken123456'}),
              200,
            );
          }

          if (request.method == 'PATCH') {
            return http.Response('Internal Server Error', 500);
          }

          return http.Response('Not Found', 404);
        });

        expect(
          () => GitHubService.updateGitHubCheckRun(
            owner: 'my-owner',
            repo: 'my-repo',
            checkRunIdStr: '99999',
            installationIdStr: '98765',
            runStatus: 'completed',
            conclusion: 'failure',
            environment: testEnv,
            client: mockClient,
          ),
          throwsA(
            isA<HttpException>().having(
              (e) => e.message,
              'message',
              contains(
                'Failed to update GitHub check run: 500 Internal Server Error',
              ),
            ),
          ),
        );
      });
    });
  });
}
