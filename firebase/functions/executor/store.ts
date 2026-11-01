import { getApp, getApps, initializeApp, type App } from "firebase-admin/app";
import {
  getDataConnect,
  type ConnectorConfig,
  type DataConnect,
} from "firebase-admin/data-connect";
import * as sdk from "@openci/dispatch-admin";
import { identity, type Dispatch, type Outcome } from "./model.js";
import { configuredConnector } from "../data_connect_config.js";

export function isolatedConnector(config: ConnectorConfig, app: App = getApp()): DataConnect {
  // firebase-admin 14.5 caches by location/service, without the connector ID.
  const name = `${app.name}:executor:${config.connector}`;
  const isolated =
    getApps().find((candidate) => candidate.name === name) ?? initializeApp(app.options, name);
  return getDataConnect(configuredConnector(config), isolated);
}

export class ExecutionStore {
  constructor(readonly dc: DataConnect) {}
  async read(id: string, jobId: string) {
    return (await sdk.getBuildExecution(this.dc, { id, jobId, runId: `run-${id}` })).data;
  }
  async claim(id: string, executorId: string, executionName: string, timeoutSeconds: number) {
    return (
      (await sdk.claimBuildJobExecution(this.dc, { id, executorId, executionName, timeoutSeconds }))
        .data.acquired === 1
    );
  }
  async context(teamId: string, installationId: string, appId: string, apiBaseUrl: string) {
    return (
      await sdk.getBuildExecutorContext(this.dc, { teamId, installationId, appId, apiBaseUrl })
    ).data;
  }
  async configure(dispatch: Dispatch, executorId: string, selfHosted = false): Promise<number> {
    if (selfHosted) {
      try {
        await sdk.startSelfHostedBuildExecution(this.dc, {
          id: dispatch.id,
          jobId: dispatch.jobId,
          teamId: identity(dispatch).teamId,
          executorId,
        });
      } catch {
        // Resolve a duplicate or lost acknowledgement without replacing a run.
        const state = await this.read(dispatch.id, dispatch.jobId);
        if (
          !state.run ||
          state.run.id !== dispatch.runId ||
          state.dispatch?.executorId !== executorId ||
          state.dispatch.state !== "running" ||
          state.dispatch.finishedAt ||
          !state.dispatch.deadlineAt ||
          Date.parse(state.dispatch.deadlineAt) <= Date.now() ||
          state.job?.latestRunId !== dispatch.runId ||
          state.job.status !== "IN_PROGRESS" ||
          state.job.workerHost !== identity(dispatch).workerHost
        )
          throw new Error("Self-hosted run initialization failed");
      }
    }
    try {
      await sdk.configureBuildExecutionRun(this.dc, {
        id: dispatch.id,
        jobId: dispatch.jobId,
        executorId,
      });
    } catch {
      /* Reconcile an ambiguous acknowledgement; never increment twice. */
    }
    const state = await this.read(dispatch.id, dispatch.jobId);
    if (
      !state.run?.runNumber ||
      state.dispatch?.executorId !== executorId ||
      state.job?.latestRunId !== dispatch.runId
    )
      throw new Error("Run configuration failed");
    const runNumber = Number(state.run.runNumber);
    if (!Number.isSafeInteger(runNumber) || runNumber < 1) throw new Error("Invalid run number");
    return runNumber;
  }
  async heartbeat(id: string, executorId: string) {
    return (await sdk.heartbeatBuildExecution(this.dc, { id, executorId })).data.updated === 1;
  }
  async vmRequested(id: string, executorId: string) {
    await sdk.markBuildVmRequested(this.dc, { id, executorId });
  }
  async check(id: string, checkRunId: string) {
    await sdk.recordBuildExecutionCheck(this.dc, { id, checkRunId });
  }
  async result(id: string, executorId: string, outcome: Outcome) {
    return (
      (await sdk.recordBuildExecutionResult(this.dc, { id, executorId, outcome })).data.updated ===
      1
    );
  }
  async recoverable() {
    return (await sdk.getRecoverableBuildExecutions(this.dc)).data.dispatches;
  }
  async finishedForVms(vmNames: string[]) {
    return (await sdk.getFinishedBuildExecutionsForVms(this.dc, { vmNames })).data.dispatches;
  }
  async acquireCleanup(id: string, owner: string) {
    return (await sdk.acquireBuildExecutionCleanup(this.dc, { id, owner })).data.acquired === 1;
  }
  async vmDeleted(id: string, owner: string) {
    await sdk.confirmBuildVmDeleted(this.dc, { id, owner });
  }
  async complete(id: string, jobId: string, owner: string) {
    await sdk.completeBuildExecution(this.dc, { id, jobId, owner });
  }
  async secrets(teamId: string) {
    return (await sdk.getBuildExecutionSecrets(this.dc, { teamId })).data.secrets;
  }
}
