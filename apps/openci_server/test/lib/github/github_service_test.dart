import 'dart:convert';
import 'dart:io';

import 'package:github/github.dart';
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

    MockClient apiClient(http.Response Function(http.Request) handleRequest) {
      final client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.endsWith('/access_tokens')) {
          return _jsonResponse({'token': 'ghs_test_token'});
        }
        return handleRequest(request);
      });
      addTearDown(client.close);
      return client;
    }

    group('getRepositoryInstallationId', () {
      test(
        'finds the repository installation using the configured App JWT',
        () async {
          testEnv['GITHUB_API_BASE_URL'] =
              'https://github.example.test/api/v3/';
          final requests = <http.Request>[];
          final client = apiClient((request) {
            requests.add(request);
            return _jsonResponse({'id': 42});
          });

          expect(
            await GitHubService.getRepositoryInstallationId(
              owner: 'example',
              repo: 'mobile',
              environment: testEnv,
              client: client,
            ),
            '42',
          );
          final request = requests.single;
          expect(request.method, 'GET');
          expect(
            request.url.toString(),
            'https://github.example.test/api/v3/repos/example/mobile/installation',
          );
          expect(request.headers['accept'], 'application/vnd.github+json');
          final jwt = request.headers['authorization']!.substring(
            'Bearer '.length,
          );
          final payload = jsonDecode(
            utf8.decode(
              base64Url.decode(
                base64Url.normalize(jwt.split('.')[1]),
              ),
            ),
          );
          expect(payload['iss'], testEnv['GITHUB_APP_ID']);
        },
      );

      test('uses the default HTTP client when none is supplied', () async {
        final result = await http.runWithClient(
          () => GitHubService.getRepositoryInstallationId(
            owner: 'example',
            repo: 'mobile',
            environment: testEnv,
          ),
          () => MockClient((_) async => _jsonResponse({'id': 42})),
        );
        expect(result, '42');
      });

      for (final key in [
        'GITHUB_APP_ID',
        'GITHUB_PRIVATE_KEY_PATH',
        'GITHUB_API_BASE_URL',
      ]) {
        for (final value in [null, '']) {
          test(
            'rejects missing $key with value $value before requesting GitHub',
            () async {
              testEnv.remove(key);
              if (value != null) testEnv[key] = value;
              await expectLater(
                GitHubService.getRepositoryInstallationId(
                  owner: 'example',
                  repo: 'mobile',
                  environment: testEnv,
                  client: apiClient((_) => fail('GitHub must not be called')),
                ),
                throwsA(
                  isA<StateError>().having(
                    (error) => error.message,
                    'message',
                    contains(key),
                  ),
                ),
              );
            },
          );
        }
      }

      test(
        'rejects a missing private key file before requesting GitHub',
        () async {
          await privateKeyFile.delete();
          await expectLater(
            GitHubService.getRepositoryInstallationId(
              owner: 'example',
              repo: 'mobile',
              environment: testEnv,
              client: apiClient((_) => fail('GitHub must not be called')),
            ),
            throwsA(isA<FileSystemException>()),
          );
        },
      );

      for (final status in [403, 404]) {
        test(
          'propagates a GitHub $status without returning a dummy ID',
          () async {
            await expectLater(
              GitHubService.getRepositoryInstallationId(
                owner: 'example',
                repo: 'mobile',
                environment: testEnv,
                client: apiClient(
                  (_) => http.Response('No installation', status),
                ),
              ),
              throwsA(
                isA<HttpException>().having(
                  (error) => error.message,
                  'message',
                  contains('$status'),
                ),
              ),
            );
          },
        );
      }

      for (final body in [
        '{}',
        '{"id":0}',
        '{"id":-1}',
        '{"id":"42"}',
        'invalid',
      ]) {
        test('rejects an invalid installation response: $body', () async {
          await expectLater(
            GitHubService.getRepositoryInstallationId(
              owner: 'example',
              repo: 'mobile',
              environment: testEnv,
              client: apiClient((_) => http.Response(body, 200)),
            ),
            throwsFormatException,
          );
        });
      }
    });

    group('listRepositories', () {
      test(
        'maps repository fields and defaults using the configured API host',
        () async {
          testEnv['GITHUB_API_BASE_URL'] = 'https://github.example.test/api/v3';
          final requests = <http.Request>[];
          final client = apiClient((request) {
            requests.add(request);
            return _jsonResponse({
              'repositories': [
                {
                  'full_name': 'org/mobile',
                  'name': 'mobile',
                  'owner': {'login': 'org'},
                  'private': true,
                  'default_branch': 'develop',
                },
                <String, Object?>{},
              ],
            });
          });

          final repositories = await GitHubService.listRepositories(
            installationIdStr: '98765',
            environment: testEnv,
            client: client,
          );

          expect(repositories, [
            {
              'fullName': 'org/mobile',
              'name': 'mobile',
              'owner': 'org',
              'private': true,
              'defaultBranch': 'develop',
            },
            {
              'fullName': '',
              'name': '',
              'owner': '',
              'private': false,
              'defaultBranch': 'main',
            },
          ]);
          expect(requests.single.method, 'GET');
          expect(
            requests.single.url.toString(),
            'https://github.example.test/api/v3/installation/repositories',
          );
          expect(
            requests.single.headers['authorization'],
            'Bearer ghs_test_token',
          );
        },
      );

      test('returns an empty list when repositories are absent', () async {
        final client = apiClient((_) => _jsonResponse({}));

        expect(
          await GitHubService.listRepositories(
            installationIdStr: '98765',
            environment: testEnv,
            client: client,
          ),
          isEmpty,
        );
      });

      test('propagates a repository API failure', () async {
        final client = apiClient((_) => http.Response('Forbidden', 403));

        await expectLater(
          GitHubService.listRepositories(
            installationIdStr: '98765',
            environment: testEnv,
            client: client,
          ),
          throwsA(
            isA<HttpException>().having(
              (e) => e.message,
              'message',
              contains('403 Forbidden'),
            ),
          ),
        );
      });
    });

    group('listBranches', () {
      test(
        'preserves branch names and removes entries without a name',
        () async {
          final requests = <http.Request>[];
          final client = apiClient((request) {
            requests.add(request);
            return _jsonResponse([
              {'name': 'main'},
              {'name': 'feature/new-ci'},
              {'name': ''},
              {'name': null},
              {},
            ]);
          });

          final branches = await GitHubService.listBranches(
            owner: 'org',
            repo: 'mobile',
            installationIdStr: '98765',
            environment: testEnv,
            client: client,
          );

          expect(branches, ['main', 'feature/new-ci']);
          expect(requests.single.url.path, '/repos/org/mobile/branches');
          expect(
            requests.single.headers['authorization'],
            'Bearer ghs_test_token',
          );
        },
      );

      test('propagates a branch API failure', () async {
        final client = apiClient((_) => http.Response('Not Found', 404));

        await expectLater(
          GitHubService.listBranches(
            owner: 'org',
            repo: 'mobile',
            installationIdStr: '98765',
            environment: testEnv,
            client: client,
          ),
          throwsA(
            isA<HttpException>().having(
              (e) => e.message,
              'message',
              contains('404 Not Found'),
            ),
          ),
        );
      });
    });

    group('fetchWorkflowContent', () {
      test(
        'fetches Dart from genuine_ci at the commit using an existing token',
        () async {
          final requests = <http.Request>[];
          const content = '// 日本語のワークフロー\nvoid main() {}\n';
          final encoded = base64Encode(utf8.encode(content));
          final client = MockClient((request) async {
            requests.add(request);
            return _jsonResponse({
              'content':
                  '${encoded.substring(0, 8)}\n ${encoded.substring(8)}\n',
            });
          });
          addTearDown(client.close);

          final result = await GitHubService.fetchWorkflowContent(
            owner: 'org',
            repo: 'mobile',
            workflowFileName: 'ci.dart',
            installationIdStr: '98765',
            token: 'existing-token',
            commitSha: 'abc123',
            branch: 'develop',
            environment: {},
            client: client,
          );

          expect(result, content);
          expect(requests.single.method, 'GET');
          expect(
            requests.single.url.toString(),
            'https://api.github.com/repos/org/mobile/contents/genuine_ci/ci.dart?ref=abc123',
          );
          expect(
            requests.single.headers['authorization'],
            'Bearer existing-token',
          );
        },
      );

      test('fetches YAML from .openci and encodes the branch ref', () async {
        final requests = <http.Request>[];
        final client = apiClient((request) {
          requests.add(request);
          return _jsonResponse({'content': 'name: CI\n', 'encoding': 'utf-8'});
        });

        final result = await GitHubService.fetchWorkflowContent(
          owner: 'org',
          repo: 'mobile',
          workflowFileName: 'ci.yml',
          installationIdStr: '98765',
          branch: 'feature/ci & tests',
          environment: testEnv,
          client: client,
        );

        expect(result, 'name: CI\n');
        expect(
          requests.single.url.path,
          '/repos/org/mobile/contents/.openci/ci.yml',
        );
        expect(requests.single.url.queryParameters, {
          'ref': 'feature/ci & tests',
        });
      });

      test('omits the ref query when no revision is specified', () async {
        final requests = <http.Request>[];
        final client = apiClient((request) {
          requests.add(request);
          return _jsonResponse({'content': '', 'encoding': 'base64'});
        });

        expect(
          await GitHubService.fetchWorkflowContent(
            owner: 'org',
            repo: 'mobile',
            workflowFileName: 'ci.dart',
            installationIdStr: '98765',
            environment: testEnv,
            client: client,
          ),
          '',
        );
        expect(requests.single.url.query, isEmpty);
      });

      test('reports a missing workflow', () async {
        final client = apiClient((_) => http.Response('Not Found', 404));

        await expectLater(
          GitHubService.fetchWorkflowContent(
            owner: 'org',
            repo: 'mobile',
            workflowFileName: 'ci.dart',
            installationIdStr: '98765',
            environment: testEnv,
            client: client,
          ),
          throwsA(
            isA<HttpException>().having(
              (e) => e.message,
              'message',
              contains('404 Not Found'),
            ),
          ),
        );
      });

      test('rejects a response without file content', () async {
        final client = apiClient((_) => _jsonResponse({'encoding': 'base64'}));

        await expectLater(
          GitHubService.fetchWorkflowContent(
            owner: 'org',
            repo: 'mobile',
            workflowFileName: 'ci.dart',
            installationIdStr: '98765',
            environment: testEnv,
            client: client,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'No content in GitHub response',
            ),
          ),
        );
      });

      test(
        'rejects invalid base64 rather than returning corrupted source',
        () async {
          final client = apiClient((_) => _jsonResponse({'content': '***'}));

          await expectLater(
            GitHubService.fetchWorkflowContent(
              owner: 'org',
              repo: 'mobile',
              workflowFileName: 'ci.dart',
              installationIdStr: '98765',
              environment: testEnv,
              client: client,
            ),
            throwsFormatException,
          );
        },
      );
    });

    group('fetchGenuineCiFiles', () {
      test(
        'loads Dart files at the same commit and excludes other entries',
        () async {
          final requests = <http.Request>[];
          const sources = {
            'genuine_ci/ci.dart': '// ビルド\nvoid main() {}\n',
            'genuine_ci/secrets.g.dart': 'const secretName = "API_TOKEN";\n',
          };
          final client = apiClient((request) {
            requests.add(request);
            if (request.url.path.endsWith('/contents/genuine_ci')) {
              return _jsonResponse([
                for (final path in sources.keys)
                  {'type': 'file', 'name': path.split('/').last, 'path': path},
                {
                  'type': 'file',
                  'name': 'README.md',
                  'path': 'genuine_ci/README.md',
                },
                {
                  'type': 'dir',
                  'name': 'helpers',
                  'path': 'genuine_ci/helpers',
                },
              ]);
            }
            final path = request.url.path.split('/contents/').last;
            return _jsonResponse({
              'type': 'file',
              'content': base64Encode(utf8.encode(sources[path]!)),
            });
          });

          final files = await GitHubService.fetchGenuineCiFiles(
            owner: 'org',
            repo: 'mobile',
            commitSha: 'abc123',
            installationIdStr: '98765',
            environment: testEnv,
            client: client,
          );

          expect(files.map((file) => file.name), ['ci.dart', 'secrets.g.dart']);
          expect({for (final file in files) file.path: file.content}, sources);
          expect(requests.map((request) => request.url.path), [
            '/repos/org/mobile/contents/genuine_ci',
            '/repos/org/mobile/contents/genuine_ci/ci.dart',
            '/repos/org/mobile/contents/genuine_ci/secrets.g.dart',
          ]);
          for (final request in requests) {
            expect(request.method, 'GET');
            expect(request.url.queryParameters, {'ref': 'abc123'});
            expect(
              request.headers['authorization'],
              contains('ghs_test_token'),
            );
          }
        },
      );

      test('returns no files if genuine_ci does not exist', () async {
        final client = apiClient(
          (_) => _jsonResponse({'message': 'Not Found'}, statusCode: 404),
        );

        expect(
          await GitHubService.fetchGenuineCiFiles(
            owner: 'org',
            repo: 'mobile',
            commitSha: 'abc123',
            installationIdStr: '98765',
            environment: testEnv,
            client: client,
          ),
          isEmpty,
        );
      });

      test(
        'propagates access errors instead of treating the directory as empty',
        () async {
          final client = apiClient(
            (_) => _jsonResponse({'message': 'Forbidden'}, statusCode: 403),
          );

          await expectLater(
            GitHubService.fetchGenuineCiFiles(
              owner: 'org',
              repo: 'mobile',
              commitSha: 'abc123',
              installationIdStr: '98765',
              environment: testEnv,
              client: client,
            ),
            throwsA(isA<GitHubError>()),
          );
        },
      );
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

    group('createGitHubCheckRun', () {
      Future<String> createCheck({
        http.Client? client,
        Map<String, String>? environment,
      }) => GitHubService.createGitHubCheckRun(
        owner: 'org',
        repo: 'mobile',
        installationIdStr: '98765',
        name: 'Flutter CI',
        headSha: 'abc123',
        externalId: 'job-123',
        environment: environment ?? testEnv,
        client: client,
      );

      test('creates an in-progress check and returns its ID', () async {
        testEnv['GITHUB_API_BASE_URL'] = 'https://github.example.test/api/v3';
        final requests = <http.Request>[];
        final client = apiClient((request) {
          requests.add(request);
          return http.Response('{"id": 99999}', HttpStatus.created);
        });

        expect(await createCheck(client: client), '99999');
        final request = requests.single;
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://github.example.test/api/v3/repos/org/mobile/check-runs',
        );
        expect(request.headers['authorization'], 'Bearer ghs_test_token');
        expect(request.headers['content-type'], 'application/json');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final startedAt = DateTime.parse(body.remove('started_at') as String);
        expect(startedAt.isUtc, isTrue);
        expect(body, {
          'name': 'Flutter CI',
          'head_sha': 'abc123',
          'external_id': 'job-123',
          'status': 'in_progress',
        });
      });

      test('uses the default HTTP client when none is supplied', () async {
        final client = apiClient(
          (_) => http.Response('{"id": 99999}', HttpStatus.created),
        );

        expect(
          await http.runWithClient(() => createCheck(), () => client),
          '99999',
        );
      });

      test(
        'reports missing process configuration when no environment is supplied',
        () async {
          final client = MockClient((_) async => fail('No request expected'));
          addTearDown(client.close);

          await expectLater(
            GitHubService.createGitHubCheckRun(
              owner: 'org',
              repo: 'mobile',
              installationIdStr: '98765',
              name: 'Flutter CI',
              headSha: 'abc123',
              externalId: 'job-123',
              client: client,
            ),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                'GITHUB_API_BASE_URL environment variable is not configured',
              ),
            ),
          );
        },
        skip: (Platform.environment['GITHUB_API_BASE_URL'] ?? '').isNotEmpty
            ? 'Requires an unconfigured process environment.'
            : false,
      );

      for (final status in [
        HttpStatus.forbidden,
        HttpStatus.unprocessableEntity,
      ]) {
        test('reports a Check creation failure with status $status', () async {
          final client = apiClient((_) => http.Response('Rejected', status));

          await expectLater(
            createCheck(client: client),
            throwsA(
              isA<HttpException>().having(
                (e) => e.message,
                'message',
                contains('$status Rejected'),
              ),
            ),
          );
        });
      }

      for (final body in [
        'not-json',
        '[]',
        '{}',
        '{"id":"99999"}',
        '{"id":0}',
      ]) {
        test('rejects an invalid Check response: $body', () async {
          final client = apiClient(
            (_) => http.Response(body, HttpStatus.created),
          );

          await expectLater(createCheck(client: client), throwsFormatException);
        });
      }

      for (final baseUrl in [null, '']) {
        test('rejects missing API configuration: $baseUrl', () async {
          final env = Map<String, String>.from(testEnv)
            ..remove('GITHUB_API_BASE_URL');
          if (baseUrl != null) env['GITHUB_API_BASE_URL'] = baseUrl;
          final client = MockClient((_) async => fail('No request expected'));
          addTearDown(client.close);

          await expectLater(
            createCheck(client: client, environment: env),
            throwsStateError,
          );
        });
      }

      test(
        'does not create a Check if installation authentication fails',
        () async {
          final requests = <http.Request>[];
          final client = MockClient((request) async {
            requests.add(request);
            return http.Response('Forbidden', HttpStatus.forbidden);
          });
          addTearDown(client.close);

          await expectLater(
            createCheck(client: client),
            throwsA(isA<HttpException>()),
          );
          expect(
            requests.single.url.path,
            '/app/installations/98765/access_tokens',
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
            expect(body.containsKey('conclusion'), isFalse);
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

http.Response _jsonResponse(Object body, {int statusCode = 200}) =>
    http.Response(
      jsonEncode(body),
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
