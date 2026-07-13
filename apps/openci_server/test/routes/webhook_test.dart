import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/webhook_task_processor.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../routes/webhook.dart' as route;

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
  group('POST /webhook', () {
    const testSecret = 'super-secret-key';
    const testBody = '{"event": "push", "ref": "refs/heads/main"}';

    test(
      'responds with 405 Method Not Allowed when method is not POST',
      () async {
        final context = TestRequestContext(
          path: '/webhook',
          method: HttpMethod.get,
        );

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      },
    );

    test('responds with 401 when signature header is missing', () async {
      final context = TestRequestContext(
        path: '/webhook',
        method: HttpMethod.post,
        body: testBody,
      );

      context.provide<Map<String, String>>({
        'GITHUB_WEBHOOK_SECRET': testSecret,
      });

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], equals('Missing or invalid signature header'));
    });

    test('responds with 401 when signature header format is invalid', () async {
      final context = TestRequestContext(
        path: '/webhook',
        method: HttpMethod.post,
        body: testBody,
        headers: {
          'x-hub-signature-256': 'invalid-format-signature-value',
        },
      );

      context.provide<Map<String, String>>({
        'GITHUB_WEBHOOK_SECRET': testSecret,
      });

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], equals('Missing or invalid signature header'));
    });

    test('responds with 401 when signature does not match', () async {
      final context = TestRequestContext(
        path: '/webhook',
        method: HttpMethod.post,
        body: testBody,
        headers: {
          'x-hub-signature-256':
              'sha256=wrongsignaturevalue12345678901234567890',
        },
      );

      context.provide<Map<String, String>>({
        'GITHUB_WEBHOOK_SECRET': testSecret,
      });

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], equals('Signature mismatch'));
    });
  });

  group('constantTimeCompare', () {
    test('returns true for identical lists', () {
      expect(
        constantTimeCompare([1, 2, 3], [1, 2, 3]),
        isTrue,
      );
    });

    test('returns false for lists of different lengths', () {
      expect(
        constantTimeCompare([1, 2, 3], [1, 2]),
        isFalse,
      );
      expect(
        constantTimeCompare([1, 2], [1, 2, 3]),
        isFalse,
      );
    });

    test('returns false for lists with different values at the beginning', () {
      expect(
        constantTimeCompare([9, 2, 3], [1, 2, 3]),
        isFalse,
      );
    });

    test('returns false for lists with different values in the middle', () {
      expect(
        constantTimeCompare([1, 9, 3], [1, 2, 3]),
        isFalse,
      );
    });

    test('returns false for lists with different values at the end', () {
      expect(
        constantTimeCompare([1, 2, 9], [1, 2, 3]),
        isFalse,
      );
    });

    test('returns true for empty lists', () {
      expect(
        constantTimeCompare([], []),
        isTrue,
      );
    });
  });

  group('Step 2: Full Webhook Process Integration Tests', () {
    const testSecret = 'super-secret-key';
    late AppDatabase db;
    late File tempPrivateKeyFile;

    String computeSignature(String body, String secret) {
      final key = utf8.encode(secret);
      final hmacSha256 = Hmac(sha256, key);
      final digest = hmacSha256.convert(utf8.encode(body));
      return 'sha256=$digest';
    }

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.now().toUtc();
      final testTeam = DriftTeam(
        id: 'team-123',
        name: 'Test Team',
        installationIds: [98765],
        aiEnabled: false,
        runNumber: 1,
        createdAt: now,
        updatedAt: now,
      );
      await db.into(db.teams).insert(testTeam);

      final tempDir = Directory.systemTemp.createTempSync();
      tempPrivateKeyFile = File(p.join(tempDir.path, 'test_private_key.pem'));
      tempPrivateKeyFile.writeAsStringSync(testRsaPrivateKey);
    });

    tearDown(() async {
      await db.close();
      if (tempPrivateKeyFile.existsSync()) {
        tempPrivateKeyFile.deleteSync();
      }
    });

    test(
      'successfully processes pull_request webhook and inserts BuildJob to DB',
      () async {
        final prBody = jsonEncode({
          'action': 'opened',
          'number': 42,
          'pull_request': {
            'number': 42,
            'id': 999,
            'head': {
              'sha': 'commit-sha-123',
              'ref': 'feature-branch',
            },
            'base': {
              'ref': 'main',
            },
          },
          'repository': {
            'id': 12345,
            'name': 'openci-repo',
            'owner': {
              'id': 12345,
              'login': 'openci-owner',
              'avatar_url': 'https://github.com/avatar',
              'html_url': 'https://github.com/openci-owner',
            },
          },
          'installation': {
            'id': 98765,
          },
        });

        final mockClient = MockClient((request) async {
          if (request.url.path.contains('/access_tokens')) {
            return http.Response(
              jsonEncode({
                'token': 'mock-access-token-999',
                'expires_at': '2026-06-19T20:00:00Z',
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/contents/.openci')) {
            return http.Response(
              jsonEncode([
                {
                  'name': 'build.yaml',
                  'path': '.openci/build.yaml',
                  'type': 'file',
                },
              ]),
              200,
            );
          }
          if (request.url.path.endsWith('/contents/.openci/build.yaml')) {
            return http.Response(
              '''
name: CI Build
on:
  pull_request:
    branches: [main]
jobs:
  test_job:
    runs-on: macos-13
    steps:
      - run: echo "Hello"
''',
              200,
            );
          }
          if (request.url.path.endsWith('/check-runs')) {
            return http.Response(
              jsonEncode({
                'id': 54321,
              }),
              201,
            );
          }
          return http.Response('Not Found', 404);
        });

        final signature = computeSignature(prBody, testSecret);
        final context = TestRequestContext(
          path: '/webhook',
          method: HttpMethod.post,
          body: prBody,
          headers: {
            'x-hub-signature-256': signature,
            'x-github-event': 'pull_request',
            'x-github-delivery': 'test-delivery-id-123',
          },
        );

        context.provide<Map<String, String>>({
          'GITHUB_WEBHOOK_SECRET': testSecret,
          'GITHUB_APP_ID': '12345',
          'GITHUB_PRIVATE_KEY_PATH': tempPrivateKeyFile.path,
          'GITHUB_API_BASE_URL': 'https://api.github.com',
        });

        context.provide<AppDatabase>(db);
        context.provide<http.Client>(mockClient);

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.ok));
        final resBody = await response.json() as Map<String, dynamic>;
        expect(resBody['success'], isTrue);
        expect(resBody['message'], equals('Webhook received and queued.'));

        final task = await db.webhookTaskDao.claimNextWebhookTask();
        expect(task, isNotNull);
        await processWebhookTask(
          db,
          task!,
          environment: {
            'GITHUB_WEBHOOK_SECRET': testSecret,
            'GITHUB_APP_ID': '12345',
            'GITHUB_PRIVATE_KEY_PATH': tempPrivateKeyFile.path,
            'GITHUB_API_BASE_URL': 'https://api.github.com',
          },
          client: mockClient,
        );

        final jobs = await db.select(db.buildJobs).get();
        expect(jobs, hasLength(1));

        final savedJob = jobs.first;
        expect(savedJob.owner, equals('openci-owner'));
        expect(savedJob.repo, equals('openci-repo'));
        expect(savedJob.workflowName, equals('CI Build'));
        expect(savedJob.branch, equals('feature-branch'));
        expect(savedJob.pullRequestNumber, equals(42));
        expect(savedJob.installationId, equals('98765'));
        expect(savedJob.checkRunId, equals('54321'));
      },
    );

    test(
      'successfully processes push webhook with matrix build and resolves status/needs',
      () async {
        final pushBody = jsonEncode({
          'ref': 'refs/heads/main',
          'deleted': false,
          'head_commit': {
            'id': 'commit-sha-456',
          },
          'repository': {
            'name': 'openci-repo',
            'owner': {
              'login': 'openci-owner',
            },
          },
          'installation': {
            'id': 98765,
          },
        });

        final mockClient = MockClient((request) async {
          if (request.url.path.contains('/access_tokens')) {
            return http.Response(
              jsonEncode({
                'token': 'mock-access-token-999',
                'expires_at': '2026-06-19T20:00:00Z',
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/contents/.openci')) {
            return http.Response(
              jsonEncode([
                {
                  'name': 'matrix_build.yaml',
                  'path': '.openci/matrix_build.yaml',
                  'type': 'file',
                },
              ]),
              200,
            );
          }
          if (request.url.path.endsWith(
            '/contents/.openci/matrix_build.yaml',
          )) {
            return http.Response(
              '''
name: Matrix Workflow
on:
  push:
    branches: [main]
jobs:
  build:
    strategy:
      matrix:
        target: [ios, android]
    runs-on: macos-13
    steps:
      - run: echo "Building for \${{ matrix.target }}"
  deploy:
    needs: build
    runs-on: macos-13
    steps:
      - run: echo "Deploying"
''',
              200,
            );
          }
          if (request.url.path.endsWith('/check-runs')) {
            return http.Response(
              jsonEncode({
                'id': 777,
              }),
              201,
            );
          }
          return http.Response('Not Found', 404);
        });

        final signature = computeSignature(pushBody, testSecret);
        final context = TestRequestContext(
          path: '/webhook',
          method: HttpMethod.post,
          body: pushBody,
          headers: {
            'x-hub-signature-256': signature,
            'x-github-event': 'push',
            'x-github-delivery': 'test-delivery-id-456',
          },
        );

        context.provide<Map<String, String>>({
          'GITHUB_WEBHOOK_SECRET': testSecret,
          'GITHUB_APP_ID': '12345',
          'GITHUB_PRIVATE_KEY_PATH': tempPrivateKeyFile.path,
          'GITHUB_API_BASE_URL': 'https://api.github.com',
        });

        context.provide<AppDatabase>(db);
        context.provide<http.Client>(mockClient);

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.ok));
        final resBody = await response.json() as Map<String, dynamic>;
        expect(resBody['success'], isTrue);
        expect(resBody['message'], equals('Webhook received and queued.'));

        final task = await db.webhookTaskDao.claimNextWebhookTask();
        expect(task, isNotNull);
        await processWebhookTask(
          db,
          task!,
          environment: {
            'GITHUB_WEBHOOK_SECRET': testSecret,
            'GITHUB_APP_ID': '12345',
            'GITHUB_PRIVATE_KEY_PATH': tempPrivateKeyFile.path,
            'GITHUB_API_BASE_URL': 'https://api.github.com',
          },
          client: mockClient,
        );

        final jobs = await db.select(db.buildJobs).get();
        expect(jobs, hasLength(3));

        final buildIos = jobs.firstWhere(
          (j) => j.jobKey == 'build[target=ios]',
        );
        final buildAndroid = jobs.firstWhere(
          (j) => j.jobKey == 'build[target=android]',
        );
        final deploy = jobs.firstWhere((j) => j.jobKey == 'deploy');

        expect(buildIos.status, equals(BuildJobStatus.QUEUED));
        expect(buildAndroid.status, equals(BuildJobStatus.QUEUED));
        expect(deploy.status, equals(BuildJobStatus.WAITING));
        expect(
          deploy.needs,
          containsAll(['build[target=ios]', 'build[target=android]']),
        );
      },
    );

    test(
      'returns early when webhook delivery has already been processed',
      () async {
        final prBody = jsonEncode({
          'action': 'opened',
          'number': 42,
          'pull_request': {
            'number': 42,
            'id': 999,
            'head': {
              'sha': 'commit-sha-123',
              'ref': 'feature-branch',
            },
            'base': {
              'ref': 'main',
            },
          },
          'repository': {
            'id': 12345,
            'name': 'openci-repo',
            'owner': {
              'id': 12345,
              'login': 'openci-owner',
              'avatar_url': 'https://github.com/avatar',
              'html_url': 'https://github.com/openci-owner',
            },
          },
          'installation': {
            'id': 98765,
          },
        });

        final mockClient = MockClient((request) async {
          if (request.url.path.contains('/access_tokens')) {
            return http.Response(
              jsonEncode({
                'token': 'mock-access-token-999',
                'expires_at': '2026-06-19T20:00:00Z',
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/contents/.openci')) {
            return http.Response(
              jsonEncode([
                {
                  'name': 'build.yaml',
                  'path': '.openci/build.yaml',
                  'type': 'file',
                },
              ]),
              200,
            );
          }
          if (request.url.path.endsWith('/contents/.openci/build.yaml')) {
            return http.Response(
              '''
name: CI Build
on:
  pull_request:
    branches:
      - main
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Hello"
''',
              200,
            );
          }
          if (request.url.path.endsWith('/check-runs')) {
            return http.Response(
              jsonEncode({
                'id': 54321,
              }),
              201,
            );
          }
          return http.Response('Not Found', 404);
        });

        final signature = computeSignature(prBody, testSecret);

        // First call - should process successfully
        final context1 = TestRequestContext(
          path: '/webhook',
          method: HttpMethod.post,
          body: prBody,
          headers: {
            'x-hub-signature-256': signature,
            'x-github-event': 'pull_request',
            'x-github-delivery': 'test-delivery-id-789',
          },
        );

        context1.provide<Map<String, String>>({
          'GITHUB_WEBHOOK_SECRET': testSecret,
          'GITHUB_APP_ID': '12345',
          'GITHUB_PRIVATE_KEY_PATH': tempPrivateKeyFile.path,
          'GITHUB_API_BASE_URL': 'https://api.github.com',
        });
        context1.provide<AppDatabase>(db);
        context1.provide<http.Client>(mockClient);

        final response1 = await route.onRequest(context1.context);
        expect(response1.statusCode, equals(HttpStatus.ok));
        final resBody1 = await response1.json() as Map<String, dynamic>;
        expect(resBody1['success'], isTrue);
        expect(resBody1['message'], equals('Webhook received and queued.'));

        final task = await db.webhookTaskDao.claimNextWebhookTask();
        expect(task, isNotNull);
        await processWebhookTask(
          db,
          task!,
          environment: {
            'GITHUB_WEBHOOK_SECRET': testSecret,
            'GITHUB_APP_ID': '12345',
            'GITHUB_PRIVATE_KEY_PATH': tempPrivateKeyFile.path,
            'GITHUB_API_BASE_URL': 'https://api.github.com',
          },
          client: mockClient,
        );

        final jobs = await db.select(db.buildJobs).get();
        expect(jobs, hasLength(1));

        // Second call with same delivery ID - should return early without duplicating jobs
        final context2 = TestRequestContext(
          path: '/webhook',
          method: HttpMethod.post,
          body: prBody,
          headers: {
            'x-hub-signature-256': signature,
            'x-github-event': 'pull_request',
            'x-github-delivery': 'test-delivery-id-789',
          },
        );

        context2.provide<Map<String, String>>({
          'GITHUB_WEBHOOK_SECRET': testSecret,
          'GITHUB_APP_ID': '12345',
          'GITHUB_PRIVATE_KEY_PATH': tempPrivateKeyFile.path,
          'GITHUB_API_BASE_URL': 'https://api.github.com',
        });
        context2.provide<AppDatabase>(db);
        context2.provide<http.Client>(mockClient);

        final response2 = await route.onRequest(context2.context);
        expect(response2.statusCode, equals(HttpStatus.ok));
        final resBody2 = await response2.json() as Map<String, dynamic>;
        expect(resBody2['success'], isTrue);
        expect(resBody2['message'], contains('already processed'));

        // DB job count should still be 1 (no duplicate creation)
        final jobsAfter = await db.select(db.buildJobs).get();
        expect(jobsAfter, hasLength(1));
      },
    );
  });
}
