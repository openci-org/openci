import { validateAdminArgs } from "firebase-admin/data-connect";

export const connectorConfig = {
  connector: "dispatch",
  serviceId: "openci-b1b91-service",
  location: "asia-northeast1",
};

export function getBuildDispatchState(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildDispatchState", inputVars, inputOpts);
}

export function getBuildJobDispatch(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildJobDispatch", inputVars, inputOpts);
}

export function getActiveBuildDispatches(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetActiveBuildDispatches", undefined, inputOpts);
}

export function initializeBuildDispatchScheduler(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeMutation("InitializeBuildDispatchScheduler", undefined, inputOpts);
}

export function acquireBuildDispatchScheduler(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("AcquireBuildDispatchScheduler", inputVars, inputOpts);
}

export function releaseBuildDispatchScheduler(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ReleaseBuildDispatchScheduler", inputVars, inputOpts);
}

export function reserveBuildJobDispatch(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ReserveBuildJobDispatch", inputVars, inputOpts);
}

export function expireUnstartedBuildDispatches(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ExpireUnstartedBuildDispatches", undefined, inputOpts);
}

export function cancelUnstartedBuildDispatch(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CancelUnstartedBuildDispatch", inputVars, inputOpts);
}

export function acquireBuildDispatchLaunch(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("AcquireBuildDispatchLaunch", inputVars, inputOpts);
}

export function recordBuildDispatchLaunch(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("RecordBuildDispatchLaunch", inputVars, inputOpts);
}

export function claimBuildJobExecution(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ClaimBuildJobExecution", inputVars, inputOpts);
}

export function finishBuildJobDispatch(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("FinishBuildJobDispatch", inputVars, inputOpts);
}
