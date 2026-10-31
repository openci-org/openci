import { getDataConnect } from "firebase-admin/data-connect";
import { error } from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { connectorConfig } from "@openci/github-admin";
import { connectionConfig } from "./github_connection/config.js";
import { ConnectionError, OctokitConnectionClient } from "./github_connection/github.js";
import { GitHubConnections } from "./github_connection/service.js";
import { GitHubConnectionStore } from "./github_connection/store.js";
import { GitHubCredentialVault } from "./github_connection/vault.js";
import { apiServiceAccount } from "./function_identity.js";

const clientSecret = defineSecret("GITHUB_APP_CLIENT_SECRET");
let service: GitHubConnections | undefined;
function runtime(): GitHubConnections {
  if (!service) {
    const config = connectionConfig(process.env);
    service = new GitHubConnections(
      config,
      new GitHubConnectionStore(getDataConnect(connectorConfig), config),
      new GitHubCredentialVault(
        process.env.SECRET_MANAGER_PROJECT ?? process.env.GCLOUD_PROJECT ?? "",
      ),
      new OctokitConnectionClient(config),
      (reason) => error("GitHub connection operation failed", { reason }),
    );
  }
  return service;
}

const options = {
  serviceAccount: apiServiceAccount,
  region: "asia-northeast1",
  memory: "256MiB" as const,
  cpu: 1,
  concurrency: 1,
  minInstances: 0,
  timeoutSeconds: 300,
  secrets: [clientSecret],
};

export const githubConnection = onCall(options, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous")
    throw new HttpsError("unauthenticated", "Sign in to connect GitHub");
  try {
    return await runtime().execute(request.auth.uid, request.data);
  } catch (cause) {
    if (cause instanceof ConnectionError) throw new HttpsError(cause.code, cause.message);
    // Do not serialize SDK exceptions: they may include OAuth tokens or variables.
    error("GitHub connection operation failed");
    throw new HttpsError("unavailable", "GitHub connection failed; try again");
  }
});

export const githubConnectionCallback = onRequest(
  { ...options, invoker: "public" },
  async (request, response) => {
    response.set({ "Cache-Control": "no-store", "Referrer-Policy": "no-referrer" });
    if (request.method !== "GET") {
      response.status(405).send("Method not allowed");
      return;
    }
    try {
      const parameters = new URL(request.originalUrl, "https://callback.invalid").searchParams;
      response.redirect(303, await runtime().callback(parameters));
    } catch {
      error("GitHub connection callback is unavailable");
      response
        .status(503)
        .send("GitHub connection is unavailable. Please restart from the dashboard.");
    }
  },
);

export const cleanGitHubConnectionCredentials = onSchedule(
  { ...options, schedule: "every 5 minutes", maxInstances: 1 },
  async () => {
    try {
      await runtime().cleanup();
    } catch {
      error("GitHub connection cleanup failed");
      throw new Error("GitHub connection cleanup failed");
    }
  },
);
