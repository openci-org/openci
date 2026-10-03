import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  group('CITrigger', () {
    test('CITrigger.push creates push trigger with branch', () {
      const trigger = CITrigger.push(branch: 'develop');
      expect(trigger.branch, 'develop');
      expect(trigger, isA<CITrigger>());
    });

    test('CITrigger.pullRequest creates pullRequest trigger with branch', () {
      const trigger = CITrigger.pullRequest(branch: 'main');
      expect(trigger.branch, 'main');
      expect(trigger, isA<CITrigger>());
    });
  });
}
