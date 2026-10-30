import { initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import { error } from "firebase-functions/logger";
import { defineSecret, defineString } from "firebase-functions/params";
import { onMutationExecuted } from "firebase-functions/dataconnect";
import { onRequest } from "firebase-functions/v2/https";
import { connectorConfig } from "@openci/webhooks-admin";
import { receiveGitHubWebhook } from "./github_webhook.js";
import { enqueueWebhook } from "./webhook_queue.js";
import { invokeProcessWebhookTask, requestedWebhookTaskId } from "./build_job_planning.js";

initializeApp();
const githubWebhookSecret = defineSecret("GITHUB_WEBHOOK_SECRET");
const processWebhookTaskUrl = defineString("PROCESS_WEBHOOK_TASK_URL");

export { queueBuildJobs, dispatchBuildJob } from "./build_dispatch_functions.js";
export { recoverBuildExecutions } from "./build_recovery_functions.js";
export { expireBuildLogs } from "./log_retention_functions.js";

export const githubWebhook = onRequest(
  {
    region: "asia-northeast1",
    invoker: "public",
    memory: "128MiB",
    cpu: 1,
    concurrency: 1,
    minInstances: 0,
    timeoutSeconds: 60,
    secrets: [githubWebhookSecret],
  },
  async (request, response) => {
    const status = await receiveGitHubWebhook(request, {
      secret: githubWebhookSecret.value(),
      enqueue: (delivery) => enqueueWebhook(getDataConnect(connectorConfig), delivery),
      reportError: (context) => error("GitHub webhook could not be persisted", context),
    });
    response.sendStatus(status);
  },
);

export const createBuildJobs = onMutationExecuted(
  {
    region: "asia-northeast1",
    service: "openci-b1b91-service",
    connector: "webhooks",
    operation: "RequestWebhookTaskPlanning",
    memory: "128MiB",
    cpu: 1,
    concurrency: 1,
    minInstances: 0,
    timeoutSeconds: 540,
    retry: true,
  },
  async (event) => {
    let taskId: string | null = null;
    try {
      if (event.authType !== "admin") throw new Error("Unexpected webhook task principal");
      taskId = requestedWebhookTaskId(event.data.payload);
      if (!taskId) return;
      await invokeProcessWebhookTask(processWebhookTaskUrl.value(), taskId);
    } catch {
      // SDK and HTTP errors can include tokens, private source and variables.
      error("Build job planning failed", { taskId, eventId: event.id });
      throw new Error("Build job planning failed; retry required");
    }
  },
);

export { teamSecrets, cleanSecretVersions } from "./secret_functions.js";
