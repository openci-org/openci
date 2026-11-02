import { onMutationExecuted } from "firebase-functions/dataconnect";
import { error } from "firebase-functions/logger";
import { defineSecret, defineString } from "firebase-functions/params";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { dataConnectServiceId } from "./data_connect_config.js";
import { apiServiceAccount } from "./function_identity.js";
import { ExecutionGitHub, githubOptions } from "./executor/github.js";
import { DataConnectSkippedCheckStore } from "./skipped_check_store.js";
import {
  createdSkippedCheckIds,
  recoverSkippedChecks,
  reportSkippedCheck,
} from "./skipped_checks.js";

const githubPrivateKey = defineSecret("GITHUB_APP_PRIVATE_KEY");
const githubAppId = defineString("GITHUB_APP_ID");
const githubApiBaseUrl = defineString("GITHUB_API_BASE_URL", { default: "https://api.github.com" });
const githubBaseUrl = defineString("GITHUB_BASE_URL", { default: "https://github.com" });

function dependencies() {
  const github = new ExecutionGitHub(
    githubOptions({
      appId: githubAppId.value(),
      privateKey: githubPrivateKey.value(),
      apiBaseUrl: githubApiBaseUrl.value(),
      baseUrl: githubBaseUrl.value(),
    }),
  );
  return {
    store: new DataConnectSkippedCheckStore(),
    report: github.skippedCheck.bind(github),
  };
}

const options = {
  serviceAccount: apiServiceAccount,
  region: "asia-northeast1",
  memory: "256MiB" as const,
  cpu: 1,
  concurrency: 1,
  minInstances: 0,
  timeoutSeconds: 540,
  secrets: [githubPrivateKey],
};

export const reportSkippedWorkflowChecks = onMutationExecuted(
  {
    ...options,
    service: dataConnectServiceId(),
    connector: "webhooks",
    operation: "CompleteWebhookTask",
    retry: true,
  },
  async (event) => {
    try {
      if (event.authType !== "admin") throw new Error("Unexpected mutation principal");
      const ids = createdSkippedCheckIds(event.data.payload);
      if (!ids.length) return;
      const deps = dependencies();
      const deadline = Date.now() + 240000;
      for (const id of ids) {
        if (Date.now() >= deadline) throw new Error("Skipped Check reporting budget exhausted");
        await reportSkippedCheck(id, deps);
      }
    } catch {
      error("Skipped Check reporting failed", { eventId: event.id });
      throw new Error("Skipped Check reporting failed; retry required");
    }
  },
);

export const recoverSkippedWorkflowChecks = onSchedule(
  { ...options, schedule: "every 1 minutes", maxInstances: 1 },
  async () => {
    try {
      await recoverSkippedChecks(dependencies(), (id) =>
        error("Skipped Check retry failed", { id }),
      );
    } catch {
      error("Skipped Check recovery failed");
      throw new Error("Skipped Check recovery failed");
    }
  },
);
