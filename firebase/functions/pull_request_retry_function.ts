import { onMutationExecuted } from "firebase-functions/dataconnect";
import { defineSecret } from "firebase-functions/params";
import { error } from "firebase-functions/logger";
import * as webhooks from "@openci/webhooks-admin";
import { requestedWebhookTaskId } from "./build_job_planning.js";
import { dataConnectServiceId } from "./data_connect_config.js";
import { getDispatchDataConnect } from "./dispatch_store.js";
import { buildGitHub } from "./executor/github.js";
import { hasStatus } from "./executor/pull_request_comment.js";
import { ExecutionStore, isolatedConnector } from "./executor/store.js";
import { dispatchServiceAccount } from "./function_identity.js";
import { retryFromPullRequest } from "./pull_request_retry.js";
import { retryCheckboxClick } from "./pull_request_retry_control.js";

export const retryPullRequestCommentJob = onMutationExecuted(
  {
    serviceAccount: dispatchServiceAccount,
    region: "asia-northeast1",
    service: dataConnectServiceId(),
    connector: "webhooks",
    operation: "RequestPullRequestCommentRetry",
    timeoutSeconds: 120,
    retry: true,
    secrets: [defineSecret("GITHUB_APP_PRIVATE_KEY")],
  },
  async (event) => {
    try {
      if (event.authType !== "admin") throw new Error("Unexpected webhook task principal");
      const id = requestedWebhookTaskId(event.data.payload);
      if (!id) return;
      const dc = isolatedConnector(webhooks.connectorConfig);
      const { webhookTask: task } = (await webhooks.getWebhookTask(dc, { id })).data;
      if (task?.status !== "pending" || task.eventType !== "issue_comment") return;
      const click = retryCheckboxClick(JSON.parse(task.payload));
      if (click) {
        try {
          await retryFromPullRequest(
            click,
            new ExecutionStore(getDispatchDataConnect()),
            buildGitHub(),
          );
        } catch (failure) {
          // The comment, repository or installation may have been removed.
          if (!(failure instanceof Error && "request" in failure && hasStatus(failure, 404, 410)))
            throw failure;
        }
      }
      await webhooks.finishPullRequestCommentRetry(dc, { id });
    } catch {
      error("Pull request comment retry could not be processed", { eventId: event.id });
      throw new Error("Pull request comment retry requires redelivery");
    }
  },
);
