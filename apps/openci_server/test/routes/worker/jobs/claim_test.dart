import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
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
    },
    String body = '{}',
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
    context.provide<InternalApiKeyValidator>(
      InternalApiKeyValidator.forTesting(environment: environment),
    );
    return Future.value(worker.middleware(route.onRequest)(context.context));
  }

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
  });
}
