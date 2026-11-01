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

List<PullRequest> connect(List<PullRequest> pulls, List<PullRequest> previous) {
  final old = {for (final pr in previous) pr.number: pr};
  final map = {
    for (final pr in pulls)
      pr.number: (pr.copy()
        ..parent = null
        ..boundary = null),
  };
  for (final pr in map.values) {
    final prior = old[pr.number];
    if (!pr.isOpen) {
      pr.parent = prior?.parent;
      pr.boundary = prior?.boundary;
      continue;
    }
    if (!pr.sameRepo) continue;
    final parents = pulls
        .where((p) => p.isOpen && p.sameRepo && p.headRef == pr.baseRef && p.number != pr.number)
        .toList();
    if (parents.length > 1) {
      throw RestackException('同じブランチに複数の親PRがあります。親PRを一意にしてください。', number: pr.number);
    }
    PullRequest? parent = parents.firstOrNull;
    // GHES may retarget a child when merging its parent. Keep the recorded edge.
    if (parent == null && prior?.parent != null) {
      final savedParent = map[prior!.parent];
      if (savedParent != null) {
        final acceptable = {savedParent.headRef};
        final visited = <int>{};
        PullRequest? cursor = savedParent;
        while (cursor != null && cursor.merged && visited.add(cursor.number)) {
          acceptable.add(cursor.baseRef);
          cursor = map[old[cursor.number]?.parent];
        }
        if (acceptable.contains(pr.baseRef)) parent = savedParent;
      }
    }
    if (parent != null) {
      pr.parent = parent.number;
      pr.boundary = prior?.parent == parent.number ? prior?.boundary : null;
    }
  }
  final values = map.values.toList();
  ordered(values);
  final parents = <int>{};
  for (final pr in values.where((p) => p.isOpen && p.parent != null)) {
    if (!parents.add(pr.parent!)) {
      throw RestackException('分岐したstackを検出しました。親1つにつき子1つに対応しています。', number: pr.number);
    }
  }
  return values;
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
    if (parent == null) throw RestackException('保存した親PRを取得できません。', number: pr.number);
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
