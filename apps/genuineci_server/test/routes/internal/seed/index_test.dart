import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:genuineci_server/auth/internal_api_key_validator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:genuineci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../routes/internal/_middleware.dart' as internal;
import '../../../../routes/internal/seed/index.dart' as route;
import '../../../helpers/github_app_test_key.dart';

void main() {
  late AppDatabase db;
  late Directory tempDirectory;
  late Map<String, String> environment;
  late List<http.Request> requests;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDirectory = await Directory.systemTemp.createTemp('seed_route_test_');
    final keyFile = File('${tempDirectory.path}/key.pem');
    await keyFile.writeAsString(testRsaPrivateKey);
    environment = {
      'GITHUB_APP_ID': '123',
      'GITHUB_PRIVATE_KEY_PATH': keyFile.path,
      'GITHUB_API_BASE_URL': 'https://api.github.test',
    };
    requests = [];
  });
  tearDown(() async {
    await db.close();
    await tempDirectory.delete(recursive: true);
  });

  Future<Response> seed(
    Map<String, Object?> body, {
    int githubStatus = 200,
    bool provideConfiguration = true,
  }) async {
    const validator = InternalApiKeyValidator.forTesting(
      environment: {'INTERNAL_API_KEY': 'test-internal-key'},
    );
    final context = TestRequestContext(
      path: '/internal/seed',
      method: HttpMethod.post,
      headers: {'Authorization': 'Bearer test-internal-key'},
      body: jsonEncode(body),
    )..provide<AppDatabase>(db);
    context.provide<InternalApiKeyValidator>(validator);
    if (provideConfiguration) {
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"id":42}', githubStatus);
      });
      addTearDown(client.close);
      context.provide<Map<String, String>>(environment);
      context.provide<http.Client>(client);
    }
    return await internal.middleware(route.onRequest)(context.context);
  }

  test(
    'creates one queued job and associates its installation with the team',
    () async {
      final response = await seed({
        'owner': 'example',
        'repo': 'mobile',
        'commitSha': '0123456789abcdef0123456789abcdef01234567',
        'workflowName': 'checks/smoke.dart',
        'workflowFileName': 'checks/smoke.dart',
        'installationId': '42',
        'branch': 'feature/worker',
      });

      expect(response.statusCode, HttpStatus.ok);
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);
      final jobs = await db.buildJobDao.getQueuedJobs();
      expect(jobs, hasLength(1));
      final job = jobs.single;
      expect(job.id, body['jobId']);
      expect(job.status, BuildJobStatus.QUEUED);
      expect(job.owner, 'example');
      expect(job.repo, 'mobile');
      expect(job.commitSha, '0123456789abcdef0123456789abcdef01234567');
      expect(job.workflowName, 'checks/smoke.dart');
      expect(job.workflowFileName, 'checks/smoke.dart');
      expect(job.branch, 'feature/worker');
      expect(job.installationId, '42');
      expect(job.runsOn, 'macos-latest');
      expect((await db.teamDao.getTeam(job.teamId!))!.installationIds, [42]);
      expect(requests, isEmpty);
    },
  );

  test('adds the installation without replacing an existing team', () async {
    await db.seedDao.ensureTestTeam(installationId: 11);

    final response = await seed({'installationId': '42'});

    expect(response.statusCode, HttpStatus.ok);
    expect((await db.teamDao.getTeam('test-team'))!.installationIds, [11, 42]);
    expect((await db.buildJobDao.getQueuedJobs()).single.installationId, '42');
  });

  test(
    'seeds the fixed smoke job and resolves the installation with an empty body',
    () async {
      final response = await seed({});

      expect(response.statusCode, HttpStatus.ok);
      final job = (await db.buildJobDao.getQueuedJobs()).single;
      expect(job.owner, 'openci-org');
      expect(job.repo, 'openci');
      expect(job.commitSha, '5cb05f76d8941ea1edc3593eb753ce808f0f290e');
      expect(job.workflowName, 'Build job worker smoke');
      expect(job.workflowFileName, 'worker_smoke.dart');
      expect(job.branch, 'test/build-job-worker-smoke-openci');
      expect(job.runsOn, 'macos-latest');
      expect(job.teamId, 'test-team');
      expect(job.installationId, '42');
      expect((await db.teamDao.getTeam('test-team'))!.installationIds, [42]);
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/repos/openci-org/openci/installation');
    },
  );

  test(
    'looks up the requested repository when the API caller supplies one',
    () async {
      final response = await seed({'owner': 'example', 'repo': 'mobile'});

      expect(response.statusCode, HttpStatus.ok);
      expect(requests.single.url.path, '/repos/example/mobile/installation');
      expect(
        (await db.buildJobDao.getQueuedJobs()).single.installationId,
        '42',
      );
    },
  );

  test(
    'does not seed a team or job if the App cannot access the repository',
    () async {
      final response = await seed({}, githubStatus: 404);

      expect(response.statusCode, HttpStatus.internalServerError);
      expect((await response.json())['error'], contains('404'));
      expect(await db.teamDao.getTeam('test-team'), isNull);
      expect(await db.buildJobDao.getQueuedJobs(), isEmpty);
    },
  );

  test(
    'reports missing process configuration before creating seed data',
    () async {
      final response = await seed({}, provideConfiguration: false);

      expect(response.statusCode, HttpStatus.internalServerError);
      expect((await response.json())['error'], contains('GITHUB_APP_ID'));
      expect(await db.teamDao.getTeam('test-team'), isNull);
      expect(await db.buildJobDao.getQueuedJobs(), isEmpty);
    },
    skip: Platform.environment['GITHUB_APP_ID']?.isNotEmpty == true
        ? 'The process has a GitHub App configured.'
        : false,
  );

  for (final installationId in ['', 'abc', '0', '-1']) {
    test(
      'rejects installation ID "$installationId" before writing data',
      () async {
        final response = await seed({'installationId': installationId});

        expect(response.statusCode, HttpStatus.badRequest);
        expect((await response.json())['success'], isFalse);
        expect(await db.teamDao.getTeam('test-team'), isNull);
        expect(await db.buildJobDao.getQueuedJobs(), isEmpty);
      },
    );
  }
}
