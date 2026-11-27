import { createHash } from "node:crypto";
import { connectorConfig as webhooksConnector } from "@openci/webhooks-admin";
import { onMutationExecuted } from "firebase-functions/dataconnect";
import { error, warn } from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { validJobId } from "./build_dispatch.js";
import { dataConnectServiceId } from "./data_connect_config.js";
import { getDispatchDataConnect } from "./dispatch_store.js";
import { buildGitHub, type ExecutionGitHub } from "./executor/github.js";
import { ExecutionStore, isolatedConnector } from "./executor/store.js";
import { dispatchServiceAccount } from "./function_identity.js";
import { enqueueWebhook, type WebhookDelivery } from "./webhook_queue.js";
import {
  failedPullRequestComment,
  resolvedPullRequestComment,
  successfulPullRequestComment,
} from "./pull_request_failure.js";

type Store = Pick<
  ExecutionStore,
  | "pullRequestCommentExecution"
  | "pullRequestFailureLog"
  | "completedCheck"
  | "context"
  | "withPullRequestCommentLease"
>;

export async function reportCompletedPullRequest(
  jobId: string,
  dispatchId: string,
  store: Store,
  github: Pick<
    ExecutionGitHub,
    "options" | "currentPullRequestRevision" | "postPullRequestResult" | "check"
  >,
  enqueue: (delivery: WebhookDelivery) => Promise<unknown>,
) {
  const { job, latest } = await store.pullRequestCommentExecution(jobId);
  if (
    !job?.pullRequestNumber ||
    !job.teamId ||
    !job.installationId ||
    !job.commitSha ||
    !/^[a-f0-9]{40}(?:[a-f0-9]{24})?$/u.test(job.commitSha) ||
    !latest?.finishedAt ||
    latest.id !== dispatchId ||
    latest.teamId !== job.teamId ||
    !["success", "failure", "timed_out"].includes(latest.outcome ?? "") ||
    job.status !== latest.outcome?.toUpperCase()
  )
    return;
  const { connection } = await store.context(
    job.teamId,
    job.installationId,
    github.options.appId,
    github.options.apiBaseUrl,
    job.repositoryId,
  );
  if (!connection) return;
  const signal = AbortSignal.timeout(90_000);
  if (latest.runId && latest.pullRequestBaseBranch && latest.pullRequestBaseSha) {
    const revision = await github.currentPullRequestRevision(job, connection.accountId, signal);
    if (!revision || revision.base.ref !== latest.pullRequestBaseBranch) return;
    if (revision.base.sha !== latest.pullRequestBaseSha) {
      const current = await store.pullRequestCommentExecution(jobId);
      if (current.latest?.id !== dispatchId || current.job?.status !== job.status) return;
      const repo = { id: revision.repositoryId };
      const payload = JSON.stringify({
        action: "openci_base_changed",
        openci_team_id: job.teamId,
        number: revision.number,
        installation: { id: Number(job.installationId) },
        repository: {
          ...repo,
          name: job.repo,
          owner: { id: Number(connection.accountId), login: job.owner },
        },
        pull_request: {
          title: `Revalidate PR #${revision.number} against ${revision.base.ref}`,
          head: { ...revision.head, repo },
          base: { ...revision.base, repo },
        },
      });
      // A replacement uses the ordinary planner and its per-revision job key.
      // Replay this completion after a lost acknowledgement. A later run may
      // need the same base again after a force-push.
      const key = createHash("sha256")
        .update(
          JSON.stringify([github.options.apiBaseUrl, github.options.appId, dispatchId, payload]),
        )
        .digest("hex");
      await enqueue({ deliveryId: `pr-base-${key}`, eventType: "pull_request", payload });
      return;
    }
  }
  // Reservations also have an ordering before a numbered run (e.g. a checkout failure).
  const micros = (latest.createdAt.match(/\.(\d+)/u)?.[1] ?? "").padEnd(6, "0").slice(3, 6);
  const order = BigInt(Date.parse(latest.createdAt)) * 1000n + BigInt(micros);
  const comment = github.postPullRequestResult(
    job,
    connection.accountId,
    order,
    signal,
    (key, work) => store.withPullRequestCommentLease(key, signal, work),
    async (previous, files) => {
      if (latest.outcome === "success" && !previous && latest.checkRunId) return null;
      const current = await store.pullRequestCommentExecution(jobId);
      if (current.latest?.id !== dispatchId || current.job?.status !== job.status) return null;
      if (latest.outcome === "success")
        return (
          resolvedPullRequestComment(job, latest.checkRunId, previous) ??
          (latest.checkRunId
            ? null
            : successfulPullRequestComment(job, github.options.dashboardOrigin))
        );
      const logs = latest.runId
        ? await store.pullRequestFailureLog(jobId, latest.runId)
        : undefined;
      return failedPullRequestComment(job, latest, logs, files, github.options.dashboardOrigin);
    },
    [job.workflowJobKey ?? "", job.matrixLabel ?? ""],
  );
  // A local merge can finish before GitHub creates the matching commit. Retry
  // the check after releasing the worker, pinned to the base the run actually tested.
  const reconcile = async () => {
    if (
      latest.checkRunId ||
      !latest.runId ||
      !latest.pullRequestBaseSha ||
      !latest.pullRequestBaseBranch
    )
      return;
    const runId = latest.runId;
    await store.withPullRequestCommentLease(`check:${dispatchId}`, signal, async (renew) => {
      const isCurrent = async () => {
        const current = await store.pullRequestCommentExecution(jobId);
        return (
          current.latest?.id === dispatchId &&
          !current.latest.checkRunId &&
          current.job?.status === job.status
        );
      };
      if (!(await isCurrent())) return;
      const id = await github.check(
        job,
        latest,
        latest.outcome as "success" | "failure" | "timed_out",
        {
          accountId: connection.accountId,
          retryPending: true,
          signal,
          beforeWrite: async () => {
            await renew();
            if (!(await isCurrent()))
              throw new Error("Pull request run changed before check publication");
          },
        },
      );
      if (id) await store.completedCheck(dispatchId, jobId, runId, id);
    });
  };
  const [checkResult, commentResult] = await Promise.allSettled([reconcile(), comment]);
  if (checkResult.status === "rejected") throw checkResult.reason;
  if (commentResult.status === "rejected") throw commentResult.reason;
}

