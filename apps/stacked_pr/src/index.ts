import { onRequest } from "firebase-functions/v2/https";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { defineSecret, defineString } from "firebase-functions/params";
import { required } from "./config.js";
import { workerParallelism, workerTimeoutSeconds } from "./limits.js";
import { TaskQueue, region } from "./queue.js";
import { processTask, runJob } from "./runtime.js";
import { createWebhookHandler } from "./webhook.js";

const webhookSecret = defineSecret("STACKED_PR_WEBHOOK_SECRET");
const privateKey = defineSecret("STACKED_PR_GITHUB_PRIVATE_KEY");
const runtimeAccount = defineString("STACKED_PR_RUNTIME_SERVICE_ACCOUNT");
// TaskQueueOptions.invoker accepts literal accounts, not parameter expressions.
// Firebase CLI loads .env.<project-id> before discovering these functions.
const taskAccount = required(process.env, "STACKED_PR_TASK_SERVICE_ACCOUNT");
let webhookHandler: ReturnType<typeof createWebhookHandler> | undefined;

export const stackedPrWebhook = onRequest(
  {
    region,
    serviceAccount: runtimeAccount,
    secrets: [webhookSecret],
    invoker: "public",
    memory: "256MiB",
    cpu: 1,
    timeoutSeconds: 30,
    concurrency: 20,
    minInstances: 0,
    maxInstances: 3,
  },
  async (request, response) => {
    webhookHandler ??= createWebhookHandler(
      (job) => TaskQueue.fromEnvironment(process.env).enqueue(job),
      webhookSecret.value(),
      undefined,
      process.env.STACKED_PR_BOT_LOGIN,
    );
    await webhookHandler(request, response);
  },
);

export const stackedPrWorker = onTaskDispatched<unknown>(
  {
    region,
    serviceAccount: runtimeAccount,
    secrets: [privateKey],
    invoker: [taskAccount],
    memory: "2GiB",
    cpu: 1,
    timeoutSeconds: workerTimeoutSeconds,
    concurrency: 1,
    minInstances: 0,
    maxInstances: workerParallelism,
    retryConfig: {
      maxAttempts: 8,
      minBackoffSeconds: 30,
      maxBackoffSeconds: 300,
      maxDoublings: 4,
      maxRetrySeconds: 3600,
    },
    rateLimits: {
      maxConcurrentDispatches: workerParallelism,
      maxDispatchesPerSecond: workerParallelism,
    },
  },
  (request) =>
    processTask(request.data, (job) =>
      runJob(job, {
        ...process.env,
        GITHUB_APP_PRIVATE_KEY: privateKey.value(),
      }),
    ),
);
