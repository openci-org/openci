import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  group('CITrigger', () {
    test('CITrigger.push creates push trigger with branch', () {
      const trigger = CITrigger.push(branch: 'develop');
      expect(trigger.branch, 'develop');
      expect(trigger.whenChanged, isNull);
      expect(trigger, isA<CITrigger>());
    });

    test('CITrigger.pullRequest creates pullRequest trigger with branch', () {
      const trigger = CITrigger.pullRequest(branch: 'main');
      expect(trigger.branch, 'main');
      expect(trigger.whenChanged, isNull);
      expect(trigger, isA<CITrigger>());
    });

    test('changed-file conditions support const triggers', () {
      const push = CITrigger.push(branch: 'main', whenChanged: ['apps/**']);
      const pullRequest = CITrigger.pullRequest(
        branch: 'main',
        whenChanged: ['packages/**'],
      );

      expect(push.whenChanged, ['apps/**']);
      expect(pullRequest.whenChanged, ['packages/**']);
    });
  });
}
