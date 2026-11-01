import 'package:test/test.dart';
import 'package:stacked_pr_app/src/git.dart';
import 'package:stacked_pr_app/src/models.dart';
import 'package:stacked_pr_app/src/stack.dart';
import '../test/support/fixtures.dart';
import 'support/git_fixture.dart';

void main() {
  test('squash merge preserves only child changes and cascades to grandchild', () async {
    final f = await GitFixture.create();
    final squash = await f.squash(deleteParent: true);
    f.pulls[1].baseRef = 'main';
    final linked = connect(f.pulls, f.pulls);
    expect(linked[1].parent, 1);
    final plan = await planRestack(linked, f.worker);
    expect(plan.pulls[1].baseRef, 'main');
    expect(plan.pulls[1].parent, isNull);
    expect(plan.pulls[1].boundary, squash);
    expect(await f.output(['rev-list', '--count', '$squash..${plan.pulls[1].head}']), '1');
    expect(await f.output(['diff', '--name-only', squash, plan.pulls[1].head]), 'child.txt');
    expect(
      await f.output(['diff', '--name-only', plan.pulls[1].head, plan.pulls[2].head]),
      'grandchild.txt',
    );
    await f.worker.push(plan.changes);
    expect((await f.worker.remoteHeads(['child']))['child'], plan.pulls[1].head);
  });
  test('amended parent uses recorded boundary rather than merge-base', () async {
    final f = await GitFixture.create();
    await f.git(['checkout', 'parent']);
    await f.commit('parent.txt', 'parent revised\n', 'fix');
    await f.git(['reset', '--soft', f.main]);
    await f.git(['commit', '-m', 'rewritten parent']);
    f.pulls[0].head = await f.git(['rev-parse', 'HEAD']);
    await f.git(['push', '--force', 'origin', 'parent']);
    await f.worker.prepare();
    final plan = await planRestack(f.pulls, f.worker);
    expect(await f.output(['show', '${plan.pulls[2].head}:parent.txt']), 'parent revised');
    expect(
      await f.output(['rev-list', '--count', '${f.pulls[0].head}..${plan.pulls[1].head}']),
      '1',
    );
  });
  test('conflict in last layer pushes no earlier successful layer', () async {
    final f = await GitFixture.create();
    await f.git(['checkout', 'grandchild']);
    f.pulls[2].head = await f.commit('parent.txt', 'grandchild conflicting edit\n', 'conflict');
    await f.git(['push', 'origin', 'grandchild']);
    await f.git(['checkout', 'parent']);
    f.pulls[0].head = await f.commit('parent.txt', 'parent conflicting edit\n', 'fix');
    await f.git(['push', 'origin', 'parent']);
    await f.worker.prepare();
    await expectLater(
      planRestack(f.pulls, f.worker),
      throwsA(
        isA<RestackException>().having((e) => e.number, 'PR', 3).having((e) => e.files, 'files', [
          'parent.txt',
        ]),
      ),
    );
    final heads = await f.worker.remoteHeads(['child', 'grandchild']);
    expect(heads['child'], f.child);
    expect(heads['grandchild'], f.pulls[2].head);
  });
  test('atomic lease rejects all refs when one branch has a concurrent push', () async {
    final f = await GitFixture.create();
    await f.advanceParent();
    final plan = await planRestack(f.pulls, f.worker);
    await f.git(['checkout', 'grandchild']);
    final human = await f.commit('human.txt', 'human\n', 'concurrent human');
    await f.git(['push', 'origin', 'grandchild']);
    await expectLater(f.worker.push(plan.changes), throwsA(isA<GitException>()));
    final heads = await f.worker.remoteHeads(['child', 'grandchild']);
    expect(heads['child'], f.child);
    expect(heads['grandchild'], human);
  });
  test('already synchronized or manually restacked children are unchanged', () async {
    final f = await GitFixture.create();
    f.pulls[1].boundary = f.main;
    final plan = await planRestack(f.pulls, f.worker);
    expect(plan.pulls[1].head, f.child);
    expect(plan.pulls[2].head, f.grandchild);
    expect(plan.pulls[1].boundary, f.parent);
  });
  test('two merged ancestors retarget to surviving trunk', () async {
    final f = await GitFixture.create();
    await f.git(['checkout', 'main']);
    await f.git(['merge', '--squash', 'child']);
    await f.git(['commit', '-m', 'land both']);
    final main = await f.git(['rev-parse', 'HEAD']);
    await f.git(['push', 'origin', 'main']);
    await f.worker.prepare();
    for (var i = 0; i < 2; i++) {
      f.pulls[i] = modify(f.pulls[i], {'state': 'closed', 'merged': true});
    }
    final plan = await planRestack(f.pulls, f.worker);
    expect(plan.pulls[2].baseRef, 'main');
    expect(await f.output(['diff', '--name-only', main, plan.pulls[2].head]), 'grandchild.txt');
  });
  test('fetch removes deleted target refs while keeping pinned boundary', () async {
    final f = await GitFixture.create();
    await f.worker.pin(f.parent);
    await f.git(['push', 'origin', ':parent']);
    await f.worker.prepare();
    await expectLater(f.worker.branch('parent'), throwsA(isA<GitException>()));
    expect(await f.worker.has(f.parent), isTrue);
  });
  test('missing boundary after child rewrite stops without overwriting', () async {
    final f = await GitFixture.create();
    final target = await f.advanceParent();
    await expectLater(
      f.worker.rebase(number: 2, head: f.child, boundary: target, target: target),
      throwsA(isA<RestackException>().having((e) => e.message, 'reason', contains('変更境界'))),
    );
  });

  test('merged boundary recovery rejects multiple merge bases', () async {
    final f = await GitFixture.create();
    final squash = await f.squash();
    await f.git(['checkout', '-b', 'left', squash]);
    final left = await f.commit('left.txt', 'left\n', 'left side');
    await f.git(['checkout', '-b', 'right', squash]);
    final right = await f.commit('right.txt', 'right\n', 'right side');
    await f.git(['merge', '--no-ff', 'left', '-m', 'join from right']);
    final target = await f.git(['rev-parse', 'HEAD']);
    final tree = await f.git(['rev-parse', 'HEAD^{tree}']);
    final head = await f.git([
      'commit-tree',
      tree,
      '-p',
      left,
      '-p',
      right,
      '-m',
      'join from left',
    ]);
    await f.git(['branch', 'other-join', head]);
    await f.git(['push', 'origin', 'right', 'other-join']);
    await f.worker.prepare();

    expect(
      await f.worker.findMergedBoundary(head: head, target: target, mergeCommits: [squash]),
      isNull,
    );
  });
}
