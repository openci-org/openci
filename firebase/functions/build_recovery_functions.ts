import { error } from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { recoverExecutions } from "./executor/execute.js";
import { runtime } from "./executor/runtime.js";
import { orchardNetworkOptions } from "./orchard_network.js";
import { recoveryServiceAccount } from "./function_identity.js";

const orchardToken = defineSecret("ORCHARD_SERVICE_ACCOUNT_TOKEN");
const githubPrivateKey = defineSecret("GITHUB_APP_PRIVATE_KEY");

export const recoverBuildExecutions = onSchedule(
  {
    ...orchardNetworkOptions,
    serviceAccount: recoveryServiceAccount,
    region: "asia-northeast1",
    schedule: "every 1 minutes",
    memory: "256MiB",
    cpu: 1,
    concurrency: 1,
    minInstances: 0,
    maxInstances: 1,
    timeoutSeconds: 300,
    secrets: [orchardToken, githubPrivateKey],
  },
  async () => {
    try {
      await recoverExecutions(
        runtime(process.env, (reason, dispatchId) =>
          error("Build execution recovery", { reason, dispatchId }),
        ),
        180000,
      );
    } catch {
      error("Build execution recovery failed");
      throw new Error("Build execution recovery failed");
    }
  },
);
