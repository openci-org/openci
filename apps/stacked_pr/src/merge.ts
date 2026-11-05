import { createHash } from "node:crypto";
import { ApiException, type GitHubApi } from "./github.js";
import type { StackLocks } from "./locks.js";
import type { MergeStops, Terminal } from "./merge-stops.js";
import {
  type Job,
  type Json,
  jsonObject,
  object,
  PullRequest,
  Repository,
  RetryException,
  StackBusyException,
} from "./models.js";

const lifetime = 24 * 60 * 60_000;
const shaPattern = /^(?:[a-f0-9]{40}|[a-f0-9]{64})$/;
const ticketPattern = /^[\w-]{1,128}$/;
const markerPattern =
  /^<!-- stacked-pr-app:merge:([\w-]{1,128}):(active|stopped|complete|cancelled) -->/;
type State = "active" | Terminal;
type Member = { number: number; ref: string; head: string; base: string };
interface Plan {
  id: string;
  login: string;
  trunk: string;
  expires: number;
  members: Member[];
}
interface Tick {
  plan: Plan;
  sequence: number;
  prepared: number;
  waits: number;
  comment?: number;
}
interface Options {
  api: GitHubApi;
  locks: StackLocks;
  stops: MergeStops;
  host: string;
  now?: () => number;
  enqueue: (job: Job, scheduleTime?: Date) => Promise<boolean>;
  discover: (
    installation: number,
    repo: Repository,
    target: number,
  ) => Promise<{ repo: Repository; pulls: PullRequest[]; errors: ReadonlyMap<number, Error> }>;
  sync: (installation: number, repo: Repository, target: number) => Promise<void>;
}
class Stop extends Error {}
function need(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Stop(message);
}
function owned(comment: Json, app: Json) {
  const user = object(comment.user),
    via = object(comment.performed_via_github_app);
  return (
    user.type === "Bot" &&
    user.login === `${app.slug}[bot]` &&
    (via.id === undefined || via.id === app.id)
  );
}
export function activeMerge(comment: Json, app: Json): boolean {
  return owned(comment, app) && markerPattern.exec(String(comment.body))?.[2] === "active";
}

/** Follow only the chosen PR's ancestors. A sibling or a later descendant is never authorized. */
function lineage(
  pulls: PullRequest[],
  target: number,
  head: string,
  trunk: string,
  errors: ReadonlyMap<number, Error>,
): Member[] {
  const byNumber = new Map(pulls.map((p) => [p.number, p]));
  let pr = byNumber.get(target);
  need(
    pr?.isOpen && pr.head === head,
    "選択したPRが更新または終了しています。最新のCheckからやり直してください。",
  );
  const seen = new Set<number>(),
    members: Member[] = [];
  while (pr) {
    need(!seen.has(pr.number) && !errors.has(pr.number), "親子関係を一意に確認できません。");
    seen.add(pr.number);
    need(
      pr.sameRepo && pr.headRef !== trunk && (pr.isOpen || pr.merged),
      `#${pr.number} の状態では一括マージできません。`,
    );
    need(!pr.draft, `#${pr.number} はドラフトです。`);
    if (pr.isOpen)
      members.unshift({ number: pr.number, ref: pr.headRef, head: pr.head, base: pr.baseRef });
    if (pr.parent === undefined) {
      need(pr.baseRef === trunk, "このスタックはデフォルトブランチにつながっていません。");
      break;
    }
    pr = byNumber.get(pr.parent);
    need(pr, "親PRが見つかりません。");
  }
  need(members.length <= 200, "一括マージは200件までです。");
  return members;
}

/** Allow only an unbroken suffix of force pushes by this App, anchored at the selected SHA. */
function ownRebase(events: Json[], old: string, head: string, slug: string): boolean {
  let cursor = head;
  for (const e of [...events].reverse()) {
    if (e.__typename !== "HeadRefForcePushedEvent") continue;
    const actor = object(e.actor),
      before = object(e.beforeCommit).oid;
    if (
      object(e.afterCommit).oid !== cursor ||
      typeof before !== "string" ||
      actor.__typename !== "Bot" ||
      ![slug, `${slug}[bot]`].includes(String(actor.login).toLowerCase())
    )
      return false;
    cursor = before;
    if (cursor === old) return true;
  }
  return false;
}

