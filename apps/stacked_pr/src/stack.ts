import type { GitRepository } from "./git.js";
import { BranchChange, PullRequest, RestackException } from "./models.js";

export function ordered(pulls: PullRequest[]): PullRequest[] {
  const map = new Map(pulls.map((pr) => [pr.number, pr]));
  const done = new Set<number>(),
    active = new Set<number>(),
    result: PullRequest[] = [];
  function visit(pr: PullRequest): void {
    if (done.has(pr.number)) return;
    if (active.has(pr.number))
      throw new RestackException(
        "PRの依存関係が循環しています。baseブランチを修正してください。",
        pr.number,
      );
    active.add(pr.number);
    const parent = pr.parent === undefined ? undefined : map.get(pr.parent);
    if (parent) visit(parent);
    active.delete(pr.number);
    done.add(pr.number);
    result.push(pr);
  }
  pulls.forEach(visit);
  return result;
}
export function stackFor(pulls: PullRequest[], number: number): PullRequest[] {
  const connected = new Set([number]);
  let changed = true;
  while (changed) {
    changed = false;
    for (const pr of pulls)
      if (pr.parent !== undefined && (connected.has(pr.number) || connected.has(pr.parent))) {
        if (!connected.has(pr.number)) {
          connected.add(pr.number);
          changed = true;
        }
        if (!connected.has(pr.parent)) {
          connected.add(pr.parent);
          changed = true;
        }
      }
  }
  return ordered(pulls.filter((p) => connected.has(p.number)));
}
export async function planRestack(
  pulls: PullRequest[],
  git: GitRepository,
): Promise<{ pulls: PullRequest[]; changes: BranchChange[] }> {
  const original = new Map(pulls.map((pr) => [pr.number, pr]));
  const next = pulls.map((pr) => pr.copy()),
    map = new Map(next.map((pr) => [pr.number, pr]));
  const changes: BranchChange[] = [];
  for (const pr of ordered(next)) {
    if (!pr.isOpen || !pr.sameRepo || pr.parent === undefined) continue;
    let parent = map.get(pr.parent);
    if (!parent) throw new RestackException("依存先の親PRを取得できません。", pr.number);
    if (!parent.isOpen && !parent.merged)
      throw new RestackException(
        `親PR #${parent.number} はmergeされずに閉じられています。baseを修正してください。`,
        pr.number,
      );
    if (!pr.boundary) {
      const head = original.get(parent.number)!.head;
      await git.ensure(head);
      if (!(await git.ancestor(head, pr.head)))
        throw new RestackException(
          "初回の変更境界を確認できません。手元でrestackしてから /stack sync を実行してください。",
          pr.number,
        );
      pr.boundary = head;
    }
    await git.pin(pr.boundary);
    let targetRef = parent.headRef,
      target = parent.head;
    let survivingParent: number | undefined = parent.number;
    const mergedParents: PullRequest[] = [];
    while (parent?.merged) {
      mergedParents.push(parent);
      targetRef = parent.baseRef;
      survivingParent = parent.parent;
      parent = parent.parent === undefined ? undefined : map.get(parent.parent);
      if (!parent) {
        target = await git.branch(targetRef);
        break;
      }
      if (!parent.isOpen && !parent.merged)
        throw new RestackException(
          `祖先PR #${parent.number} はmergeされずに閉じられています。`,
          pr.number,
        );
      if (!parent.merged) {
        targetRef = parent.headRef;
        target = parent.head;
      }
    }
    if (!(await git.ancestor(pr.boundary, pr.head)) && !(await git.ancestor(target, pr.head))) {
      if (!mergedParents.length) {
        const previous = original.get(pr.parent)!.head;
        if (await git.ancestor(previous, pr.head)) pr.boundary = previous;
      } else if (mergedParents.every((p) => p.mergeCommit !== undefined)) {
        pr.boundary =
          (await git.findMergedBoundary({
            head: pr.head,
            target,
            mergeCommits: mergedParents.map((p) => p.mergeCommit!),
          })) ?? pr.boundary;
      }
    }
    const newHead = await git.rebase({
      number: pr.number,
      head: pr.head,
      boundary: pr.boundary,
      target,
    });
    changes.push(new BranchChange(pr.number, pr.headRef, pr.head, newHead, pr.baseRef, targetRef));
    pr.head = newHead;
    pr.base = target;
    pr.baseRef = targetRef;
    pr.boundary = target;
    pr.parent = survivingParent;
    await git.pin(target);
  }
  return { pulls: next, changes };
}
