import { assertSha, type GitRepository } from "./git.js";
import { ApiException, type GitHubApi } from "./github.js";
import { type Json, jsonObject, PullRequest, Repository, RestackException } from "./models.js";

/** Invocation-local view reconstructed from GitHub; no persistent PR state. */
export class History {
  private readonly timelines = new Map<number, Json[]>();
  private readonly closedPulls = new Map<string, PullRequest[]>();
  readonly errors = new Map<number, RestackException>();
  constructor(
    readonly api: GitHubApi,
    readonly installation: number,
    readonly repo: Repository,
  ) {}
  async timeline(number: number): Promise<Json[]> {
    if (!this.timelines.has(number))
      this.timelines.set(number, await this.api.timeline(this.installation, this.repo, number));
    return this.timelines.get(number)!;
  }
  async closed(branch: string): Promise<PullRequest[]> {
    if (!this.closedPulls.has(branch)) {
      const head = encodeURIComponent(`${this.repo.fullName.split("/")[0]}:${branch}`);
      this.closedPulls.set(
        branch,
        (
          await this.api.list(
            this.installation,
            `${this.repo.apiPath}/pulls?state=closed&head=${head}`,
          )
        )
          .map((p) => PullRequest.fromApi(p, this.repo.id))
          .filter((p) => p.sameRepo && p.headRef === branch),
      );
    }
    return this.closedPulls.get(branch)!;
  }
  async discover(current: PullRequest[]): Promise<PullRequest[]> {
    const roots = current.filter(
      (child) =>
        child.sameRepo &&
        !current.some(
          (parent) =>
            parent.isOpen &&
            parent.sameRepo &&
            parent.number !== child.number &&
            parent.headRef === child.baseRef,
        ),
    );
    for (const [number, events] of await this.api.timelines(
      this.installation,
      this.repo,
      roots.map((p) => p.number),
    ))
      this.timelines.set(number, events);
    const pulls = new Map(
      current.map((p) => [
        p.number,
        new PullRequest({ ...p, parent: undefined, boundary: undefined }),
      ]),
    );
    const pending = [...pulls.values()];
    for (let i = 0; i < pending.length; i++) {
      const child = pending[i];
      if (!child.sameRepo) continue;
      try {
        const branch = child.baseRef;
        let candidates = pending.filter(
          (p) => p.sameRepo && p.isOpen && p.headRef === branch && p.number !== child.number,
        );
        if (branch === this.repo.defaultBranch) candidates = [];
        if (!candidates.length && branch !== this.repo.defaultBranch)
          candidates = await this.closed(branch);
        if (!candidates.length) {
          const changes = (await this.timeline(child.number)).filter(
            (e) =>
              e.__typename === "BaseRefChangedEvent" ||
              e.__typename === "AutomaticBaseChangeSucceededEvent",
          );
          // Only follow a contiguous history ending at the current base (B -> A -> main).
          let base = branch;
          for (const change of changes.reverse()) {
            const automatic = change.__typename === "AutomaticBaseChangeSucceededEvent";
            if ((automatic ? change.newBase : change.currentRefName) !== base) break;
            const previous = (automatic ? change.oldBase : change.previousRefName) as string,
              at = Date.parse(change.createdAt as string);
            const merged = (await this.closed(previous)).filter(
              (p) =>
                p.merged &&
                [base, branch].includes(p.baseRef) &&
                p.mergedAt !== undefined &&
                p.mergedAt.getTime() <= at + 5000 &&
                (child.createdAt === undefined || p.mergedAt >= child.createdAt),
            );
            if (!merged.length) break;
            candidates = merged;
            if (merged.length > 1) break;
            base = previous;
          }
        }
        candidates = candidates.filter((p) => p.number !== child.number);
        if (candidates.length > 1)
          throw new RestackException(
            "親PRを一意に確認できません。baseブランチを確認してください。",
            child.number,
          );
        if (!candidates.length) continue; // A permanent release branch is not a stack.
        const parent = candidates[0];
        child.parent = parent.number;
        if (!pulls.has(parent.number)) {
          pulls.set(parent.number, parent);
          pending.push(parent);
        }
      } catch (error) {
        if (!(error instanceof RestackException)) throw error;
        this.errors.set(child.number, error);
      }
    }
    return [...pulls.values()];
  }
  async boundary(git: GitRepository, parent: PullRequest, child: PullRequest): Promise<string> {
    await git.ensure(parent.head);
    if (await git.ancestor(parent.head, child.head)) return parent.head;
    const tips = new Set([parent.head]);
    let incomplete = false;
    for (const event of await this.timeline(parent.number)) {
      if (event.__typename !== "HeadRefForcePushedEvent") continue;
      for (const field of ["beforeCommit", "afterCommit"]) {
        if (event[field] == null) incomplete = true;
        else tips.add(jsonObject(event[field]).oid as string);
      }
    }
    const candidates = new Set<string>();
    // A common ancestor in main is not evidence of the parent's change boundary.
    const upstream = await git.branch(parent.baseRef);
    for (const tip of tips) {
      if (!(await git.has(tip))) {
        try {
          await this.api.request(
            this.installation,
            "GET",
            `${this.repo.apiPath}/git/commits/${assertSha(tip)}`,
          );
        } catch (error) {
          if (!(error instanceof ApiException) || error.status !== 404) throw error;
          incomplete = true;
          continue;
        }
        await git.ensure(tip); // Transport failures must retry rather than masquerade as missing history.
      }
      const base = await git.mergeBase(tip, child.head);
      if (base !== undefined && !(await git.ancestor(base, upstream))) candidates.add(base);
    }
    if (!incomplete && candidates.size) {
      const latest: string[] = [];
      for (const candidate of candidates) {
        let superseded = false;
        for (const other of candidates)
          if (candidate !== other && (await git.ancestor(candidate, other))) superseded = true;
        if (!superseded) latest.push(candidate);
      }
      if (latest.length === 1) return latest[0];
    }
    throw new RestackException(
      "GitHubの履歴から親子の変更境界を確定できません。手元でrestackしてから /stack sync を実行してください。",
      child.number,
    );
  }
}
