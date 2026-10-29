import { initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import { error } from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { onRequest } from "firebase-functions/v2/https";
import { connectorConfig } from "@openci/webhooks-admin";
import { receiveGitHubWebhook } from "./github_webhook.js";
import { enqueueWebhook } from "./webhook_queue.js";

initializeApp();
const githubWebhookSecret = defineSecret("GITHUB_WEBHOOK_SECRET");

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