export const reportPullRequestBuildResult = onMutationExecuted(
  {
    serviceAccount: dispatchServiceAccount,
    region: "asia-northeast1",
    service: dataConnectServiceId(),
    connector: "dispatch",
    operation: "CompleteBuildExecution",
    secrets: [defineSecret("GITHUB_APP_PRIVATE_KEY")],
    timeoutSeconds: 120,
    retry: true,
  },
  async (event) => {
    try {
      if (event.authType !== "admin") throw new Error("Unexpected mutation principal");
      const { errors, data, variables } = event.data.payload;
      if (
        errors?.length ||
        !data ||
        typeof data !== "object" ||
        !("completed" in data) ||
        data.completed !== 1
      )
        return;
      if (
        !variables ||
        typeof variables !== "object" ||
        !("jobId" in variables) ||
        !validJobId(variables.jobId) ||
        !("id" in variables) ||
        !validJobId(variables.id)
      )
        throw new Error("Invalid completed execution");
      await reportCompletedPullRequest(
        variables.jobId,
        variables.id,
        new ExecutionStore(getDispatchDataConnect()),
        buildGitHub(),
        (delivery) => enqueueWebhook(isolatedConnector(webhooksConnector), delivery),
      );
    } catch (cause) {
      // Installation removal and insufficient App permissions are permanent for this
      // event. Rate limits and ambiguous writes are retried with the same marker.
      const status =
        cause instanceof Error && "request" in cause && "status" in cause
          ? Number(cause.status)
          : null;
      if (
        status === 404 ||
        status === 410 ||
        ((status === 403 || status === 422) &&
          cause instanceof Error &&
          /resource not accessible|permissions? requested|not (?:accessible|permitted)|insufficient permission/iu.test(
            cause.message,
          ))
      ) {
        warn("Pull request comment unavailable", { eventId: event.id, status });
        return;
      }
      error("Pull request comment publication failed", { eventId: event.id, status });
      throw new Error("Pull request comment publication requires retry");
    }
  },
);
