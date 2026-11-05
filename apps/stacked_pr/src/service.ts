import { join } from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import type { AppConfig } from "./config.js";
import type { Deadline } from "./deadline.js";
import { isSelfUpdate } from "./events.js";
import { GitRepository } from "./git.js";
import type { GitHubApi } from "./github.js";
import { History } from "./history.js";
import type { StackLocks, StackLease } from "./locks.js";
import { StackMerge } from "./merge.js";
import type { MergeStops } from "./merge-stops.js";
import {
  type Job,
  type Json,
  jsonObject,
  object,
  PullRequest,
  Repository,
  RestackException,
  RetryException,
  StackBusyException,
} from "./models.js";
import type { Reporter } from "./report.js";
import { ordered, planRestack } from "./stack.js";

interface ServiceOptions {
  config: AppConfig;
  api: GitHubApi;
  reporter: Reporter;
  locks: StackLocks;
  mergeStops?: MergeStops;
  enqueue?: (job: Job, scheduleTime?: Date) => Promise<boolean>;
  now?: () => number;
  deadline?: Deadline;
  gitFactory?: (installation: number, repo: Repository) => GitRepository;
}
interface Selection {
  number?: number;
  branch?: string;
  previousBase?: string;
}

function lockResources(components: PullRequest[][]): string[] {
  return [
    ...new Set(
      components
        .flat()
        .filter((p) => p.sameRepo)
        .flatMap((p) => [`pr:${p.number}`, `head:${p.headRef}`]),
    ),
  ].sort();
}
export class Service {
  private readonly config: AppConfig;
  private readonly api: GitHubApi;
  private readonly gitFactory: (installation: number, repo: Repository) => GitRepository;
  constructor(private readonly options: ServiceOptions) {
    this.config = options.config;
    this.api = options.api;
    this.gitFactory =
      options.gitFactory ??
      ((installation, repo) =>
        new GitRepository({
          directory: join(this.config.dataDir, `${installation}-${repo.id}.git`),
          remote: `${this.config.githubUrl}/${repo.fullName}.git`,
          token: () => this.api.token(installation),
          deadline: options.deadline,
        }));
  }
  allowed(repo: Json): boolean {
    return (
      Number.isSafeInteger(repo.id) &&
      (repo.id as number) > 0 &&
      typeof repo.full_name === "string" &&
      /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repo.full_name) &&
      (!this.config.allowedRepos.size || this.config.allowedRepos.has(repo.full_name.toLowerCase()))
    );
  }
  private merger(): StackMerge {
    if (!this.options.enqueue || !this.options.mergeStops)
      throw new Error("Merge controls unavailable");
    return new StackMerge({
      api: this.api,
      locks: this.options.locks,
      stops: this.options.mergeStops,
      host: this.config.githubUrl,
      now: this.options.now,
      enqueue: this.options.enqueue,
      git: this.gitFactory,
      publish: (i, repo, pulls) => this.options.reporter.publish(i, repo, pulls),
      discover: async (i, repo, target) => {
        const snapshot = await this.discover(i, repo, { number: target });
        return {
          repo: snapshot.repo,
          pulls: snapshot.selected.flat(),
          errors: snapshot.history.errors,
        };
      },
      sync: (i, repo, target) =>
        this.reconcile(i, repo, { number: target, force: true, requireLock: true }),
    });
  }
  async handle(job: Job): Promise<void> {
    const payload = job.payload,
      installation = object(payload.installation).id;
    if (!Number.isSafeInteger(installation) || (installation as number) <= 0) return;
    const installationId = installation as number;
    if (!(await this.api.installationActive(installationId))) return;
    if (["installation", "installation_repositories"].includes(job.event)) {
      if (!["created", "added", "unsuspend"].includes(payload.action as string)) return;
      const repos = await this.api.list(
        installationId,
        "/installation/repositories",
        "repositories",
      );
      for (const repo of repos.filter((r) => this.allowed(r)))
        await this.options.enqueue!({
          id: `${job.id}-${repo.id}`,
          event: "reconcile",
          payload: {
            installation: { id: installationId },
            repository: { id: repo.id, full_name: repo.full_name },
          },
        });
      return;
    }
    const rawRepo = object(payload.repository);
    if (!this.allowed(rawRepo)) return;
    // Also drain self-generated deliveries queued before the webhook filter was deployed.
    if (object(payload.sender).type === "Bot") {
      const app = await this.api.identity();
      if (isSelfUpdate(job.event, payload, `${app.slug}[bot]`)) return;
    }
    const repo = Repository.fromJson(rawRepo);
    if (job.event === "merge_stack") {
      await this.merger().tick(installationId, repo, payload.tick);
      return;
    }
    // Only the private worker creates reconcile tasks with this flag, after authorization.
    let force = job.event === "reconcile" && payload.force === true;
    if (job.event === "issue_comment") {
      const sender = object(payload.sender);
      if (
        object(payload.issue).pull_request == null ||
        payload.action !== "created" ||
        sender.type === "Bot" ||
        (object(payload.comment).body as string | undefined)?.trim() !== "/stack sync" ||
        !(await this.api.canWrite(installationId, repo.apiPath, sender.login as string | undefined))
      )
        return;
      force = true;
    }
    const externalId = object(payload.check_run).external_id;
    const tail = typeof externalId === "string" ? externalId.split(":").at(-1) : undefined;
    const number = (object(payload.pull_request).number ??
      object(payload.issue).number ??
      (tail && /^\d+$/.test(tail) ? Number(tail) : undefined)) as number | undefined;
    if (job.event === "check_run") {
      if (
        payload.action !== "requested_action" ||
        String(object(object(payload.check_run).app).id) !== this.config.appId ||
        !Number.isSafeInteger(number) ||
        number! <= 0 ||
        externalId !== `stacked-pr:${repo.id}:${number}`
      )
        return;
      const action = object(payload.requested_action).identifier,
        sender = object(payload.sender);
      if (typeof sender.login !== "string") return;
      if (action === "merge-stack" || action === "squash-stack" || action === "cancel-merge") {
        if (sender.type !== "User") return;
        if (action === "merge-stack" || action === "squash-stack")
          await this.merger().start(
            installationId,
            repo,
            number!,
            job.id,
            sender.login,
            String(object(payload.check_run).head_sha),
            action === "squash-stack" ? "squash" : undefined,
          );
        else await this.merger().cancel(installationId, repo, number!, sender.login);
        return;
      }
      if (
        action !== "restack" ||
        !(await this.api.canWrite(installationId, repo.apiPath, sender.login))
      )
        return;
      force = true;
    }
    if (job.event === "reconcile" && number === undefined && this.options.enqueue) {
      const current = (await this.api.list(installationId, `${repo.apiPath}/pulls?state=open`))
        .map((p) => PullRequest.fromApi(p, repo.id))
        .filter((p) => p.sameRepo);
      const scheduled = new Set<number>();
      for (const pr of current) {
        if (scheduled.has(pr.number)) continue;
        const members = new Set([pr.number]);
        let changed = true;
        while (changed) {
          changed = false;
          for (const child of current)
            for (const parent of current.filter((p) => p.headRef === child.baseRef)) {
              if (members.has(child.number) || members.has(parent.number)) {
                if (!members.has(child.number)) {
                  members.add(child.number);
                  changed = true;
                }
                if (!members.has(parent.number)) {
                  members.add(parent.number);
                  changed = true;
                }
              }
            }
        }
        for (const member of members) scheduled.add(member);
        await this.options.enqueue({
          id: `${job.id}-${pr.number}`,
          event: "reconcile",
          payload: {
            installation: { id: installationId },
            repository: repo.toJson(),
            pull_request: { number: pr.number },
          },
        });
      }
      return;
    }
    const ref = payload.ref;
    await this.reconcile(installationId, repo, {
      force,
      number,
      branch:
        job.event === "push" && typeof ref === "string" && ref.startsWith("refs/heads/")
          ? ref.slice("refs/heads/".length)
          : undefined,
      previousBase:
        job.event === "pull_request" && payload.action === "edited"
          ? (payload.previous_base as string | undefined)
          : undefined,
    });
  }
  async reconcile(
    installation: number,
    repo: Repository,
    options: Selection & { force?: boolean; requireLock?: boolean } = {},
  ): Promise<void> {
    const initial = await this.discover(installation, repo, options);
    const resources = lockResources(initial.selected);
    if (!resources.length) return;
    // Repository identity is stable across renames and installations. PR IDs
    // protect shared members; head refs also protect multiple PRs on one branch.
    let lease: StackLease;
    try {
      lease = await this.options.locks.acquire(`${this.config.githubUrl}:${repo.id}`, resources);
    } catch (error) {
      if (!(error instanceof StackBusyException) || !this.options.enqueue || options.requireLock)
        throw error;
      // All producers in this window share one future task per affected component.
      // Schedule after the window closes: a completed task's ID tombstone must never
      // suppress a later notification. Enqueue before acknowledging the original.
      const windowMs = 30_000;
      const window = Math.floor((this.options.now?.() ?? Date.now()) / windowMs);
      for (const component of initial.selected) {
        const number = Math.min(...component.map((pr) => pr.number));
        await this.options.enqueue(
          {
            id: `deferred-${repo.id}-${installation}-${number}-${options.force ? "force" : "auto"}-${window}`,
            event: "reconcile",
            payload: {
              installation: { id: installation },
              repository: repo.toJson(),
              pull_request: { number },
              ...(options.force ? { force: true } : {}),
            },
          },
          new Date((window + 2) * windowMs),
        );
      }
      console.info(
        JSON.stringify({
          event: "stack_task_deferred",
          repository: repo.id,
          stacks: initial.selected.length,
        }),
      );
      return;
    }
    try {
      // Another delivery could have finished between discovery and acquisition.
      // Build a fresh plan under the lease; never execute the earlier snapshot.
      const fresh = await this.discover(installation, repo, options);
      lease.assertActive();
      const held = new Set(resources);
      if (lockResources(fresh.selected).some((resource) => !held.has(resource)))
        throw new RetryException("Stack membership changed before processing");
      await this.updateSelected(
        installation,
        fresh.repo,
        fresh.history,
        fresh.selected,
        options.force ?? false,
        lease,
      );
    } finally {
      await lease.release();
    }
  }

  private async discover(
    installation: number,
    repo: Repository,
    { number, branch, previousBase }: Selection,
  ): Promise<{ repo: Repository; history: History; selected: PullRequest[][] }> {
    const metadata = jsonObject(await this.api.request(installation, "GET", repo.apiPath));
    if (metadata.id !== repo.id || typeof metadata.default_branch !== "string")
      throw new RetryException("Repository identity changed");
    repo = new Repository(repo.id, repo.fullName, metadata.default_branch);
    const current = (await this.api.list(installation, `${repo.apiPath}/pulls?state=open`)).map(
      (p) => PullRequest.fromApi(p, repo.id),
    );
    if (number !== undefined && !current.some((p) => p.number === number))
      current.push(
        PullRequest.fromApi(
          jsonObject(
            await this.api.request(installation, "GET", `${repo.apiPath}/pulls/${number}`),
          ),
          repo.id,
        ),
      );
    const history = new History(this.api, installation, repo);
    if (
      !current.length ||
      (branch === repo.defaultBranch && !current.some((p) => p.headRef === branch))
    )
      return { repo, history, selected: [] };
    const pulls = await history.discover(current, { number, branch, previousBase });
    // Scope failures before checking cycles or boundaries, so unrelated stacks can continue.
    const components: PullRequest[][] = [],
      assigned = new Set<number>();
    for (const pr of pulls) {
      if (assigned.has(pr.number)) continue;
      const numbers = new Set([pr.number]);
      let changed = true;
      while (changed) {
        changed = false;
        for (const item of pulls)
          if (item.parent !== undefined && (numbers.has(item.number) || numbers.has(item.parent))) {
            if (!numbers.has(item.number)) {
              numbers.add(item.number);
              changed = true;
            }
            if (!numbers.has(item.parent)) {
              numbers.add(item.parent);
              changed = true;
            }
          }
      }
      for (const n of numbers) assigned.add(n);
      components.push(pulls.filter((p) => numbers.has(p.number)));
    }
    const selected = components.filter(
      (component) =>
        (number === undefined && branch === undefined) ||
        component.some(
          (p) =>
            p.number === number ||
            (previousBase !== undefined &&
              previousBase !== repo.defaultBranch &&
              p.headRef === previousBase) ||
            (branch !== undefined &&
              (p.headRef === branch || (branch !== repo.defaultBranch && p.baseRef === branch))),
        ),
    );
    return { repo, history, selected };
  }

  private async updateSelected(
    installation: number,
    repo: Repository,
    history: History,
    selected: PullRequest[][],
    force: boolean,
    lease: StackLease,
  ): Promise<void> {
    if (!selected.length) return;
    lease.assertActive();
    const selectedPulls = selected.flat().filter((p) => p.sameRepo),
      enabled = force || this.config.autoRestack;
    const git = this.gitFactory(installation, repo);
    if (enabled && selectedPulls.some((p) => p.isOpen && p.parent !== undefined)) {
      const deleted = new Set(selectedPulls.filter((p) => !p.isOpen).map((p) => p.headRef));
      await git.prepare({
        pulls: selectedPulls,
        branches: [
          ...new Set([
            repo.defaultBranch!,
            ...selectedPulls.filter((p) => p.isOpen).map((p) => p.headRef),
            ...selectedPulls.map((p) => p.baseRef).filter((b) => !deleted.has(b)),
          ]),
        ],
      });
    }
    for (const component of selected) {
      lease.assertActive();
      let result = component,
        error: RestackException | undefined;
      try {
        for (const pr of component)
          if (history.errors.has(pr.number)) throw history.errors.get(pr.number);
        ordered(component);
        if (enabled && component.some((p) => p.isOpen && p.parent !== undefined))
          result = await this.restack(installation, repo, git, history, component);
      } catch (failure) {
        if (!(failure instanceof RestackException)) throw failure;
        error = failure;
        console.warn(
          JSON.stringify({ event: "restack_blocked", repository: repo.id, pull: error.number }),
        );
      }
      lease.assertActive();
      await this.options.reporter.publish(installation, repo, result, {
        error,
        observeOnly: !this.config.autoRestack,
        closedToUpdate: component.filter((p) => !p.isOpen).map((p) => p.number),
      });
    }
  }
  private async restack(
    installation: number,
    repo: Repository,
    git: GitRepository,
    history: History,
    pulls: PullRequest[],
  ): Promise<PullRequest[]> {
    const byNumber = new Map(pulls.map((pr) => [pr.number, pr]));
    for (const child of pulls.filter((p) => p.isOpen && p.sameRepo)) {
      if ((await git.branch(child.headRef)) !== child.head)
        throw new RetryException("Branch changed during fetch");
      if (child.parent === undefined) continue;
      if (child.headRef === repo.defaultBranch)
        throw new RestackException("デフォルトブランチは書き換えられません。", child.number);
      const parent = byNumber.get(child.parent)!;
      if (!parent.isOpen && !parent.merged)
        throw new RestackException(
          "親PRがmergeされずに閉じられています。依存先を確認してください。",
          child.number,
        );
      let ancestor = parent;
      const merged: PullRequest[] = [];
      while (ancestor.merged) {
        merged.push(ancestor);
        const next = ancestor.parent === undefined ? undefined : byNumber.get(ancestor.parent);
        if (!next) break;
        ancestor = next;
      }
      const target = ancestor.merged ? await git.branch(ancestor.baseRef) : ancestor.head;
      await git.ensure(target);
      if (await git.ancestor(target, child.head)) child.boundary = target;
      else if (merged.length && merged.every((p) => p.mergeCommit != null))
        child.boundary = await git.findMergedBoundary({
          head: child.head,
          target,
          mergeCommits: merged.map((p) => p.mergeCommit!),
        });
      child.boundary ??= await history.boundary(git, parent, child);
    }
    const plan = await planRestack(pulls, git),
      mutations = plan.changes.filter((c) => c.mutates);
    if (!mutations.length) return plan.pulls;
    for (const before of pulls) {
      const now = PullRequest.fromApi(
        jsonObject(
          await this.api.request(installation, "GET", `${repo.apiPath}/pulls/${before.number}`),
        ),
        repo.id,
      );
      if (
        now.head !== before.head ||
        now.baseRef !== before.baseRef ||
        now.state !== before.state ||
        now.merged !== before.merged ||
        !now.sameRepo
      )
        throw new RetryException("PR changed during restack");
    }
    await git.push(mutations);
    // A retry reconstructs current GitHub state; already-pushed children are not replayed.
    for (const change of mutations) {
      let now!: PullRequest;
      // GHES can briefly return the old SHA after a successful atomic push.
      // Only wait for that known old state; other changes require a fresh plan.
      for (let attempt = 0; attempt < 5; attempt++) {
        now = PullRequest.fromApi(
          jsonObject(
            await this.api.request(installation, "GET", `${repo.apiPath}/pulls/${change.number}`),
          ),
          repo.id,
        );
        if (
          !now.isOpen ||
          !now.sameRepo ||
          now.head === change.newHead ||
          now.head !== change.oldHead ||
          ![change.oldBase, change.newBase].includes(now.baseRef) ||
          attempt === 4
        )
          break;
        this.options.deadline?.limit(500);
        await delay(500);
      }
      if (
        !now.isOpen ||
        !now.sameRepo ||
        now.head !== change.newHead ||
        ![change.oldBase, change.newBase].includes(now.baseRef)
      )
        throw new RetryException("PR changed after push or GitHub is still updating");
      if (now.baseRef !== change.newBase)
        await this.api.request(installation, "PATCH", `${repo.apiPath}/pulls/${change.number}`, {
          base: change.newBase,
        });
    }
    return plan.pulls;
  }
}
