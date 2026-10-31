import { validateAdminArgs } from "firebase-admin/data-connect";

export const connectorConfig = {
  connector: "logs",
  serviceId: "openci-b1b91-service",
  location: "asia-northeast1",
};

export function appendBuildLog(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("AppendBuildLog", inputVars, inputOpts);
}

export function getBuildLogs(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildLogs", inputVars, inputOpts);
}

export function getBuildLogWriteState(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildLogWriteState", inputVars, inputOpts);
}

export function getBuildStepWriteState(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildStepWriteState", inputVars, inputOpts);
}

export function getBuildLogState(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildLogState", inputVars, inputOpts);
}

export function getExpiredBuildLogs(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetExpiredBuildLogs", undefined, inputOpts);
}

export function deleteExpiredBuildLogs(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("DeleteExpiredBuildLogs", inputVars, inputOpts);
}

export function createBuildStep(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CreateBuildStep", inputVars, inputOpts);
}

export function updateBuildStep(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("UpdateBuildStep", inputVars, inputOpts);
}
