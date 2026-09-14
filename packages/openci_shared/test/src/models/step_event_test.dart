import 'dart:convert';

import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('StepEvent', () {
    final stepJson = {
      'id': 'step-1',
      'runId': 'run-1',
      'name': 'Run tests',
      'status': 'SUCCESS',
      'durationMs': 1200,
      'stepOrder': 1,
      'createdAt': '2026-09-14T00:00:00.000Z',
      'updatedAt': '2026-09-14T00:00:01.200Z',
    };
    final step = BuildStep.fromJson(stepJson);

    test('reads a nested JSON object as a BuildStep', () {
      final event = StepEvent.fromJson({'step': stepJson});

      expect(event.step, step);
    });

    test('writes the step as a nested JSON object', () {
      final event = StepEvent(step: step);

      expect(event.toJson(), {'step': stepJson});
      expect(jsonDecode(jsonEncode(event)), {'step': stepJson});
    });
  });
}
