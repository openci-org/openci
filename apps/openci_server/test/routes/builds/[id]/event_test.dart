import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../routes/builds/[id]/event.dart' as route;

void main() {
  group('GET /builds/[id]/event', () {
    test(
      'responds with 405 Method Not Allowed when method is not GET',
      () async {
        final context = TestRequestContext(
          path: '/builds/123/event',
          method: HttpMethod.post,
        );

        final response = await route.onRequest(context.context, '123');

        expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      },
    );

    test('returns push event payload when pullRequestNumber is null', () async {
      final context = TestRequestContext(
        path: '/builds/123/event',
        method: HttpMethod.get,
      );

      final now = DateTime.now();
      final driftJob = DriftBuildJob(
        id: '123',
        owner: 'test_owner',
        repo: 'test_repo',
        commitSha: 'commit_123',
        branch: 'main',
        status: BuildJobStatus.QUEUED,
        workflowName: 'workflow',
        workflowFileName: 'ci.yml',
        createdAt: now,
        updatedAt: now,
      );

      context.provide<DriftBuildJob>(driftJob);

      final response = await route.onRequest(context.context, '123');

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);

      final payload =
          jsonDecode(body['eventPayload'] as String) as Map<String, dynamic>;
      expect(payload['ref'], equals('refs/heads/main'));
      expect(payload['after'], equals('commit_123'));
      expect(payload['head_commit']['id'], equals('commit_123'));
      expect(payload['repository']['name'], equals('test_repo'));
      expect(
        payload['repository']['full_name'],
        equals('test_owner/test_repo'),
      );
    });

    test(
      'returns pull_request event payload when pullRequestNumber is set',
      () async {
        final context = TestRequestContext(
          path: '/builds/123/event',
          method: HttpMethod.get,
        );

        final now = DateTime.now();
        final driftJob = DriftBuildJob(
          id: '123',
          owner: 'test_owner',
          repo: 'test_repo',
          commitSha: 'commit_123',
          branch: 'main',
          status: BuildJobStatus.QUEUED,
          workflowName: 'workflow',
          workflowFileName: 'ci.yml',
          createdAt: now,
          updatedAt: now,
          pullRequestNumber: 42,
        );

        context.provide<DriftBuildJob>(driftJob);

        final response = await route.onRequest(context.context, '123');

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final payload =
            jsonDecode(body['eventPayload'] as String) as Map<String, dynamic>;
        expect(payload['action'], equals('opened'));
        expect(payload['number'], equals(42));
        expect(payload['pull_request']['number'], equals(42));
        expect(payload['pull_request']['head']['ref'], equals('main'));
        expect(payload['pull_request']['head']['sha'], equals('commit_123'));
        expect(payload['repository']['name'], equals('test_repo'));
      },
    );
  });
}
