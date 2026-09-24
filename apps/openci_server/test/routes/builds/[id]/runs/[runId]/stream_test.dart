import 'dart:convert';

import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../../../routes/builds/[id]/runs/[runId]/stream.dart' as route;

void main() {
  group('buildRunLogPayload', () {
    for (final type in ['step_log', null]) {
      test('preserves JSON logs containing stepOrder with type=$type', () {
        const message = ' {"stepOrder":1,"message":"確認中"}';

        final payload = route.buildRunLogPayload(
          runId: 'run-1',
          labels: {'type': ?type, 'step_id': 'step-1'},
          message: message,
        );

        expect(payload['isStepEvent'], isFalse);
        expect(payload['message'], message);
        expect(payload, isNot(contains('step')));
        expect(payload['runId'], 'run-1');
        expect(payload['stepId'], 'step-1');

        final log = StepLog.fromJson(
          jsonDecode(jsonEncode(payload)) as Map<String, Object?>,
        );
        expect(log.message, message);
      });
    }

    test('returns step_event as a nested StepEvent payload', () {
      const stepJson = {
        'id': 'step-1',
        'runId': 'run-1',
        'name': 'Run tests',
        'status': 'SUCCESS',
        'durationMs': 1200,
        'stepOrder': 1,
        'createdAt': '2026-09-14T00:00:00.000Z',
        'updatedAt': '2026-09-14T00:00:01.200Z',
      };

      final payload = route.buildRunLogPayload(
        runId: 'run-1',
        labels: {'type': 'step_event'},
        message: jsonEncode(stepJson),
      );

      expect(payload['isStepEvent'], isTrue);
      expect(payload['step'], stepJson);
      expect(payload, isNot(contains('message')));
      expect(payload['runId'], 'run-1');
      expect(payload['stepId'], isNull);

      final event = StepEvent.fromJson(
        jsonDecode(jsonEncode(payload)) as Map<String, Object?>,
      );
      expect(event.step.status, BuildJobStatus.SUCCESS);
      expect(event.step.durationMs, 1200);
    });

    test('rejects step_event containing invalid JSON', () {
      expect(
        () => route.buildRunLogPayload(
          runId: 'run-1',
          labels: {'type': 'step_event'},
          message: 'not JSON',
        ),
        throwsFormatException,
      );
    });

    test('rejects step_event missing required BuildStep fields', () {
      expect(
        () => route.buildRunLogPayload(
          runId: 'run-1',
          labels: {'type': 'step_event'},
          message: '{"id":"step-1","status":"SUCCESS"}',
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
