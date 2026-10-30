import { error as reportError } from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as sdk from "@openci/secrets-admin";
import { isolatedConnector } from "./executor/store.js";
import { TeamSecrets, SecretError } from "./secrets/service.js";
import { ManagedSecretStore } from "./secrets/store.js";
import { ManagedSecretVault } from "./secrets/vault.js";

let cachedRuntime: ReturnType<typeof createRuntime> | undefined;
function runtime() {
  return (cachedRuntime ??= createRuntime());
}
function createRuntime() {
  const dc = isolatedConnector(sdk.connectorConfig);
  const store = new ManagedSecretStore(dc);
  const vault = new ManagedSecretVault(
    process.env.SECRET_MANAGER_PROJECT ?? process.env.GCLOUD_PROJECT ?? "",
  );
  return { dc, store, vault, service: new TeamSecrets(store, vault) };
}

export const teamSecrets = onCall(
  {
    region: "asia-northeast1",
    memory: "128MiB",
    cpu: 1,
    minInstances: 0,
    concurrency: 1,
    timeoutSeconds: 60,
  },
  async (request) => {
    if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous")
      throw new HttpsError("unauthenticated", "Sign in to manage secrets");
    try {
      return await runtime().service.execute(request.auth.uid, request.data);
    } catch (error) {
      if (error instanceof SecretError) throw new HttpsError(error.code, error.message);
      // Never serialize SDK errors, operation variables or secret values.
      throw new HttpsError("unavailable", "Secret operation failed; try again");
    }
  },
);

export const cleanSecretVersions = onSchedule(
  {
    region: "asia-northeast1",
    schedule: "every 60 minutes",
    memory: "128MiB",
    cpu: 1,
    minInstances: 0,
    maxInstances: 1,
    concurrency: 1,
    timeoutSeconds: 300,
  },
  async () => {
    const { dc, store, vault } = runtime();
    for (const { path } of (await sdk.getDueSecretVersions(dc)).data.versions) {
      try {
        if ((await sdk.getSecretVersionReferences(dc, { path })).data.references.length) {
          await store.queue(path);
        } else {
          await vault.destroy(path);
          await sdk.completeSecretVersionCleanup(dc, { path });
        }
      } catch {
        reportError("Secret version cleanup failed");
        // Rotate failing entries so they cannot starve the remaining backlog.
        await store.queue(path);
      }
    }
  },
);
