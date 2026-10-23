import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:openci_server/secret/secret_table.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../routes/builds/[id]/_middleware.dart' as build;
import '../../../../routes/builds/[id]/secrets.dart' as route;
import '../../../helpers/github_app_test_key.dart';

void main() {
  const token = 'test-installation-token';
  const encryptionKey = 'A9hs566HtB6B0ZEB2aKkAZpC81VGQxKMlFspt+vA5F4=';
  const definitions = '''
    abstract final class Secrets {
      static String get ascKey =>
          Platform.environment['ASC_KEY'] ??
          (throw StateError('ASC_KEY is not set.'));
      static String get unused => Platform.environment['UNUSED_KEY'] ?? '';
    }
  ''';
  late AppDatabase db;
  late Directory tempDir;
  late Map<String, String> environment;
  late List<String> requestedFiles;
  late List<http.Request> githubRequests;

  final connection = DriftGitHubConnection(
    id: 'connection-1',
    teamId: 'team-1',
    githubApiBaseUrl: 'https://github.example/api/v3',
    githubAppId: 123456,
    installationId: 98765,
    accountId: 42,
    accountType: GitHubAccountType.organization,
    accountLogin: 'owner',
    verifiedByUserId: 'member-1',
    verifiedByGitHubUserId: 100,
    verifiedAt: DateTime.utc(2026),
    status: GitHubConnectionStatus.active,
  );

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-1',
        name: 'OpenCI',
        installationIds: const [55555],
        aiEnabled: false,
        runNumber: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      'member-1',
    );
    await db.into(db.gitHubConnections).insert(connection);

    tempDir = await Directory.systemTemp.createTemp('job_secrets_test_');
    final keyFile = File('${tempDir.path}/key.pem');
    await keyFile.writeAsString(testRsaPrivateKey);
    environment = {
      'GITHUB_APP_ID': '123456',
      'GITHUB_PRIVATE_KEY_PATH': keyFile.path,
      'GITHUB_API_BASE_URL': 'https://github.example/api/v3',
      'SECRET_ENCRYPTION_KEY': encryptionKey,
    };
    requestedFiles = [];
    githubRequests = [];

    final crypter = SecretCrypter(encryptionKey);
    final now = DateTime.utc(2026, 9, 7);
    final secrets = [
      for (final entry in {
        'ASC_KEY': 'test-asc-value',
        'ascKey': 'wrong-secret-value',
        'g': 'import-path-is-not-a-secret',
        'UNUSED_KEY': 'unused-secret-value',
      }.entries)
        DriftSecret(
          name: entry.key,
          teamId: 'team-1',
          encryptedValue: await crypter.encrypt(entry.value),
          createdAt: now,
          updatedAt: now,
        ),
    ];
    for (final secret in secrets) {
      await db.secretDao.insertOrUpdateSecret(secret);
    }
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<http.Response> requestSecrets({
    String workflow = 'Secrets.ascKey;',
    String fileName = 'ci.dart',
    String? installationId = '98765',
    String? commitSha = 'job-commit',
    String? teamId = 'team-1',
    String secretDefinitions = definitions,
    int definitionsStatus = 200,
    String method = 'GET',
    String? uid,
    String? bearerToken = 'test-internal-key',
    http.Response Function(http.Request)? respond,
  }) async {
    final directory = fileName.endsWith('.dart') ? 'openci' : '.openci';
    final githubClient = MockClient((request) async {
      githubRequests.add(request);
      if (respond != null) return respond(request);
      if (request.url.path == '/api/v3/repos/owner/repo/installation') {
        return http.Response(jsonEncode({'id': 98765}), 200);
      }
      if (request.method == 'POST') {
        expect(
          request.url.path,
          '/api/v3/app/installations/98765/access_tokens',
        );
        return http.Response(jsonEncode({'token': token}), 200);
      }
      expect(request.method, 'GET');
      expect(request.headers['Authorization'], 'Bearer $token');
      expect(request.url.queryParameters['ref'], commitSha ?? 'feature/ci');
      const prefix = '/api/v3/repos/owner/repo/contents/';
      expect(request.url.path, startsWith(prefix));
      final file = request.url.path.substring(prefix.length);
      requestedFiles.add(file);
      if ((file == 'openci/secrets.g.dart' ||
              file == 'openci/generated/secrets.g.dart') &&
          definitionsStatus != 200) {
        return http.Response('Not found', definitionsStatus);
      }
      final content = switch (file) {
        'openci/secrets.g.dart' => secretDefinitions,
        'openci/generated/secrets.g.dart' => secretDefinitions,
        _ when file == '$directory/$fileName' => workflow,
        _ => throw StateError('Unexpected GitHub request: $file'),
      };
      return http.Response(
        jsonEncode({
          'content': base64Encode(utf8.encode(content)),
          'encoding': 'base64',
        }),
        200,
      );
    });
    addTearDown(githubClient.close);

    final now = DateTime.utc(2026, 9, 7);
    await db.buildJobDao.insertBuildJob(
      DriftBuildJob(
        id: 'job-1',
        owner: 'owner',
        repo: 'repo',
        teamId: teamId,
        installationId: installationId,
        githubBaseUrl: 'https://untrusted.example',
        commitSha: commitSha,
        branch: 'feature/ci',
        status: BuildJobStatus.IN_PROGRESS,
        workflowName: 'CI',
        workflowFileName: fileName,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final handler =
        ((RequestContext context) => route.onRequest(context, 'job-1'))
            .use(build.middleware)
            .use(provider<AppDatabase>((_) => db))
            .use(provider<String?>((_) => uid))
            .use(provider<Map<String, String>>((_) => environment))
            .use(provider<http.Client>((_) => githubClient))
            .use(
              provider<InternalApiKeyValidator>(
                (_) => const InternalApiKeyValidator(
                  environment: {'INTERNAL_API_KEY': 'test-internal-key'},
                ),
              ),
            );
    final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final client = http.Client();
    addTearDown(client.close);
    final request = http.Request(
      method,
      Uri(
        scheme: 'http',
        host: server.address.address,
        port: server.port,
        path: '/builds/job-1/secrets',
      ),
    );
    if (bearerToken != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $bearerToken';
    }
    return http.Response.fromStream(await client.send(request));
  }

  Future<void> expectConnectionRejected(
    DriftGitHubConnection rejectedConnection,
  ) async {
    await db.update(db.gitHubConnections).replace(rejectedConnection);
    // Reading secrets before rejecting the connection would return 500.
    await db.customStatement('DROP TABLE secrets');

    final response = await requestSecrets();

    expect(response.statusCode, HttpStatus.forbidden);
    expect(jsonDecode(response.body), {'success': false, 'error': 'Forbidden'});
    expect(githubRequests, isEmpty);
  }

  group('verified connections', () {
    test('an internal key resolves secrets through a new connection', () async {
      final team = (await db.teamDao.getTeam('team-1'))!;
      await db.teamDao.updateTeam(team.copyWith(installationIds: []));

      final response = await requestSecrets();

      expect(response.statusCode, HttpStatus.ok);
      expect(jsonDecode(response.body), {
        'success': true,
        'secretsContent': 'GITHUB_TOKEN=$token\nASC_KEY=test-asc-value',
      });
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(githubRequests.map((request) => request.url.toString()), [
        'https://github.example/api/v3/repos/owner/repo/installation',
        'https://github.example/api/v3/app/installations/98765/access_tokens',
        'https://github.example/api/v3/repos/owner/repo/contents/openci/ci.dart?ref=job-commit',
        'https://github.example/api/v3/repos/owner/repo/contents/openci/secrets.g.dart?ref=job-commit',
      ]);
      expect(githubRequests.map((request) => request.method), [
        'GET',
        'POST',
        'GET',
        'GET',
      ]);
    });

    test('a team member can resolve secrets without an internal key', () async {
      final response = await requestSecrets(uid: 'member-1', bearerToken: null);

      expect(response.statusCode, HttpStatus.ok);
      expect(jsonDecode(response.body), {
        'success': true,
        'secretsContent': 'GITHUB_TOKEN=$token\nASC_KEY=test-asc-value',
      });
    });

    test('rejects an unauthenticated caller', () async {
      final response = await requestSecrets(bearerToken: null);

      expect(response.statusCode, HttpStatus.unauthorized);
      expect(githubRequests, isEmpty);
    });

    test('rejects a non-member', () async {
      final response = await requestSecrets(
        uid: 'other-user',
        bearerToken: null,
      );

      expect(response.statusCode, HttpStatus.forbidden);
      expect(githubRequests, isEmpty);
    });

    test('rejects a job with only a legacy installation ID', () async {
      await db.customStatement('DROP TABLE secrets');

      final response = await requestSecrets(installationId: '55555');

      expect(response.statusCode, HttpStatus.forbidden);
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'Forbidden',
      });
      expect(githubRequests, isEmpty);
    });

    test('rejects a job whose connection no longer exists', () async {
      await db.delete(db.gitHubConnections).go();
      await db.customStatement('DROP TABLE secrets');

      final response = await requestSecrets();

      expect(response.statusCode, HttpStatus.forbidden);
      expect(githubRequests, isEmpty);
    });

    test('rejects a connection belonging to another team', () async {
      final team = (await db.teamDao.getTeam('team-1'))!;
      await db.into(db.teams).insert(team.copyWith(id: 'other-team'));

      await expectConnectionRejected(connection.copyWith(teamId: 'other-team'));
    });

    test('rejects a suspended connection', () async {
      await expectConnectionRejected(
        connection.copyWith(status: GitHubConnectionStatus.suspended),
      );
    });

    test('rejects a removed connection', () async {
      await expectConnectionRejected(
        connection.copyWith(status: GitHubConnectionStatus.removed),
      );
    });

    test('rejects a connection for another GitHub API host', () async {
      await expectConnectionRejected(
        connection.copyWith(githubApiBaseUrl: 'https://api.github.com'),
      );
    });

    test('rejects a connection for another GitHub App', () async {
      await expectConnectionRejected(connection.copyWith(githubAppId: 42));
    });

    test('rejects a malformed installation ID', () async {
      final response = await requestSecrets(installationId: '../other');

      expect(response.statusCode, HttpStatus.badRequest);
      expect(githubRequests, isEmpty);
    });

    test('rejects a non-positive installation ID', () async {
      final response = await requestSecrets(installationId: '0');

      expect(response.statusCode, HttpStatus.badRequest);
      expect(githubRequests, isEmpty);
    });

    test('rejects a job without a team', () async {
      final response = await requestSecrets(teamId: null);

      expect(response.statusCode, HttpStatus.forbidden);
      expect(githubRequests, isEmpty);
    });

    test('rejects a repository belonging to another installation', () async {
      await db.customStatement('DROP TABLE secrets');

      final response = await requestSecrets(
        respond: (_) => http.Response(jsonEncode({'id': 99999}), 200),
      );

      expect(response.statusCode, HttpStatus.forbidden);
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'Forbidden',
      });
      expect(githubRequests, hasLength(1));
      expect(githubRequests.single.method, 'GET');
      expect(
        githubRequests.single.url.path,
        '/api/v3/repos/owner/repo/installation',
      );
    });

    test(
      'fails without credentials when GitHub denies repository access',
      () async {
        final response = await requestSecrets(
          respond: (_) => http.Response('private permission detail', 403),
        );

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(jsonDecode(response.body), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(githubRequests, hasLength(1));
        expect(
          githubRequests.single.url.path,
          '/api/v3/repos/owner/repo/installation',
        );
      },
    );

    test(
      'does not return dummy credentials when token issuance fails',
      () async {
        await db
            .update(db.gitHubConnections)
            .replace(
              connection.copyWith(installationId: 12345678),
            );

        final response = await requestSecrets(
          installationId: '12345678',
          respond: (request) => request.method == 'GET'
              ? http.Response(jsonEncode({'id': 12345678}), 200)
              : http.Response('private token failure', 403),
        );

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(jsonDecode(response.body), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(githubRequests.map((request) => request.url.path), [
          '/api/v3/repos/owner/repo/installation',
          '/api/v3/app/installations/12345678/access_tokens',
        ]);
      },
    );

    test(
      'does not return credentials if workflow access fails for the former dummy installation',
      () async {
        await db
            .update(db.gitHubConnections)
            .replace(
              connection.copyWith(installationId: 12345678),
            );

        final response = await requestSecrets(
          installationId: '12345678',
          respond: (request) {
            if (request.url.path.endsWith('/installation')) {
              return http.Response(jsonEncode({'id': 12345678}), 200);
            }
            if (request.method == 'POST') {
              return http.Response(jsonEncode({'token': token}), 201);
            }
            return http.Response('private workflow permission detail', 403);
          },
        );

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(jsonDecode(response.body), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(githubRequests.map((request) => request.url.path), [
          '/api/v3/repos/owner/repo/installation',
          '/api/v3/app/installations/12345678/access_tokens',
          '/api/v3/repos/owner/repo/contents/openci/ci.dart',
        ]);
      },
    );

    test(
      'does not return credentials when the private key is missing',
      () async {
        environment.remove('GITHUB_PRIVATE_KEY_PATH');

        final response = await requestSecrets();

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(jsonDecode(response.body), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(githubRequests, isEmpty);
      },
    );

    test('rejects an empty token before fetching workflow files', () async {
      final response = await requestSecrets(
        respond: (request) => request.method == 'GET'
            ? http.Response(jsonEncode({'id': 98765}), 200)
            : http.Response(jsonEncode({'token': ''}), 200),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(githubRequests.map((request) => request.url.path), [
        '/api/v3/repos/owner/repo/installation',
        '/api/v3/app/installations/98765/access_tokens',
      ]);
    });

    test(
      'fails without contacting GitHub when the connection database fails',
      () async {
        await db.customStatement('DROP TABLE github_connections');

        final response = await requestSecrets();

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(jsonDecode(response.body), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(githubRequests, isEmpty);
      },
    );

    test('normalizes the operator URL for all GitHub requests', () async {
      environment['GITHUB_API_BASE_URL'] =
          ' https://github.example:8443/api/v3/// ';
      await db
          .update(db.gitHubConnections)
          .replace(
            connection.copyWith(
              githubApiBaseUrl: 'https://github.example:8443/api/v3',
            ),
          );

      final response = await requestSecrets();

      expect(response.statusCode, HttpStatus.ok);
      expect(jsonDecode(response.body), {
        'success': true,
        'secretsContent': 'GITHUB_TOKEN=$token\nASC_KEY=test-asc-value',
      });
      expect(githubRequests, hasLength(4));
      expect(
        githubRequests.map((request) => request.url.origin),
        everyElement('https://github.example:8443'),
      );
      expect(githubRequests.map((request) => request.url.path), [
        '/api/v3/repos/owner/repo/installation',
        '/api/v3/app/installations/98765/access_tokens',
        '/api/v3/repos/owner/repo/contents/openci/ci.dart',
        '/api/v3/repos/owner/repo/contents/openci/secrets.g.dart',
      ]);
    });
  });

  group('GET /builds/[id]/secrets', () {
    test('rejects unsupported methods without fetching secrets', () async {
      final response = await requestSecrets(
        workflow: 'Secrets.ascKey;',
        method: 'POST',
      );

      expect(response.statusCode, 405);
      expect(githubRequests, isEmpty);
    });

    for (final installationId in [null, '']) {
      test('rejects a missing installation ID: $installationId', () async {
        final response = await requestSecrets(
          workflow: 'Secrets.ascKey;',
          installationId: installationId,
        );

        expect(response.statusCode, 400);
        expect(jsonDecode(response.body), {
          'success': false,
          'error': 'No installationId found for job',
        });
        expect(githubRequests, isEmpty);
      });
    }

    test('rejects a missing workflow filename', () async {
      final response = await requestSecrets(
        workflow: 'Secrets.ascKey;',
        fileName: '',
      );

      expect(response.statusCode, 400);
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'No workflowFileName found for job',
      });
      expect(githubRequests, isEmpty);
    });

    for (final commitSha in ['job-commit', null]) {
      for (final import in [
        "import 'generated/secrets.g.dart';",
        'import "generated/secrets.g.dart";',
        "import './generated/secrets.g.dart';",
        "import '../generated/secrets.g.dart' show Secrets;",
      ]) {
        test(
          'resolves generated imports at the job ref: $import, $commitSha',
          () async {
            final response = await requestSecrets(
              workflow: '$import\nfinal key = Secrets.ascKey;',
              commitSha: commitSha,
            );

            expect(response.statusCode, 200);
            final body = jsonDecode(response.body) as Map<String, dynamic>;
            expect(
              body['secretsContent'],
              'GITHUB_TOKEN=$token\nASC_KEY=test-asc-value',
            );
            expect(requestedFiles, [
              'openci/ci.dart',
              'openci/generated/secrets.g.dart',
            ]);
          },
        );
      }

      test('resolves the getter using the same job ref: $commitSha', () async {
        final response = await requestSecrets(
          workflow: "import 'secrets.g.dart';\nfinal key = Secrets.ascKey;",
          commitSha: commitSha,
        );

        expect(response.statusCode, 200);
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(
          body['secretsContent'],
          'GITHUB_TOKEN=$token\nASC_KEY=test-asc-value',
        );
        expect(requestedFiles, [
          'openci/ci.dart',
          'openci/secrets.g.dart',
        ]);
      });
    }

    for (final expression in [
      'Secrets.ascKey',
      'Secrets.ascKey.key',
      'Secrets.ascKey.value',
    ]) {
      test(
        'injects the original secret for a Secret reference: $expression',
        () async {
          final response = await requestSecrets(
            workflow:
                "import 'generated/secrets.g.dart';\nfinal key = $expression;",
            secretDefinitions: '''
            import 'package:openci_workflow/openci_workflow.dart' show Secret;

            abstract final class Secrets {
              static const ascKey = Secret('ASC_KEY');
              static const unused = Secret('UNUSED_KEY');
            }
          ''',
          );

          expect(response.statusCode, 200);
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          expect(
            body['secretsContent'],
            'GITHUB_TOKEN=$token\nASC_KEY=test-asc-value',
          );
          expect(requestedFiles, [
            'openci/ci.dart',
            'openci/generated/secrets.g.dart',
          ]);
        },
      );
    }

    test(
      'does not require generated definitions when no getters are used',
      () async {
        final response = await requestSecrets(
          workflow: "import 'secrets.g.dart';\nvoid main() {}",
        );

        expect(response.statusCode, 200);
        expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['secretsContent'], 'GITHUB_TOKEN=$token');
        expect(requestedFiles, ['openci/ci.dart']);
      },
    );

    test(
      'preserves legacy YAML secret references and workflow location',
      () async {
        final response = await requestSecrets(
          fileName: 'ci.yml',
          workflow: 'run: echo \${{ secrets.ASC_KEY }}',
        );

        expect(response.statusCode, 200);
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(
          body['secretsContent'],
          'GITHUB_TOKEN=$token\nASC_KEY=test-asc-value',
        );
        expect(requestedFiles, ['.openci/ci.yml']);
      },
    );

    test('fails when the generated definitions cannot be fetched', () async {
      final response = await requestSecrets(
        workflow: 'final key = Secrets.ascKey;',
        definitionsStatus: 404,
      );

      expect(response.statusCode, 500);
      expect(requestedFiles, [
        'openci/ci.dart',
        'openci/secrets.g.dart',
      ]);
    });

    test(
      'does not use legacy definitions if the generated import is missing',
      () async {
        final response = await requestSecrets(
          workflow:
              "import 'generated/secrets.g.dart';\nfinal key = Secrets.ascKey;",
          definitionsStatus: 404,
        );

        expect(response.statusCode, 500);
        expect(requestedFiles, [
          'openci/ci.dart',
          'openci/generated/secrets.g.dart',
        ]);
      },
    );

    test('fails instead of silently omitting an unresolved getter', () async {
      final response = await requestSecrets(workflow: 'Secrets.unknown;');

      expect(response.statusCode, 500);
      expect(requestedFiles, [
        'openci/ci.dart',
        'openci/secrets.g.dart',
      ]);
    });

    test('does not return partial credentials when decryption fails', () async {
      final now = DateTime.utc(2026, 9, 7);
      await db.secretDao.insertOrUpdateSecret(
        DriftSecret(
          name: 'ASC_KEY',
          teamId: 'team-1',
          encryptedValue: 'invalid-ciphertext',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final response = await requestSecrets(workflow: 'Secrets.ascKey;');

      expect(response.statusCode, 500);
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'Internal server error',
      });
    });

    test('escapes multiline secret values in the environment file', () async {
      final now = DateTime.utc(2026, 9, 7);
      final encrypted = await SecretCrypter(encryptionKey).encrypt(
        '-----BEGIN KEY-----\nsecret value\n-----END KEY-----\n',
      );
      await db.secretDao.insertOrUpdateSecret(
        DriftSecret(
          name: 'ASC_KEY',
          teamId: 'team-1',
          encryptedValue: encrypted,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final response = await requestSecrets(workflow: 'Secrets.ascKey;');

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(
        body['secretsContent'],
        'GITHUB_TOKEN=$token\n'
        r'ASC_KEY=-----BEGIN KEY-----\nsecret value\n-----END KEY-----\n',
      );
    });
  });
}
