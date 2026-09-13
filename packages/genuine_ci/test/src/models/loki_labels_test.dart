import 'package:genuine_ci/src/loki/loki_labels.dart';
import 'package:test/test.dart';

void main() {
  group('LokiLabels', () {
    test('creates labels with default type', () {
      const labels = LokiLabels(
        stream: 'stdout',
        command: 'flutter build',
        runId: '123',
      );

      expect(labels.stream, 'stdout');
      expect(labels.type, 'step_log');
      expect(labels.command, 'flutter build');
      expect(labels.runId, '123');

      final map = labels.toLabelsMap();
      expect(map, {
        'stream': 'stdout',
        'type': 'step_log',
        'command': 'flutter build',
        'run_id': '123',
      });
    });

    test('toLabelsMap excludes null fields', () {
      const labels = LokiLabels(
        stream: 'stderr',
      );

      final map = labels.toLabelsMap();
      expect(map, {
        'stream': 'stderr',
        'type': 'step_log',
      });
      expect(map.containsKey('command'), isFalse);
      expect(map.containsKey('run_id'), isFalse);
    });
  });
}
