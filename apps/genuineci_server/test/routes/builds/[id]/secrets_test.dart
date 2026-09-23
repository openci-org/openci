import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:genuineci_server/database.dart';
import 'package:genuineci_server/secret/secret_crypter.dart';
import 'package:genuineci_server/secret/secret_dao.dart';
import 'package:genuineci_server/secret/secret_table.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../routes/builds/[id]/secrets.dart' as route;
import '../../../helpers/github_app_test_key.dart';

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockSecretDao extends Mock implements SecretDao {}

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
  late SecretDao dao;
  late Directory tempDir;
  late Map<String, String> environment;
  late List<String> requestedFiles;

  setUp(() async {
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
    dao = _MockSecretDao();
    db = _MockAppDatabase();
    when(() => db.secretDao).thenReturn(dao);
    when(
      () => dao.getSecretsForTeam('team-1'),
    ).thenAnswer((_) async => secrets);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<Response> requestSecrets({
    required String workflow,
    String fileName = 'ci.dart',
    String? installationId = '98765',
    String? commitSha = 'job-commit',
    int definitionsStatus = 200,
    HttpMethod method = HttpMethod.get,
  }) async {
    final directory = fileName.endsWith('.dart') ? 'openci' : '.openci';
    final client = MockClient((request) async {
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
      if (file == 'openci/secrets.g.dart' && definitionsStatus != 200) {
        return http.Response('Not found', definitionsStatus);
      }
      final content = switch (file) {
        'openci/secrets.g.dart' => definitions,
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
    addTearDown(client.close);

    final context = TestRequestContext(
      path: '/builds/job-1/secrets',
      method: method,
    );
    final now = DateTime.utc(2026, 9, 7);
    context.provide<DriftBuildJob>(
      DriftBuildJob(
        id: 'job-1',
        owner: 'owner',
        repo: 'repo',
        teamId: 'team-1',
        installationId: installationId,
        commitSha: commitSha,
        branch: 'feature/ci',
        status: BuildJobStatus.IN_PROGRESS,
        workflowName: 'CI',
        workflowFileName: fileName,
        createdAt: now,
        updatedAt: now,
      ),
    );
    context.provide<AppDatabase>(db);
    context.provide<Map<String, String>>(environment);
    context.provide<http.Client>(client);
    return route.onRequest(context.context, 'job-1');
  }

  group('GET /builds/[id]/secrets', () {
    test('rejects unsupported methods without fetching secrets', () async {
      final response = await requestSecrets(
        workflow: 'Secrets.ascKey;',
        method: HttpMethod.post,
      );

      expect(response.statusCode, 405);
      expect(requestedFiles, isEmpty);
      verifyNever(() => dao.getSecretsForTeam('team-1'));
    });

    for (final installationId in [null, '']) {
      test('rejects a missing installation ID: $installationId', () async {
        final response = await requestSecrets(
          workflow: 'Secrets.ascKey;',
          installationId: installationId,
        );

        expect(response.statusCode, 400);
        expect(await response.json(), {
          'success': false,
          'error': 'No installationId found for job',
        });
        expect(requestedFiles, isEmpty);
        verifyNever(() => dao.getSecretsForTeam('team-1'));
      });
    }

    test('rejects a missing workflow filename', () async {
      final response = await requestSecrets(
        workflow: 'Secrets.ascKey;',
        fileName: '',
      );

      expect(response.statusCode, 400);
      expect(await response.json(), {
        'success': false,
        'error': 'No workflowFileName found for job',
      });
      expect(requestedFiles, isEmpty);
      verifyNever(() => dao.getSecretsForTeam('team-1'));
    });

    for (final commitSha in ['job-commit', null]) {
      test('resolves the getter using the same job ref: $commitSha', () async {
        final response = await requestSecrets(
          workflow: "import 'secrets.g.dart';\nfinal key = Secrets.ascKey;",
          commitSha: commitSha,
        );

        expect(response.statusCode, 200);
        final body = await response.json() as Map<String, dynamic>;
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

    test(
      'does not require generated definitions when no getters are used',
      () async {
        final response = await requestSecrets(
          workflow: "import 'secrets.g.dart';\nvoid main() {}",
        );

        expect(response.statusCode, 200);
        final body = await response.json() as Map<String, dynamic>;
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
        final body = await response.json() as Map<String, dynamic>;
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
      when(() => dao.getSecretsForTeam('team-1')).thenAnswer(
        (_) async => [
          DriftSecret(
            name: 'ASC_KEY',
            teamId: 'team-1',
            encryptedValue: 'invalid-ciphertext',
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final response = await requestSecrets(workflow: 'Secrets.ascKey;');

      verify(() => dao.getSecretsForTeam('team-1')).called(1);
      expect(response.statusCode, 500);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
    });

    test('escapes multiline secret values in the environment file', () async {
      final now = DateTime.utc(2026, 9, 7);
      final encrypted = await SecretCrypter(encryptionKey).encrypt(
        '-----BEGIN KEY-----\nsecret value\n-----END KEY-----\n',
      );
      when(() => dao.getSecretsForTeam('team-1')).thenAnswer(
        (_) async => [
          DriftSecret(
            name: 'ASC_KEY',
            teamId: 'team-1',
            encryptedValue: encrypted,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final response = await requestSecrets(workflow: 'Secrets.ascKey;');

      expect(response.statusCode, 200);
      final body = await response.json() as Map<String, dynamic>;
      expect(
        body['secretsContent'],
        'GITHUB_TOKEN=$token\n'
        r'ASC_KEY=-----BEGIN KEY-----\nsecret value\n-----END KEY-----\n',
      );
    });
  });
}
