import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  group('CITrigger', () {
    test('release triggers have a separate tag filter and union identity', () {
      const all = CITrigger.release();
      const filtered = CITrigger.release(tag: 'v*');
      expect(all, const CITrigger.release(tag: '*'));
      expect(filtered, isNot(const CITrigger.push(branch: 'v*')));
      expect(filtered.branch, isNull);
      expect(filtered.paths, isNull);
    });
    test('CITrigger.push creates push trigger with branch', () {
      const trigger = CITrigger.push(branch: 'develop');
      expect(trigger.branch, 'develop');
      expect(trigger.paths, isNull);
      expect(trigger, isA<CITrigger>());
    });

    test('CITrigger.pullRequest creates pullRequest trigger with branch', () {
      const trigger = CITrigger.pullRequest(branch: 'main');
      expect(trigger.branch, 'main');
      expect(trigger.paths, isNull);
      expect(trigger, isA<CITrigger>());
    });

    test('changed-file conditions support const triggers', () {
      const push = CITrigger.push(branch: 'main', paths: ['apps/**']);
      const pullRequest = CITrigger.pullRequest(
        branch: 'main',
        paths: ['packages/**'],
      );

      expect(push.paths, ['apps/**']);
      expect(pullRequest.paths, ['packages/**']);
    });
  });
}
