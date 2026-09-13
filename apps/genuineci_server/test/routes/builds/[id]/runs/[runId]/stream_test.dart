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
        expect(payload['runId'], 'run-1');
        expect(payload['stepId'], 'step-1');
      });
    }

    test('recognizes step_event even when the message has no stepOrder', () {
      const message = '{"id":"step-1","status":"SUCCESS"}';

      final payload = route.buildRunLogPayload(
        runId: 'run-1',
        labels: {'type': 'step_event'},
        message: message,
      );

      expect(payload['isStepEvent'], isTrue);
      expect(payload['message'], message);
      expect(payload['stepId'], isNull);
    });
  });
}