async function currentMembers(
  api: GitHubApi,
  i: number,
  repo: Repository,
  plan: Plan,
  app: Json,
): Promise<PullRequest[]> {
  const pulls: PullRequest[] = [];
  for (const member of plan.members) {
    const pr = PullRequest.fromApi(
      jsonObject(await api.request(i, "GET", `${repo.apiPath}/pulls/${member.number}`)),
      repo.id,
    );
    need(
      pr.number === member.number &&
        pr.sameRepo &&
        pr.headRef === member.ref &&
        pr.headRef !== plan.trunk,
      `#${member.number} のブランチが変更されています。`,
    );
    need(
      pr.isOpen || (pr.merged && pr.baseRef === plan.trunk),
      `#${member.number} はデフォルトブランチへのマージ以外の方法で閉じられました。`,
    );
    need(!pr.draft, `#${member.number} はドラフトです。`);
    if (pr.head !== member.head)
      need(
        ownRebase(
          await api.timeline(i, repo, pr.number, true),
          member.head,
          pr.head,
          String(app.slug).toLowerCase(),
        ),
        `#${pr.number} に新しい変更があります。確認して再度Merge stackを選んでください。`,
      );
    const parent = pulls.at(-1);
    const allowedBase = parent?.isOpen
      ? pr.baseRef === parent.headRef
      : pr.baseRef === member.base || pr.baseRef === plan.trunk;
    need(!pr.isOpen || allowedBase, `#${pr.number} の依存先が変更されています。`);
    need(!pr.merged || pulls.every((p) => p.merged), "親より先にマージされたPRがあります。");
    pulls.push(pr);
  }
  return pulls;
}
async function readiness(
  api: GitHubApi,
  i: number,
  repo: Repository,
  trunk: string,
  pr: PullRequest,
  app: Json,
): Promise<{ reason: string; sync?: boolean } | undefined> {
  if (pr.baseRef !== trunk) {
    return { reason: "親のマージ後の再同期待ち", sync: true };
  }
  const checks = await api.list(
    i,
    `${repo.apiPath}/commits/${pr.head}/check-runs?check_name=Stacked%20PR&filter=all`,
    "check_runs",
  );
  const check = checks
    .filter(
      (c) => object(c.app).id === app.id && c.external_id === `stacked-pr:${repo.id}:${pr.number}`,
    )
    .sort((a, b) => Number(b.id) - Number(a.id))[0];
  need(check?.conclusion !== "failure", `#${pr.number} のStacked PRチェックが失敗しています。`);
  if (check?.conclusion !== "success") {
    return { reason: "最新のStacked PRチェック待ち", sync: true };
  }
  const [owner, name] = repo.fullName.split("/");
  const response = jsonObject(
    await api.request(i, "POST", "/graphql", {
      query: `query StackMergeReady($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) { pullRequest(number: $number) {
    state isDraft headRefOid baseRefName mergeStateStatus mergeable reviewDecision
    commits(last: 1) { nodes { commit { oid statusCheckRollup { state } } } }
  } }
}`,
      variables: { owner, name, number: pr.number },
    }),
  );
  if (response.errors != null) throw new RetryException("Merge readiness unavailable");
  const ready = jsonObject(jsonObject(jsonObject(response.data).repository).pullRequest);
  const nodes = jsonObject(ready.commits).nodes;
  const commit = Array.isArray(nodes) ? object(object(nodes[0]).commit) : {};
  need(
    ready.mergeStateStatus !== "DIRTY" && ready.mergeable !== "CONFLICTING",
    `#${pr.number} にマージ競合があります。`,
  );
  if (
    ready.state !== "OPEN" ||
    ready.isDraft !== false ||
    ready.headRefOid !== pr.head ||
    ready.baseRefName !== trunk ||
    ready.mergeable !== "MERGEABLE" ||
    !["CLEAN", "HAS_HOOKS"].includes(String(ready.mergeStateStatus)) ||
    !(ready.reviewDecision === null || ready.reviewDecision === "APPROVED") ||
    commit.oid !== pr.head ||
    object(commit.statusCheckRollup).state !== "SUCCESS"
  ) {
    return { reason: "承認・CI・ブランチ保護の条件待ち" };
  }
}

