import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../routes/builds/[id]/script.dart' as route;

void main() {
  group('GET /builds/[id]/script', () {
    test(
      'responds with 405 Method Not Allowed when method is not GET',
      () async {
        final context = TestRequestContext(
          path: '/builds/123/script',
          method: HttpMethod.post,
        );

        final response = await route.onRequest(context.context, '123');

        expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      },
    );

    test(
      'returns push event script with matrix and jobKey when pullRequestNumber is null',
      () async {
        final context = TestRequestContext(
          path: '/builds/123/script',
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
          workflowFileName: 'build.yml',
          jobKey: 'build_job',
          matrix: {'node': 18, 'os': 'macos'},
          createdAt: now,
          updatedAt: now,
        );

        context.provide<DriftBuildJob>(driftJob);

        final response = await route.onRequest(context.context, '123');

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final script = body['script'] as String;
        expect(script, contains('cd test_repo'));
        expect(script, contains('act push -W .openci/build.yml'));
        expect(script, contains('-j build_job'));
        expect(script, contains('--matrix "node:18"'));
        expect(script, contains('--matrix "os:macos"'));
        expect(script, contains('--json'));
      },
    );

    test(
      'returns pull_request event script when pullRequestNumber is set',
      () async {
        final context = TestRequestContext(
          path: '/builds/123/script',
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
          workflowFileName: 'build.yml',
          pullRequestNumber: 42,
          createdAt: now,
          updatedAt: now,
        );

        context.provide<DriftBuildJob>(driftJob);

        final response = await route.onRequest(context.context, '123');

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final script = body['script'] as String;
        expect(script, contains('act pull_request -W .openci/build.yml'));
      },
    );
  });
}
