import { createHash } from "node:crypto";
import type { Job } from "./model.js";

export type GitHubRequest = (typeof import("@octokit/request"))["request"];
export type WithCommentLease = (
  key: string,
  work: (renew: () => Promise<void>) => Promise<void>,
) => Promise<void>;

export function hasStatus(error: unknown, ...codes: number[]): boolean {
  return error instanceof Error && "status" in error && codes.includes(Number(error.status));
}

export function inlineCode(value: string): string {
  const text = value.replace(/[\r\n]/gu, " ").trim();
  const ticks = Math.max(0, ...(text.match(/`+/gu) ?? []).map((run) => run.length)) + 1;
  const fence = "`".repeat(ticks);
  const padding = text.startsWith("`") || text.endsWith("`") ? " " : "";
  return `${fence}${padding}${text}${padding}${fence}`;
}

export async function pullRequestCommentTarget(
  request: GitHubRequest,
  job: Job,
  accountId: string,
) {
  const repo = { owner: job.owner, repo: job.repo };
  const number = Number(job.pullRequestNumber);
  const target = (await request("GET /repos/{owner}/{repo}", repo)).data;
  if (
    String(target.owner.id) !== accountId ||
    (job.repositoryId != null && String(target.id) !== job.repositoryId) ||
    target.full_name.toLowerCase() !== `${repo.owner}/${repo.repo}`.toLowerCase()
  ) {
    throw new Error("Pull request repository owner changed");
  }
  const current = async () => {
    const { data: pr } = await request("GET /repos/{owner}/{repo}/pulls/{pull_number}", {
      ...repo,
      pull_number: number,
    });
    return (
      pr.number === number &&
      pr.state === "open" &&
      pr.base.repo.id === target.id &&
      pr.head.repo?.id === target.id &&
      pr.head.sha === job.commitSha
    );
  };
  if (!(await current())) return null;
  return { repo, number, repositoryId: target.id, current };
}

export async function updatePullRequestComment(
  request: GitHubRequest,
  appId: string,
  job: Job,
  target: NonNullable<Awaited<ReturnType<typeof pullRequestCommentTarget>>>,
  kind: "qr" | "result",
  runNumber: number | bigint,
  withLease: WithCommentLease,
  render: (previous: string | null) => string | null | Promise<string | null>,
  variant: readonly string[] = [],
): Promise<void> {
  const { repo, number } = target;
  const scope = createHash("sha256")
    .update(
      JSON.stringify([
        job.githubBaseUrl ?? "https://github.com",
        appId,
        target.repositoryId,
        number,
        job.workflowFileName,
        ...(kind === "result" ? [kind, ...variant] : []),
      ]),
    )
    .digest("hex");
  // Run numbers are monotonic within a team. A repository moved to a new
  // team can reuse the comment even if that team's sequence starts lower.
  const team = createHash("sha256").update(job.teamId!).digest("hex");
  const footer = new RegExp(`\\n<!-- openci-pr-${kind}:${scope}:([a-f0-9]{64}):([1-9][0-9]*) -->$`);
  const marker = `<!-- openci-pr-${kind}:${scope}:${team}:${runNumber} -->`;
  const issue = { ...repo, issue_number: number };
  const findComment = async (renew: () => Promise<void>) => {
    for (let page = 1; ; page++) {
      if (page > 1) await renew();
      const { data } = await request("GET /repos/{owner}/{repo}/issues/{issue_number}/comments", {
        ...issue,
        page,
        per_page: 100,
      });
      for (const comment of data) {
        if (comment.user?.type !== "Bot" || String(comment.performed_via_github_app?.id) !== appId)
          continue;
        const match = footer.exec(comment.body ?? "");
        if (match)
          return {
            id: comment.id,
            team: match[1],
            run: BigInt(match[2]),
            body: comment.body!.slice(0, match.index).trimEnd(),
          };
      }
      if (data.length < 100) return null;
    }
  };
  await withLease(scope, async (renew) => {
    const existing = await findComment(renew);
    const coversRun = (comment: typeof existing) =>
      comment !== null && comment.team === team && comment.run >= BigInt(runNumber);
    if (coversRun(existing)) return;
    const content = await render(existing?.body ?? null);
    if (content === null || !(await target.current())) return;
    let body = `${content}\n\n${marker}`;
    // Only the holder may make the bounded GitHub write; a late old run must
    // re-read the comment if another executor has taken its lease.
    await renew();
    if (existing) {
      try {
        await request("PATCH /repos/{owner}/{repo}/issues/comments/{comment_id}", {
          ...repo,
          comment_id: existing.id,
          body,
        });
        return;
      } catch (error) {
        const observed = await findComment(renew);
        if (coversRun(observed)) return;
        if (!hasStatus(error, 404) || observed) throw error;
        // Someone deleted the comment between the lookup and the edit.
        const replacement = await render(null);
        if (replacement === null || !(await target.current())) return;
        body = `${replacement}\n\n${marker}`;
        await renew();
      }
    }
    try {
      await request("POST /repos/{owner}/{repo}/issues/{issue_number}/comments", {
        ...issue,
        body,
      });
    } catch (error) {
      if (!coversRun(await findComment(renew))) throw error;
    }
  });
}
