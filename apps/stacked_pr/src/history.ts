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
  async discover(
    current: PullRequest[],
    selection: { number?: number; branch?: string; previousBase?: string } = {},
  ): Promise<PullRequest[]> {
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
    // Root histories are batched to find children that GitHub already retargeted
    // after a merge. Detailed closed-parent lookups are limited to connected PRs.
    const timelines = await this.api.timelines(
      this.installation,
      this.repo,
      roots.map((p) => p.number),
    );
    for (const [number, events] of timelines) this.timelines.set(number, events);
    const references = (pr: PullRequest): string[] => {
      const refs = new Set([pr.headRef, pr.baseRef]);
      let base = pr.baseRef;
      const changes = (this.timelines.get(pr.number) ?? []).filter(
        (event) =>
          event.__typename === "BaseRefChangedEvent" ||
          event.__typename === "AutomaticBaseChangeSucceededEvent",
      );
      for (const change of changes.reverse()) {
        const automatic = change.__typename === "AutomaticBaseChangeSucceededEvent";
        if ((automatic ? change.newBase : change.currentRefName) !== base) break;
        base = (automatic ? change.oldBase : change.previousRefName) as string;
        refs.add(base);
      }
      refs.delete(this.repo.defaultBranch!);
      return [...refs];
    };
    const byRef = new Map<string, PullRequest[]>();
    for (const pr of current.filter((pr) => pr.sameRepo))
      for (const ref of references(pr)) byRef.set(ref, [...(byRef.get(ref) ?? []), pr]);
    const pulls = new Map<number, PullRequest>();
    const pending: PullRequest[] = [];
    const include = (pr: PullRequest) => {
      if (pulls.has(pr.number)) return;
      const copy = new PullRequest({ ...pr, parent: undefined, boundary: undefined });
      pulls.set(pr.number, copy);
      pending.push(copy);
    };
    let expanded = 0;
    const includeConnected = () => {
      while (expanded < pending.length) {
        const pr = pending[expanded++];
        if (!pr.sameRepo) continue;
        for (const ref of references(pr))
          for (const related of byRef.get(ref) ?? []) include(related);
      }
    };
    const scoped =
      selection.number !== undefined ||
      selection.branch !== undefined ||
      selection.previousBase !== undefined;
    for (const pr of current) if (!scoped || pr.number === selection.number) include(pr);
    for (const ref of [selection.branch, selection.previousBase])
      if (ref !== undefined && ref !== this.repo.defaultBranch)
        for (const pr of byRef.get(ref) ?? []) include(pr);
    includeConnected();
    const selected = new Set(pending.map((pr) => pr.number));
    const branches = [
      ...new Set(roots.filter((pr) => selected.has(pr.number)).map((pr) => pr.baseRef)),
    ].filter((branch) => branch !== this.repo.defaultBranch);
    for (let start = 0; start < branches.length; start += 4)
      await Promise.all(branches.slice(start, start + 4).map((branch) => this.closed(branch)));
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
          include(parent);
          includeConnected();
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
