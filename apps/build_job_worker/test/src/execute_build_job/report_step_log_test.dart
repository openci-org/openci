import 'dart:convert';

import 'package:build_job_worker/src/execute_build_job/report_step_log.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  const log = StepLog(message: ' {"stepOrder":1}\n\n日本語のログ\r\n');
  late ReportStepLog reporter;
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
    reporter = ReportStepLog(
      lokiClient: client,
      lokiUrl: 'http://loki:3100',
      jobId: 'job-1',
      runId: 'run-1',
      onError: (error, stackTrace) => errors.add((error, stackTrace)),
    );
  });

  group('ReportStepLog', () {
    test('sends the original log text with step_log labels', () async {
      await reporter.send(stepId: 'step-1', log: log);

      final request = requests.single;
      expect(request.url.toString(), 'http://loki:3100/loki/api/v1/push');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final stream =
          (body['streams'] as List<dynamic>).single as Map<String, dynamic>;
      expect(stream['stream'], {
        'stream': 'stdout',
        'type': 'step_log',
        'run_id': 'run-1',
        'build_job_id': 'job-1',
        'step_id': 'step-1',
      });
      final value = (stream['values'] as List<dynamic>).single as List<dynamic>;
      expect(value[1], log.message);
      expect(errors, isEmpty);
    });

    test('notifies onError when Loki rejects the log', () async {
      respond = (_) async => http.Response('', 503);

      await reporter.send(stepId: 'step-1', log: log);

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
      final stackTrace = StackTrace.fromString('Log delivery failed here');
      respond = (_) => Future.error(error, stackTrace);

      await reporter.send(stepId: 'step-1', log: log);

      expect(requests, hasLength(1));
      expect(errors.single.$1, same(error));
      expect(errors.single.$2.toString(), stackTrace.toString());
    });
  });
}
