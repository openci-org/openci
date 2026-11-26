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
      expect(filtered.pathsIgnore, isNull);
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

    test('const push and pull request triggers accept pathsIgnore', () {
      const push = CITrigger.push(branch: 'main', pathsIgnore: ['docs/**']);
      const pullRequest = CITrigger.pullRequest(
        branch: 'main',
        pathsIgnore: ['README.md'],
      );

      expect(push.pathsIgnore, ['docs/**']);
      expect(pullRequest.pathsIgnore, ['README.md']);
      expect(push.mapOrNull(push: (trigger) => trigger.pathsIgnore), [
        'docs/**',
      ]);
    });

    test('pattern callbacks keep their existing argument lists', () {
      const trigger = CITrigger.push(branch: 'main', paths: ['apps/**']);

      expect(
        CITriggerPatterns(trigger).when(
          push: (branch, paths) => paths?.single,
          pullRequest: (branch, paths) => paths?.single,
          release: (tag) => tag,
        ),
        'apps/**',
      );
      expect(trigger.whenOrNull(push: (branch, paths) => branch), 'main');
      expect(
        trigger.maybeWhen<String?>(
          push: (branch, paths) => null,
          orElse: () => 'fallback',
        ),
        isNull,
      );
      expect(trigger.maybeWhen(orElse: () => 'fallback'), 'fallback');
    });
  });
}
