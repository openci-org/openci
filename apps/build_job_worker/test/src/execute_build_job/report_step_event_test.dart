import 'dart:convert';

import 'package:build_job_worker/src/execute_build_job/report_step_event.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  final event = StepEvent(
    step: BuildStep(
      id: 'step-1',
      runId: 'run-1',
      name: 'ビルド',
      status: BuildJobStatus.SUCCESS,
      durationMs: 1200,
      stepOrder: 2,
      createdAt: DateTime.utc(2026, 9, 14),
      updatedAt: DateTime.utc(2026, 9, 14, 0, 0, 1, 200),
    ),
  );
  late ReportStepEvent reporter;
  late List<http.Request> requests;
  late List<(Object, StackTrace)> errors;
  late Future<http.Response> Function(http.Request) respond;

  setUp(() {
    requests = [];
    errors = [];
    respond = (_) async => http.Response('', 204);
    final client = MockClient((request) {
      requests.add(request);
      return respond(request);
    });
    addTearDown(client.close);
    reporter = ReportStepEvent(
      lokiClient: client,
      lokiUrl: 'http://loki:3100',
      jobId: 'job-1',
      runId: 'run-1',
      onError: (error, stackTrace) => errors.add((error, stackTrace)),
    );
  });

  group('ReportStepEvent', () {
    test('sends BuildStep JSON with step_event labels', () async {
      await reporter.send(event);

      final request = requests.single;
      expect(request.url.toString(), 'http://loki:3100/loki/api/v1/push');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final stream =
          (body['streams'] as List<dynamic>).single as Map<String, dynamic>;
      expect(stream['stream'], {
        'stream': 'stdout',
        'type': 'step_event',
        'run_id': 'run-1',
        'build_job_id': 'job-1',
        'step_id': 'step-1',
      });
      final value = (stream['values'] as List<dynamic>).single as List<dynamic>;
      expect(
        BuildStep.fromJson(
          jsonDecode(value[1] as String) as Map<String, dynamic>,
        ),
        event.step,
      );
      expect(errors, isEmpty);
    });

    test('notifies onError when Loki rejects the event', () async {
      respond = (_) async => http.Response('', 503);

      await reporter.send(event);

      expect(requests, hasLength(1));
      expect(
        errors.single.$1,
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('HTTP 503'),
        ),
      );
    });

    test('preserves a transport error and its stack in onError', () async {
      final error = http.ClientException('Connection failed');
      final stackTrace = StackTrace.fromString('Event delivery failed here');
      respond = (_) => Future.error(error, stackTrace);

      await reporter.send(event);

      expect(requests, hasLength(1));
      expect(errors.single.$1, same(error));
      expect(errors.single.$2.toString(), stackTrace.toString());
    });
  });
}
