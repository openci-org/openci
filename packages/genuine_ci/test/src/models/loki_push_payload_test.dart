import 'package:genuine_ci/src/loki/loki_labels.dart';
import 'package:genuine_ci/src/loki/loki_push_payload.dart';
import 'package:test/test.dart';

void main() {
  group('LokiPushPayload', () {
    test('creates single log payload properly', () {
      const labels = LokiLabels(
        stream: 'stdout',
        command: 'echo test',
      );

      final payload = LokiPushPayload.single(
        labels: labels,
        timestampNanos: '1723600000000000000',
        message: 'Hello World',
      );

      expect(payload.streams.length, 1);
      final map = payload.toMap();
      expect(map, {
        'streams': [
          {
            'stream': {
              'stream': 'stdout',
              'type': 'step_log',
              'command': 'echo test',
            },
            'values': [
              ['1723600000000000000', 'Hello World'],
            ],
          },
        ],
      });
    });
  });
}
