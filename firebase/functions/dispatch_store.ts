import { getApp, getApps, initializeApp, type App } from "firebase-admin/app";
import { getDataConnect, type DataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/dispatch-admin";
import type { BuildDispatch, DispatchState, DispatchStore } from "./build_dispatch.js";

export function getDispatchDataConnect(app: App = getApp()): DataConnect {
  // Admin SDK 14.5 caches by service/location, ignoring the connector ID.
  // A dedicated app keeps webhook and dispatch calls separate in one process.
  const name = `${app.name}:build-dispatch`;
  const isolated =
    getApps().find((candidate) => candidate.name === name) ?? initializeApp(app.options, name);
  return getDataConnect(sdk.connectorConfig, isolated);
}

export class DataConnectDispatchStore implements DispatchStore {
  constructor(private readonly dc: DataConnect) {}
  async expireUnstarted(): Promise<void> {
    await sdk.expireUnstartedBuildDispatches(this.dc);
  }
  async cancelUnstarted(jobId: string): Promise<void> {
    await sdk.cancelUnstartedBuildDispatch(this.dc, { jobId });
  }
  async read(jobId: string): Promise<DispatchState> {
    return (await sdk.getBuildDispatchState(this.dc, { jobId })).data;
  }
  async active(): Promise<BuildDispatch[]> {
    return (await sdk.getActiveBuildDispatches(this.dc)).data.dispatches;
  }
  async acquireScheduler(owner: string): Promise<boolean> {
    await sdk.initializeBuildDispatchScheduler(this.dc);
    return (await sdk.acquireBuildDispatchScheduler(this.dc, { owner })).data.acquired === 1;
  }
  async releaseScheduler(owner: string): Promise<void> {
    await sdk.releaseBuildDispatchScheduler(this.dc, { owner });
  }
  async reserve(owner: string, dispatch: Omit<BuildDispatch, "startDeadline">): Promise<void> {
    await sdk.reserveBuildJobDispatch(this.dc, {
      owner,
      id: dispatch.id,
      jobId: dispatch.jobId,
      vmName: dispatch.vmName,
      cpu: dispatch.cpu,
      memoryMiB: dispatch.memoryMiB,
      image: dispatch.image,
      cloudRunJob: dispatch.cloudRunJob,
    });
  }
  async acquireLaunch(id: string, owner: string): Promise<boolean> {
    return (await sdk.acquireBuildDispatchLaunch(this.dc, { id, owner })).data.acquired === 1;
  }
  async recordLaunch(id: string, owner: string, operationName: string): Promise<void> {
    await sdk.recordBuildDispatchLaunch(this.dc, { id, owner, operationName });
  }
}
