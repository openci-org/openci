import { getDataConnect, type DataConnect } from "firebase-admin/data-connect";
import {
  connectorConfig,
  claimSkippedWorkflowCheck,
  completeSkippedWorkflowCheck,
  getPendingSkippedWorkflowChecks,
  getSkippedWorkflowCheck,
  retrySkippedWorkflowCheck,
} from "@openci/webhooks-admin";
import { configuredConnector } from "./data_connect_config.js";
import type { SkippedCheckStore } from "./skipped_checks.js";

export class DataConnectSkippedCheckStore implements SkippedCheckStore {
  constructor(readonly dc: DataConnect = getDataConnect(configuredConnector(connectorConfig))) {}

  async claim(id: string, leaseOwner: string) {
    return (await claimSkippedWorkflowCheck(this.dc, { id, leaseOwner })).data.claimed === 1;
  }
  async get(id: string) {
    return (await getSkippedWorkflowCheck(this.dc, { id })).data.check ?? null;
  }
  async complete(id: string, leaseOwner: string, checkRunId: string) {
    await completeSkippedWorkflowCheck(this.dc, { id, leaseOwner, checkRunId });
  }
  async retry(id: string, leaseOwner: string) {
    await retrySkippedWorkflowCheck(this.dc, { id, leaseOwner });
  }
  async pending() {
    return (await getPendingSkippedWorkflowChecks(this.dc)).data.checks.map((check) => check.id);
  }
}
