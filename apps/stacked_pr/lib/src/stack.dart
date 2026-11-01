import 'git.dart';
import 'models.dart';

List<PullRequest> ordered(List<PullRequest> pulls) {
  final map = {for (final pr in pulls) pr.number: pr};
  final done = <int>{}, active = <int>{};
  final result = <PullRequest>[];
  void visit(PullRequest pr) {
    if (done.contains(pr.number)) return;
    if (!active.add(pr.number)) {
      throw RestackException('PRの依存関係が循環しています。baseブランチを修正してください。', number: pr.number);
    }
    final parent = map[pr.parent];
    if (parent != null) visit(parent);
    active.remove(pr.number);
    done.add(pr.number);
    result.add(pr);
  }

  pulls.forEach(visit);
  return result;
}

List<PullRequest> stackFor(List<PullRequest> pulls, int number) {
  final connected = {number};
  var changed = true;
  while (changed) {
    changed = false;
    for (final pr in pulls) {
      final parent = pr.parent;
      if (parent != null && (connected.contains(pr.number) || connected.contains(parent))) {
        if (connected.add(pr.number)) changed = true;
        if (connected.add(parent)) changed = true;
      }
    }
  }
  return ordered(pulls.where((p) => connected.contains(p.number)).toList());
}

Future<({List<PullRequest> pulls, List<BranchChange> changes})> planRestack(
  List<PullRequest> pulls,
  GitRepository git, {
  bool enabled = true,
}) async {
  final original = {for (final pr in pulls) pr.number: pr};
  final next = pulls.map((pr) => pr.copy()).toList();
  final map = {for (final pr in next) pr.number: pr};
  final changes = <BranchChange>[];
  for (final pr in ordered(next)) {
    if (!pr.isOpen || !pr.sameRepo || pr.parent == null) continue;
    var parent = map[pr.parent];
    if (parent == null) throw RestackException('依存先の親PRを取得できません。', number: pr.number);
    if (!parent.isOpen && !parent.merged) {
      throw RestackException(
        '親PR #${parent.number} はmergeされずに閉じられています。baseを修正してください。',
        number: pr.number,
      );
    }
    if (pr.boundary == null) {
      final head = original[parent.number]!.head;
      await git.ensure(head);
      if (!await git.ancestor(head, pr.head)) {
        throw RestackException(
          '初回の変更境界を確認できません。手元でrestackしてから /stack sync を実行してください。',
          number: pr.number,
        );
      }
      pr.boundary = head;
    }
    await git.pin(pr.boundary!);
    var targetRef = parent.headRef, target = parent.head;
    int? survivingParent = parent.number;
    final mergedParents = <PullRequest>[];
    while (parent!.merged) {
      mergedParents.add(parent);
      targetRef = parent.baseRef;
      survivingParent = parent.parent;
      parent = map[parent.parent];
      if (parent == null) {
        target = await git.branch(targetRef);
        break;
      }
      if (!parent.isOpen && !parent.merged) {
        throw RestackException('祖先PR #${parent.number} はmergeされずに閉じられています。', number: pr.number);
      }
      if (!parent.merged) {
        targetRef = parent.headRef;
        target = parent.head;
      }
    }
    if (!enabled) continue;
    if (!await git.ancestor(pr.boundary!, pr.head) && !await git.ancestor(target, pr.head)) {
      if (mergedParents.isEmpty) {
        // A manual restack may already include the parent's head from before this plan.
        final previousParentHead = original[pr.parent]!.head;
        if (await git.ancestor(previousParentHead, pr.head)) pr.boundary = previousParentHead;
      } else if (mergedParents.every((parent) => parent.mergeCommit != null)) {
        pr.boundary =
            await git.findMergedBoundary(
              head: pr.head,
              target: target,
              mergeCommits: mergedParents.map((parent) => parent.mergeCommit!).toList(),
            ) ??
            pr.boundary;
      }
    }
    final newHead = await git.rebase(
      number: pr.number,
      head: pr.head,
      boundary: pr.boundary!,
      target: target,
    );
    changes.add(
      BranchChange(
        number: pr.number,
        headRef: pr.headRef,
        oldHead: pr.head,
        newHead: newHead,
        oldBase: pr.baseRef,
        newBase: targetRef,
      ),
    );
    pr.head = newHead;
    pr.base = target;
    pr.baseRef = targetRef;
    pr.boundary = target;
    pr.parent = survivingParent;
    await git.pin(target);
  }
  return (pulls: next, changes: changes);
}
