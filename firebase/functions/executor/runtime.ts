import { GoogleAuth } from "google-auth-library";
import { getApp, getApps, initializeApp } from "firebase-admin/app";
import { connectorConfig as dispatchConfig } from "@openci/dispatch-admin";
import { connectorConfig as billingConfig } from "@openci/billing-admin";
import { connectorConfig as logsConfig } from "@openci/logs-admin";
import { ExecutionStore, isolatedConnector } from "./store.js";
import { ExecutionBilling } from "./billing.js";
import { ExecutionGitHub } from "./github.js";
import { ExecutionLogs } from "./logs.js";
import { OrchardExecutor } from "./orchard.js";
import { loadSecrets, stopCloudRunExecution } from "./google.js";
import type { ExecutorDependencies } from "./execute.js";
import { ExecutionStopped, identity } from "./model.js";
import { selfHostedMode } from "../deployment_mode.js";

export function runtime(
  environment: NodeJS.ProcessEnv,
  report: ExecutorDependencies["report"],
): ExecutorDependencies {
  const required = (key: string) => {
    const value = environment[key];
    if (!value) throw new Error(`Missing ${key}`);
    return value;
  };
  const project = environment.GCLOUD_PROJECT ?? required("GOOGLE_CLOUD_PROJECT");
  const selfHosted = selfHostedMode(environment);
  const useWorkerMemory = environment.ORCHARD_USE_WORKER_MEMORY ?? "false";
  if (!["true", "false"].includes(useWorkerMemory)) throw new Error("Invalid worker memory mode");
  const cloudRunJob = required("BUILD_EXECUTOR_JOB");
  if (!/^projects\/[a-z0-9-]+\/locations\/[a-z0-9-]+\/jobs\/[a-z][a-z0-9-]*$/.test(cloudRunJob))
    throw new Error("Invalid Cloud Run job name");
  const timeoutSeconds = Number(environment.BUILD_EXECUTOR_TIMEOUT_SECONDS ?? 3600);
  if (!Number.isSafeInteger(timeoutSeconds) || timeoutSeconds < 60 || timeoutSeconds > 86400)
    throw new Error("Invalid build timeout");
  if (!selfHosted && !["true", "false"].includes(required("BILLING_STRIPE_LIVEMODE")))
    throw new Error("Billing mode must be explicit");
  if (
    environment.DATA_CONNECT_EMULATOR_HOST &&
    (!project.startsWith("demo-") ||
      !/^(127\.0\.0\.1|localhost):\d+$/.test(environment.DATA_CONNECT_EMULATOR_HOST))
  )
    throw new Error("Emulator requires a local demo project");
  const app = getApps().some((app) => app.name === "[DEFAULT]")
    ? getApp()
    : initializeApp({ projectId: project });
  const store = new ExecutionStore(isolatedConnector(dispatchConfig, app));
  const billing = new ExecutionBilling(isolatedConnector(billingConfig, app));
  const auth = new GoogleAuth();
  const eligibilityUrl = `https://asia-northeast1-${project}.cloudfunctions.net/ciCardEligibility`;
  const logs = isolatedConnector(logsConfig, app);
  const github = new ExecutionGitHub({
    appId: required("GITHUB_APP_ID"),
    privateKey: required("GITHUB_APP_PRIVATE_KEY"),
    apiBaseUrl: environment.GITHUB_API_BASE_URL ?? "https://api.github.com",
    billingOrigin: environment.BILLING_DASHBOARD_ORIGIN,
    baseUrl: environment.GITHUB_BASE_URL ?? "https://github.com",
  });
  const orchard = new OrchardExecutor({
    url: required("ORCHARD_API_URL"),
    account: required("ORCHARD_SERVICE_ACCOUNT_NAME"),
    token: required("ORCHARD_SERVICE_ACCOUNT_TOKEN"),
    ca: environment.ORCHARD_CA_CERT,
    useWorkerMemory: useWorkerMemory === "true",
  });
  return {
    store,
    billing,
    async verifyCard(teamId, livemode) {
      try {
        const client = await auth.getIdTokenClient(eligibilityUrl);
        const { data } = await client.request<{ sessionId: unknown }>({
          url: eligibilityUrl,
          method: "POST",
          data: { teamId, livemode },
          timeout: 30000,
          retry: false,
          maxRedirects: 0,
        });
        if (data.sessionId === null) return null;
        if (typeof data.sessionId !== "string" || !data.sessionId)
          throw new Error("Invalid billing response");
        return data.sessionId;
      } catch {
        // A temporary verification failure keeps the job queued for the normal retry.
        throw new ExecutionStopped("blocked");
      }
    },
    github,
    orchard,
    report,
    configuration: {
      selfHosted,
      cloudRunJob,
      timeoutSeconds,
      livemode: environment.BILLING_STRIPE_LIVEMODE === "true",
      complimentary: new Set(
        (environment.BILLING_COMPLIMENTARY_PRO_TEAM_IDS ?? "")
          .split(",")
          .map((value) => value.trim())
          .filter(Boolean),
      ),
    },
    logs: (dispatch) => {
      const attempt = identity(dispatch);
      return new ExecutionLogs(logs, attempt.teamId, attempt.runId);
    },
    secrets: async (teamId, signal) =>
      loadSecrets(
        await store.secrets(teamId),
        environment.SECRET_MANAGER_PROJECT ?? project,
        undefined,
        signal,
      ),
    stopExecution: (dispatch) => stopCloudRunExecution(dispatch, cloudRunJob),
  };
}
