const { validateAdminArgs } = require("firebase-admin/data-connect");

const connectorConfig = {
  connector: "dispatch",
  serviceId: "openci-b1b91-service",
  location: "asia-northeast1",
};
exports.connectorConfig = connectorConfig;

function getBuildDispatchState(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildDispatchState", inputVars, inputOpts);
}
exports.getBuildDispatchState = getBuildDispatchState;

function getBuildJobDispatch(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildJobDispatch", inputVars, inputOpts);
}
exports.getBuildJobDispatch = getBuildJobDispatch;

function getActiveBuildDispatches(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetActiveBuildDispatches", undefined, inputOpts);
}
exports.getActiveBuildDispatches = getActiveBuildDispatches;

function initializeBuildDispatchScheduler(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeMutation("InitializeBuildDispatchScheduler", undefined, inputOpts);
}
exports.initializeBuildDispatchScheduler = initializeBuildDispatchScheduler;

function acquireBuildDispatchScheduler(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("AcquireBuildDispatchScheduler", inputVars, inputOpts);
}
exports.acquireBuildDispatchScheduler = acquireBuildDispatchScheduler;

function releaseBuildDispatchScheduler(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ReleaseBuildDispatchScheduler", inputVars, inputOpts);
}
exports.releaseBuildDispatchScheduler = releaseBuildDispatchScheduler;

function reserveBuildJobDispatch(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ReserveBuildJobDispatch", inputVars, inputOpts);
}
exports.reserveBuildJobDispatch = reserveBuildJobDispatch;

function expireUnstartedBuildDispatches(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ExpireUnstartedBuildDispatches", undefined, inputOpts);
}
exports.expireUnstartedBuildDispatches = expireUnstartedBuildDispatches;

function cancelUnstartedBuildDispatch(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CancelUnstartedBuildDispatch", inputVars, inputOpts);
}
exports.cancelUnstartedBuildDispatch = cancelUnstartedBuildDispatch;

function acquireBuildDispatchLaunch(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("AcquireBuildDispatchLaunch", inputVars, inputOpts);
}
exports.acquireBuildDispatchLaunch = acquireBuildDispatchLaunch;

function recordBuildDispatchLaunch(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("RecordBuildDispatchLaunch", inputVars, inputOpts);
}
exports.recordBuildDispatchLaunch = recordBuildDispatchLaunch;

function claimBuildJobExecution(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ClaimBuildJobExecution", inputVars, inputOpts);
}
exports.claimBuildJobExecution = claimBuildJobExecution;

function finishBuildJobDispatch(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("FinishBuildJobDispatch", inputVars, inputOpts);
}
exports.finishBuildJobDispatch = finishBuildJobDispatch;
