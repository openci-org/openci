import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

Future<Response<BodyType>> _convert<BodyType, Item>(Object? json) async {
  final encoded = jsonEncode(json);
  return const JsonToTypeConverter().convertResponse<BodyType, Item>(
    Response<String>(
      http.Response(
        encoded,
        200,
        headers: {
          'content-type': 'application/json',
          'x-request-id': 'request-1',
        },
      ),
      encoded,
    ),
  );
}

void main() {
  final now = DateTime.utc(2026, 9, 7);
  final job = BuildJob(
    id: 'job-1',
    status: BuildJobStatus.QUEUED,
    owner: 'owner',
    repo: 'repo',
    workflowName: 'CI',
    workflowFileName: 'ci.dart',
    createdAt: now,
    updatedAt: now,
  );
  final group = CicdCommitGroup(
    branch: 'main',
    commitSha: 'sha-1',
    commitMessage: 'Build',
    status: BuildJobStatus.SUCCESS,
    createdAt: now,
    workflows: [
      CicdWorkflowGroup(
        fileName: 'ci.dart',
        status: BuildJobStatus.SUCCESS,
        duration: const Duration(microseconds: 1234),
        stages: [
          [
            const CicdJobGroup(
              id: 'job-1',
              label: 'Test',
              status: BuildJobStatus.SUCCESS,
            ),
          ],
        ],
      ),
    ],
  );
  final step = BuildStep(
    id: 'step-1',
    runId: 'run-1',
    name: 'Test',
    status: BuildJobStatus.SUCCESS,
    durationMs: 1501,
    stepOrder: 0,
    createdAt: now,
    updatedAt: now,
  );

  test('converts a build job and preserves response metadata', () async {
    final response = await _convert<BuildJob, BuildJob>(job.toJson());
    expect(response.body, job);
    expect(response.statusCode, 200);
    expect(response.headers['x-request-id'], 'request-1');
  });

  test(
    'converts commit groups including nested stages and durations',
    () async {
      final response = await _convert<List<CicdCommitGroup>, CicdCommitGroup>([
        group.toJson(),
      ]);
      expect(response.body, [group]);
    },
  );

  test('converts build steps and preserves their order', () async {
    final next = step.copyWith(id: 'step-2', stepOrder: 1);
    final response = await _convert<List<BuildStep>, BuildStep>([
      step.toJson(),
      next.toJson(),
    ]);
    expect(response.body, [step, next]);
  });

  test('preserves JSON objects without a registered model type', () async {
    const data = {'success': true, 'jobs_created': 2};
    final response = await _convert<Map<String, dynamic>, Map<String, dynamic>>(
      data,
    );
    expect(response.body, data);
  });

  test('preserves a null response body', () async {
    final response = await _convert<BuildJob, BuildJob>(null);
    expect(response.body, isNull);
    expect(response.statusCode, 200);
    expect(response.headers['x-request-id'], 'request-1');
  });

  test('preserves the JSON string "null" as a string', () async {
    final response = await _convert<String, String>('null');
    expect(response.body, 'null');
  });

  test('returns a typed empty list', () async {
    final response = await _convert<List<BuildStep>, BuildStep>([]);
    expect(response.body, isA<List<BuildStep>>());
    expect(response.body, isEmpty);
  });

  test(
    'rejects an invalid list item instead of returning partial results',
    () async {
      await expectLater(
        _convert<List<BuildStep>, BuildStep>([
          step.toJson(),
          {'id': 'incomplete'},
        ]),
        throwsA(isA<TypeError>()),
      );
    },
  );

  test('rejects a scalar where a model is required', () async {
    await expectLater(
      _convert<BuildJob, BuildJob>('invalid'),
      throwsA(isA<TypeError>()),
    );
  });
}
