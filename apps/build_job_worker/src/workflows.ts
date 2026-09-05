import { proxyActivities } from "@temporalio/workflow";
import type * as activities from "./activities";

const { EchoActivity } = proxyActivities<typeof activities>({
  startToCloseTimeout: "10s",
  retry: { maximumAttempts: 3 },
});

export async function EchoWorkflow(message: string): Promise<string> {
  return await EchoActivity(message);
}
