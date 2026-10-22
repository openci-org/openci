import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/billing/billing_proxy.dart';
import 'package:openci_server/billing/billing_proxy_config.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/build_job/build_job_dao.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../routes/worker/_middleware.dart' as worker;
import '../../../../routes/worker/jobs/claim.dart' as route;

class _MockDatabase extends Mock implements AppDatabase {}

class _MockBuildJobDao extends Mock implements BuildJobDao {}

void main() {
  late AppDatabase db;
  late BuildJobDao dao;

  setUp(() {
    db = _MockDatabase();
    dao = _MockBuildJobDao();
    when(() => db.buildJobDao).thenReturn(dao);
  });

  Future<Response> request({
    HttpMethod method = HttpMethod.post,
    String? uid,
    String? token = 'test-internal-key',
    Map<String, String> environment = const {
      'INTERNAL_API_KEY': 'test-internal-key',
      'GITHUB_API_BASE_URL': 'https://api.github.com',
    },
    String body = '{}',
    BillingProxy? billingProxy,
  }) {
    final context = TestRequestContext(
      path: '/worker/jobs/claim',
      method: method,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
    );
    context.provide<AppDatabase>(db);
    context.provide<String?>(uid);
    context.provide<Map<String, String>>(environment);
    context.provide<InternalApiKeyValidator>(
      InternalApiKeyValidator(environment: environment),
    );
    context.provide<BillingProxy?>(billingProxy);
    final requestContext = context.context;
    when(
      () => requestContext.provide<BillingProxy?>(any()),
    ).thenReturn(requestContext);
    return Future.value(worker.middleware(route.onRequest)(requestContext));
  }

  group('paid Cloud claims', () {
    const environment = {
      'SERVER_ACCESS_MODE': 'cloud',
      'BILLING_ENABLED': 'true',
      'INTERNAL_API_KEY': 'test-internal-key',
      'GITHUB_API_BASE_URL': 'https://api.github.com',
      'GENUINECI_SERVER_URL': 'http://genuineci-server:8081',
      'BILLING_INTERNAL_TOKEN': '01234567890123456789012345678901',
    };
    final job = DriftBuildJob(
      id: 'job-1',
      status: BuildJobStatus.IN_PROGRESS,
      workerHost: 'worker-1',
      owner: 'org',
      repo: 'repo',
      workflowName: 'CI',
      workflowFileName: 'ci.dart',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    test(
      'returns the admitted job without calling the unrestricted DAO',
      () async {
        final client = MockClient((incoming) async {
          expect(incoming.url.path, '/internal/billing/worker/claim');
          expect(
            jsonDecode(incoming.body),
            containsPair('workerHost', 'worker-1'),
          );
          return http.Response(
            '{"claim":{"jobId":"job-1","admissionId":"admission-1"}}',
            200,
          );
        });
        addTearDown(client.close);
        when(() => dao.getBuildJob('job-1')).thenAnswer((_) async => job);
        final response = await request(
          environment: environment,
          body: '{"workerHost":"worker-1"}',
          billingProxy: BillingProxy(
            BillingProxyConfig.fromEnvironment(environment)!,
            client,
          ),
        );
        expect(response.statusCode, 200);
        final body = await response.json() as Map<String, dynamic>;
        expect(body['job'], containsPair('billingAdmissionId', 'admission-1'));
        expect(
          body['job'],
          containsPair('githubBaseUrl', 'https://github.com'),
        );
        verify(() => dao.getBuildJob('job-1')).called(1);
        verifyNoMoreInteractions(dao);
      },
    );
    for (final (status, body) in [
      (200, '{"claim":null}'),
      (503, '{"error":"billing_unavailable"}'),
    ]) {
      test('never falls back when billing returns $status $body', () async {
        final client = MockClient((_) async => http.Response(body, status));
        addTearDown(client.close);
        final response = await request(
          environment: environment,
          body: '{"workerHost":"worker-1"}',
          billingProxy: BillingProxy(
            BillingProxyConfig.fromEnvironment(environment)!,
            client,
          ),
        );
        expect(response.statusCode, status);
        if (status == 200) expect(await response.json(), {'job': null});
        verifyZeroInteractions(dao);
      });
    }
    test('rejects a job no longer owned by the requesting worker', () async {
      final client = MockClient(
        (_) async => http.Response(
          '{"claim":{"jobId":"job-1","admissionId":"admission-1"}}',
          200,
        ),
      );
      addTearDown(client.close);
      when(() => dao.getBuildJob('job-1')).thenAnswer((_) async => job);
      final response = await request(
        environment: environment,
        body: '{"workerHost":"worker-2"}',
        billingProxy: BillingProxy(
          BillingProxyConfig.fromEnvironment(environment)!,
          client,
        ),
      );
      expect(response.statusCode, 409);
      expect(await response.json(), {'error': 'admission_not_current'});
    });
    test('missing billing transport fails closed', () async {
      final response = await request(environment: environment);
      expect(response.statusCode, 503);
      verifyZeroInteractions(dao);
    });
    test('Firebase users cannot invoke paid worker claims', () async {
      final client = MockClient(
        (_) async => throw StateError('must not call billing'),
      );
      addTearDown(client.close);
      final response = await request(
        environment: environment,
        token: 'firebase-token',
        uid: 'user-1',
        billingProxy: BillingProxy(
          BillingProxyConfig.fromEnvironment(environment)!,
          client,
        ),
      );
      expect(response.statusCode, 401);
      verifyZeroInteractions(dao);
    });
  });

  group('POST /worker/jobs/claim', () {
    test('rejects other methods without claiming a job', () async {
      expect(
        (await request(method: HttpMethod.get)).statusCode,
        HttpStatus.methodNotAllowed,
      );
      verifyZeroInteractions(dao);
    });

    for (final (name, token, uid) in [
      ('missing credentials', null, null),
      ('an empty token', '', null),
      ('an incorrect key', 'wrong-internal-key', 'system-job-processor'),
      ('a Firebase user token', 'firebase-id-token', 'user-1'),
      (
        'a Firebase token with the reserved UID',
        'firebase-id-token',
        'system-job-processor',
      ),
    ]) {
      test('rejects $name before reading the body or database', () async {
        final response = await request(
          token: token,
          uid: uid,
          body: 'not-json',
        );

        expect(response.statusCode, HttpStatus.unauthorized);
        expect(await response.json(), {
          'success': false,
          'error': 'Authentication required',
        });
        verifyZeroInteractions(db);
        verifyZeroInteractions(dao);
      });
    }

    test('rejects requests when the internal key is not configured', () async {
      final response = await request(environment: {});

      expect(response.statusCode, HttpStatus.unauthorized);
      verifyZeroInteractions(db);
      verifyZeroInteractions(dao);
    });

    test(
      'rejects requests when the configured internal key is empty',
      () async {
        final response = await request(
          token: '',
          environment: {'INTERNAL_API_KEY': ''},
        );

        expect(response.statusCode, HttpStatus.unauthorized);
        verifyZeroInteractions(db);
        verifyZeroInteractions(dao);
      },
    );

    for (final body in ['not-json', '[]']) {
      test('rejects invalid request body: $body', () async {
        final response = await request(body: body);

        expect(response.statusCode, HttpStatus.badRequest);
        verifyZeroInteractions(dao);
      });
    }

    test(
      'accepts the internal key without a UID and returns an empty queue',
      () async {
        when(() => dao.claimNextJob()).thenAnswer((_) async => null);

        final response = await request();

        expect(response.statusCode, HttpStatus.ok);
        expect(await response.json(), {'job': null});
        verify(() => dao.claimNextJob()).called(1);
      },
    );

    test(
      'passes worker settings to the DAO and returns the public job',
      () async {
        final job = DriftBuildJob(
          id: 'job-1',
          status: BuildJobStatus.IN_PROGRESS,
          owner: 'org',
          repo: 'repo',
          workflowName: 'CI',
          workflowFileName: 'ci.dart',
          vmName: 'vm-a',
          workerHost: 'host-a',
          installationId: '98765',
          checkRunId: '123',
          createdAt: DateTime.utc(2026, 9, 1),
          updatedAt: DateTime.utc(2026, 9, 1),
        );
        when(
          () => dao.claimNextJob(
            vmName: 'vm-a',
            workerHost: 'host-a',
            maxConcurrentJobs: 2,
          ),
        ).thenAnswer((_) async => job);

        final response = await request(
          body: jsonEncode({
            'vmName': 'vm-a',
            'workerHost': 'host-a',
            'maxConcurrentJobs': 2,
          }),
        );

        expect(response.statusCode, HttpStatus.ok);
        final body = await response.json() as Map<String, dynamic>;
        final returned = body['job'] as Map<String, dynamic>;
        expect(BuildJob.fromJson(returned).id, 'job-1');
        expect(returned['status'], 'IN_PROGRESS');
        expect(returned['vmName'], 'vm-a');
        expect(returned['workerHost'], 'host-a');
        expect(returned['githubBaseUrl'], 'https://github.com');
        expect(returned, isNot(contains('installationId')));
        expect(returned, isNot(contains('checkRunId')));
        verify(
          () => dao.claimNextJob(
            vmName: 'vm-a',
            workerHost: 'host-a',
            maxConcurrentJobs: 2,
          ),
        ).called(1);
      },
    );

    for (final (apiUrl, repositoryUrl) in [
      ('https://api.github.com', 'https://github.com'),
      ('https://github.example.com/api/v3', 'https://github.example.com'),
    ]) {
      for (final savedUrl in [
        null,
        'https://github.com',
        'https://untrusted.example',
      ]) {
        test('uses $apiUrl when the saved job URL is $savedUrl', () async {
          final job = DriftBuildJob(
            id: 'job-1',
            status: BuildJobStatus.IN_PROGRESS,
            owner: 'org',
            repo: 'repo',
            workflowName: 'CI',
            workflowFileName: 'ci.dart',
            githubBaseUrl: savedUrl,
            createdAt: DateTime.utc(2026, 9, 1),
            updatedAt: DateTime.utc(2026, 9, 1),
          );
          when(() => dao.claimNextJob()).thenAnswer((_) async => job);

          final response = await request(
            environment: {
              'INTERNAL_API_KEY': 'test-internal-key',
              'GITHUB_API_BASE_URL': apiUrl,
            },
          );

          expect(response.statusCode, HttpStatus.ok);
          final body = await response.json() as Map<String, dynamic>;
          expect(
            (body['job'] as Map<String, dynamic>)['githubBaseUrl'],
            repositoryUrl,
          );
          verify(() => dao.claimNextJob()).called(1);
        });
      }
    }

    for (final apiUrl in [
      null,
      'https://user:password@github.example.com/api/v3',
    ]) {
      test(
        'does not claim a job with missing or invalid API URL: $apiUrl',
        () async {
          final response = await request(
            environment: {
              'INTERNAL_API_KEY': 'test-internal-key',
              'GITHUB_API_BASE_URL': ?apiUrl,
            },
          );

          expect(response.statusCode, HttpStatus.internalServerError);
          verifyZeroInteractions(db);
          verifyZeroInteractions(dao);
        },
      );
    }
  });
}