export class StackMerge {
  constructor(private readonly options: Options) {}
  private now() {
    return this.options.now?.() ?? Date.now();
  }
  private key(i: number, repo: Repository, target: number, id: string) {
    return JSON.stringify([this.options.host, i, repo.id, target, id]);
  }
  private async comments(i: number, repo: Repository, target: number, app: Json) {
    return (await this.options.api.list(i, `${repo.apiPath}/issues/${target}/comments`)).filter(
      (c) => owned(c, app) && markerPattern.test(String(c.body)),
    );
  }
  private async note(
    i: number,
    repo: Repository,
    target: number,
    id: string,
    state: State,
    text: string,
    comment?: Json,
  ): Promise<Json> {
    if (state !== "active") {
      const decided = await this.options.stops.close(this.key(i, repo, target, id), state);
      if (decided !== state) {
        state = decided;
        text = "この一括マージはすでに終了しています。";
      }
      // Refresh the target Check's buttons after the progress marker becomes terminal.
      const key = createHash("sha256")
        .update(JSON.stringify([i, repo.id, target, id, state]))
        .digest("hex");
      await this.options.enqueue(
        {
          id: `merge-controls-${key}`,
          event: "reconcile",
          payload: {
            installation: { id: i },
            repository: repo.toJson(),
            pull_request: { number: target },
          },
        },
        new Date(this.now() + 5_000),
      );
    }
    const body = `<!-- stacked-pr-app:merge:${id}:${state} -->\n## Merge stack\n\n${text}`;
    if (!comment) {
      const created = jsonObject(
        await this.options.api.request(i, "POST", `${repo.apiPath}/issues/${target}/comments`, {
          body,
        }),
      );
      if (!Number.isSafeInteger(created.id))
        throw new RetryException("Merge progress comment unavailable");
      return { ...created, body };
    }
    if (comment.body !== body)
      await this.options.api.request(i, "PATCH", `${repo.apiPath}/issues/comments/${comment.id}`, {
        body,
      });
    return { ...comment, body };
  }
  private async schedule(i: number, repo: Repository, tick: Tick, delayMs: number) {
    const key = createHash("sha256")
      .update(JSON.stringify([i, repo.id, tick.plan.id, tick.sequence]))
      .digest("hex");
    await this.options.enqueue(
      {
        id: `merge-${key}`,
        event: "merge_stack",
        payload: { installation: { id: i }, repository: repo.toJson(), tick },
      },
      delayMs ? new Date(this.now() + delayMs) : undefined,
    );
  }
  async start(
    i: number,
    repo: Repository,
    target: number,
    id: string,
    login: string,
    head: string,
  ) {
    if (
      !ticketPattern.test(id) ||
      !shaPattern.test(head) ||
      !(await this.options.api.canWrite(i, repo.apiPath, login))
    )
      return;
    const found = await this.options.discover(i, repo, target);
    try {
      const members = lineage(found.pulls, target, head, found.repo.defaultBranch!, found.errors);
      await this.schedule(
        i,
        found.repo,
        {
          plan: {
            id,
            login,
            trunk: found.repo.defaultBranch!,
            expires: this.now() + lifetime,
            members,
          },
          sequence: 0,
          prepared: -1,
          waits: 0,
        },
        0,
      );
    } catch (error) {
      if (!(error instanceof Stop)) throw error;
      const comments = await this.comments(i, repo, target, await this.options.api.identity());
      if (!comments.some((c) => markerPattern.exec(String(c.body))?.[1] === id))
        await this.note(i, repo, target, id, "stopped", `停止：${error.message}`);
    }
  }
  async cancel(i: number, repo: Repository, target: number, login: string) {
    if (!(await this.options.api.canWrite(i, repo.apiPath, login))) return;
    const lease = await this.options.locks.acquire(`${this.options.host}:${repo.id}`, [
      `pr:${target}`,
    ]);
    try {
      const app = await this.options.api.identity();
      for (const comment of await this.comments(i, repo, target, app))
        if (activeMerge(comment, app)) {
          lease.assertActive();
          await this.note(
            i,
            repo,
            target,
            markerPattern.exec(String(comment.body))![1],
            "cancelled",
            "キャンセルしました。すでにマージされたPRはそのままです。",
            comment,
          );
        }
    } finally {
      await lease.release();
    }
  }
  async tick(i: number, repo: Repository, raw: unknown) {
    // Only the authenticated private worker creates these jobs. Never derive a plan from comment text.
    const tick = raw as Tick;
    if (
      !tick ||
      !ticketPattern.test(tick.plan?.id ?? "") ||
      !tick.plan?.login ||
      !tick.plan.trunk ||
      !Number.isFinite(tick.plan.expires) ||
      !Number.isSafeInteger(tick.sequence) ||
      tick.sequence < 0 ||
      !Number.isInteger(tick.prepared) ||
      !Number.isInteger(tick.waits) ||
      tick.waits < 0 ||
      !Array.isArray(tick.plan.members) ||
      !tick.plan.members.length ||
      tick.plan.members.length > 200 ||
      !tick.plan.members.every(
        (p) =>
          Number.isSafeInteger(p.number) &&
          p.number > 0 &&
          typeof p.ref === "string" &&
          typeof p.base === "string" &&
          shaPattern.test(p.head),
      )
    )
      throw new Error("Invalid merge task");
    const { plan } = tick,
      target = plan.members.at(-1)!.number;
    const next = (overrides: Partial<Tick>, delay: number) =>
      this.schedule(i, repo, { ...tick, ...overrides, sequence: tick.sequence + 1 }, delay);
    let lease;
    try {
      lease = await this.options.locks.acquire(
        `${this.options.host}:${repo.id}`,
        plan.members.flatMap((p) => [`pr:${p.number}`, `head:${p.ref}`]),
      );
    } catch (e) {
      if (!(e instanceof StackBusyException)) throw e;
      await next({}, 30_000);
      return;
    }
    let refresh: number | undefined, comment: Json | undefined;
    const order = plan.members.map((p) => `#${p.number}`).join(" → ");
    const note = async (state: State, msg: string) => {
      lease.assertActive();
      comment = await this.note(i, repo, target, plan.id, state, `${order}\n\n${msg}`, comment);
      tick.comment = comment.id as number;
    };
    try {
      const api = this.options.api,
        app = await api.identity(),
        comments = await this.comments(i, repo, target, app);
      comment = comments.find((c) => markerPattern.exec(String(c.body))?.[1] === plan.id);
      const terminal = await this.options.stops.get(this.key(i, repo, target, plan.id));
      if (terminal) {
        if (comment && activeMerge(comment, app))
          await note(terminal, "この一括マージは終了しています。");
        return;
      }
      if (
        comment &&
        (!activeMerge(comment, app) || (tick.comment !== undefined && comment.id !== tick.comment))
      )
        return;
      if (!comment && (tick.comment !== undefined || comments.some((c) => activeMerge(c, app))))
        return;
      need(
        this.now() < plan.expires,
        "待機期限（24時間）を過ぎました。必要なら再度Merge stackを選んでください。",
      );
      need(
        await api.canWrite(i, repo.apiPath, plan.login),
        "実行者の書き込み権限を確認できません。",
      );
      const metadata = jsonObject(await api.request(i, "GET", repo.apiPath));
      need(
        metadata.id === repo.id && metadata.default_branch === plan.trunk,
        "デフォルトブランチが変更されています。",
      );
      const pulls = await currentMembers(api, i, repo, plan, app);
      const index = pulls.findIndex((p) => p.isOpen);
      if (index < 0) {
        await note("complete", "すべてデフォルトブランチにマージしました。");
        return;
      }
      const pr = pulls[index];
      if (tick.prepared !== index) {
        await note("active", `#${pr.number} の依存関係を同期しています。`);
        refresh = index;
      } else {
        const wait = async (msg: string, prepare = false) => {
          await note("active", `#${pr.number}：${msg}（条件がそろうと自動で続行します）。`);
          await next(
            { waits: tick.waits + 1, prepared: prepare ? -1 : index },
            Math.min(180_000, 30_000 * 2 ** Math.min(tick.waits, 3)),
          );
        };
        const pending = await readiness(api, i, repo, plan.trunk, pr, app);
        if (pending) {
          await wait(pending.reason, pending.sync);
          return;
        }
        const method =
          metadata.allow_squash_merge === true
            ? "squash"
            : metadata.allow_merge_commit === true
              ? "merge"
              : metadata.allow_rebase_merge === true
                ? "rebase"
                : undefined;
        need(method, "リポジトリで利用できるマージ方式がありません。");
        lease.assertActive();
        try {
          const result = jsonObject(
            await api.request(i, "PUT", `${repo.apiPath}/pulls/${pr.number}/merge`, {
              sha: pr.head,
              merge_method: method,
            }),
          );
          if (result.merged !== true) {
            await wait("GitHubのマージ許可待ち");
            return;
          }
        } catch (e) {
          if (e instanceof ApiException && [405, 409].includes(e.status)) {
            await wait("GitHubのマージ条件を再確認中");
            return;
          }
          if (e instanceof ApiException && [403, 422].includes(e.status))
            throw new Stop(`GitHubが #${pr.number} のマージを許可しませんでした（${e.status}）。`);
          throw e;
        }
        await note("active", `#${pr.number} をマージしました。次の状態を確認します。`);
        await next({ waits: 0 }, 5_000);
      }
    } catch (e) {
      if (!(e instanceof Stop)) throw e;
      await note("stopped", `停止：${e.message}`);
    } finally {
      await lease.release();
    }
    if (refresh !== undefined) {
      // Normal restacking acquires its own lease and publishes checks on the new SHAs.
      try {
        await this.options.sync(i, repo, target);
      } catch (e) {
        if (!(e instanceof StackBusyException)) throw e;
        await next({}, 30_000);
        return;
      }
      await next({ prepared: refresh, waits: 0 }, 0);
    }
  }
}
