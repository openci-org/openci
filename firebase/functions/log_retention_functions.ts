import { onSchedule } from "firebase-functions/v2/scheduler";
import * as sdk from "@openci/logs-admin";
import { isolatedConnector } from "./executor/store.js";
import { deleteExpiredLogs } from "./log_retention.js";
import { apiServiceAccount } from "./function_identity.js";

export const expireBuildLogs = onSchedule(
  {
    serviceAccount: apiServiceAccount,
    region: "asia-northeast1",
    schedule: "every 5 minutes",
    memory: "256MiB",
    cpu: 1,
    minInstances: 0,
    maxInstances: 1,
    concurrency: 1,
    timeoutSeconds: 120,
  },
  async () => {
    const dc = isolatedConnector(sdk.connectorConfig);
    await deleteExpiredLogs({
      expired: async () =>
        (await sdk.getExpiredBuildLogs(dc)).data.runs.map((run) => ({
          id: run.id,
          logs: run.expiredLogs,
        })),
      deleteThrough: async (runId, throughSequence) => {
        await sdk.deleteExpiredBuildLogs(dc, { runId, throughSequence });
      },
    });
  },
);
