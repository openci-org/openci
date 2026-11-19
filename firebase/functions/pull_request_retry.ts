import type { ExecutionGitHub } from "./executor/github.js";
import type { ExecutionStore } from "./executor/store.js";
import {
  commentTeam,
  executionOrder,
  hasStatus,
  pullRequestCommentScope,
} from "./executor/pull_request_comment.js";
import {
  readRetryControl,
  retryControl,
  withoutRetryControl,
  type RetryClick,
} from "./pull_request_retry_control.js";

type Store = Pick<
  ExecutionStore,
  | "pullRequestCommentExecution"
  | "context"
  | "withPullRequestCommentLease"
  | "retryMember"
  | "retryAsMember"
>;

export async function retryFromPullRequest(
  click: RetryClick,
  store: Store,
  github: Pick<ExecutionGitHub, "options" | "withPullRequestComment">,
) {
  const { job } = await store.pullRequestCommentExecution(click.jobId);
  if (
    !job?.teamId ||
    !job.commitSha ||
    job.runsOn !== "macos-latest" ||
    job.pullRequestNumber !== click.pr ||
    job.installationId !== click.installationId ||
    (job.repositoryId != null && job.repositoryId !== click.repositoryId) ||
    (job.githubBaseUrl ?? "https://github.com") !== github.options.baseUrl ||
    commentTeam(job.teamId) !== click.team
  )
    return;
  const { appId, apiBaseUrl } = github.options;
  const teamId = job.teamId;
  const { connection } = await store.context(
    teamId,
    click.installationId,
    appId,
    apiBaseUrl,
    job.repositoryId,
  );
  if (!connection) return;
  const signal = AbortSignal.timeout(90_000);
  await github.withPullRequestComment(
    job,
    connection.accountId,
    signal,
    async (request, target) => {
      if (String(target.repositoryId) !== click.repositoryId) return;
      const scope = pullRequestCommentScope(appId, job, target.repositoryId, "result", [
        job.workflowJobKey ?? "",
        job.matrixLabel ?? "",
      ]);
      if (scope !== click.scope) return;
      await store.withPullRequestCommentLease(scope, signal, async (renew) => {
        const ref = { ...target.repo, comment_id: click.commentId };
        const read = async () =>
          (await request("GET /repos/{owner}/{repo}/issues/comments/{comment_id}", ref)).data;
        const comment = await read();
        const issueUrl = `${apiBaseUrl}/repos/${job.owner}/${job.repo}/issues/${click.pr}`;
        if (
          comment.user?.type !== "Bot" ||
          String(comment.performed_via_github_app?.id) !== appId ||
          comment.issue_url.toLowerCase() !== issueUrl.toLowerCase()
        )
          return;
        const body = (comment.body ?? "").replaceAll("\r\n", "\n");
        const control = readRetryControl(body);
        if (
          !control?.checked ||
          control.marker !== click.marker ||
          control.jobId !== job.id ||
          control.count !== click.count
        )
          return;
        const currentComment = async () => {
          await renew();
          return (await target.current()) && (await read()).body === comment.body;
        };
        const member = async () => {
          try {
            const { data } = await request(
              "GET /repos/{owner}/{repo}/collaborators/{username}/permission",
              { ...target.repo, username: click.login },
            );
            if (
              String(data.user?.id) !== click.actorId ||
              !["write", "maintain", "admin"].includes(data.permission)
            )
              return null;
            return await store.retryMember(teamId, apiBaseUrl, appId, click.actorId);
          } catch (error) {
            if (hasStatus(error, 404) && error instanceof Error && "request" in error) return null;
            throw error;
          }
        };
        const state = await queueSelectedAttempt(store, click, teamId, member, currentComment);
        // A human may uncheck or edit the comment while the queue accepts the job.
        if (!state || !(await currentComment())) return;
        await renew();
        await request("PATCH /repos/{owner}/{repo}/issues/comments/{comment_id}", {
          ...ref,
          body: [
            withoutRetryControl(body),
            retryControl(job.id, click.count, state),
            click.marker,
          ].join("\n\n"),
        });
      });
    },
  );
}

async function queueSelectedAttempt(
  store: Store,
  click: RetryClick,
  teamId: string,
  member: () => Promise<string | null>,
  currentComment: () => Promise<boolean>,
): Promise<"accepted" | "denied" | null> {
  const { job, latest } = await store.pullRequestCommentExecution(click.jobId);
  if (job?.teamId !== teamId) return null;
  // A committed mutation may have lost its response or its subsequent GitHub edit.
  if (job.retryCount === click.count + 1) return "accepted";
  if (
    job.retryCount !== click.count ||
    !latest?.finishedAt ||
    latest.teamId !== teamId ||
    executionOrder(latest.createdAt).toString() !== click.order ||
    !["failure", "timed_out"].includes(latest.outcome ?? "") ||
    job.status !== latest.outcome?.toUpperCase()
  )
    return null;
  const uid = await member();
  if (!uid) return "denied";
  if (!(await currentComment())) return null;
  try {
    await store.retryAsMember(job.id, click.count, uid);
    return "accepted";
  } catch (error) {
    const after = await store.pullRequestCommentExecution(job.id);
    if (after.job?.retryCount === click.count + 1) return "accepted";
    if (after.job?.retryCount !== click.count || after.latest?.id !== latest.id) return null;
    if ((await member()) !== uid) return "denied";
    throw error;
  }
}
