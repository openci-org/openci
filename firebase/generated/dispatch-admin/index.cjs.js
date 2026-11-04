const { validateAdminArgs } = require("firebase-admin/data-connect");

const connectorConfig = {
  connector: "dispatch",
  serviceId: "openci-b1b91-service",
  location: "asia-northeast1",
};
exports.connectorConfig = connectorConfig;

function getQueuedBuildCheck(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetQueuedBuildCheck", inputVars, inputOpts);
}
exports.getQueuedBuildCheck = getQueuedBuildCheck;

function acquireQueuedBuildCheck(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("AcquireQueuedBuildCheck", inputVars, inputOpts);
}
exports.acquireQueuedBuildCheck = acquireQueuedBuildCheck;

function recordQueuedBuildCheck(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("RecordQueuedBuildCheck", inputVars, inputOpts);
}
exports.recordQueuedBuildCheck = recordQueuedBuildCheck;

function releaseQueuedBuildCheck(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ReleaseQueuedBuildCheck", inputVars, inputOpts);
}
exports.releaseQueuedBuildCheck = releaseQueuedBuildCheck;

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

function getBuildDispatchExclusions(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildDispatchExclusions", undefined, inputOpts);
}
exports.getBuildDispatchExclusions = getBuildDispatchExclusions;

function getOldestQueuedBuildJob(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetOldestQueuedBuildJob", inputVars, inputOpts);
}
exports.getOldestQueuedBuildJob = getOldestQueuedBuildJob;

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

function getSupersededBuildJobs(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetSupersededBuildJobs", inputVars, inputOpts);
}
exports.getSupersededBuildJobs = getSupersededBuildJobs;

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

function getBuildExecution(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildExecution", inputVars, inputOpts);
}
exports.getBuildExecution = getBuildExecution;

function getBuildExecutorContext(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildExecutorContext", inputVars, inputOpts);
}
exports.getBuildExecutorContext = getBuildExecutorContext;

function getBuildExecutionSecrets(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildExecutionSecrets", inputVars, inputOpts);
}
exports.getBuildExecutionSecrets = getBuildExecutionSecrets;

function startSelfHostedBuildExecution(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("StartSelfHostedBuildExecution", inputVars, inputOpts);
}
exports.startSelfHostedBuildExecution = startSelfHostedBuildExecution;

function configureBuildExecutionRun(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ConfigureBuildExecutionRun", inputVars, inputOpts);
}
exports.configureBuildExecutionRun = configureBuildExecutionRun;

function heartbeatBuildExecution(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("HeartbeatBuildExecution", inputVars, inputOpts);
}
exports.heartbeatBuildExecution = heartbeatBuildExecution;

function markBuildVmRequested(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("MarkBuildVmRequested", inputVars, inputOpts);
}
exports.markBuildVmRequested = markBuildVmRequested;

function recordBuildExecutionCheck(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("RecordBuildExecutionCheck", inputVars, inputOpts);
}
exports.recordBuildExecutionCheck = recordBuildExecutionCheck;

function recordBuildExecutionResult(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("RecordBuildExecutionResult", inputVars, inputOpts);
}
exports.recordBuildExecutionResult = recordBuildExecutionResult;

function getRecoverableBuildExecutions(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetRecoverableBuildExecutions", undefined, inputOpts);
}
exports.getRecoverableBuildExecutions = getRecoverableBuildExecutions;

function getFinishedBuildExecutionsForVms(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetFinishedBuildExecutionsForVms", inputVars, inputOpts);
}
exports.getFinishedBuildExecutionsForVms = getFinishedBuildExecutionsForVms;

function acquireBuildExecutionCleanup(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("AcquireBuildExecutionCleanup", inputVars, inputOpts);
}
exports.acquireBuildExecutionCleanup = acquireBuildExecutionCleanup;

function confirmBuildVmDeleted(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ConfirmBuildVmDeleted", inputVars, inputOpts);
}
exports.confirmBuildVmDeleted = confirmBuildVmDeleted;

function completeBuildExecution(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CompleteBuildExecution", inputVars, inputOpts);
}
exports.completeBuildExecution = completeBuildExecution;

function reserveBuildDispatchRetry(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ReserveBuildDispatchRetry", inputVars, inputOpts);
}
exports.reserveBuildDispatchRetry = reserveBuildDispatchRetry;

function consumeBuildDispatchRetry(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ConsumeBuildDispatchRetry", inputVars, inputOpts);
}
exports.consumeBuildDispatchRetry = consumeBuildDispatchRetry;

function getPendingBuildDispatchWork(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetPendingBuildDispatchWork", undefined, inputOpts);
}
exports.getPendingBuildDispatchWork = getPendingBuildDispatchWork;

function completeBuildDispatchRetryJob(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CompleteBuildDispatchRetryJob", inputVars, inputOpts);
}
exports.completeBuildDispatchRetryJob = completeBuildDispatchRetryJob;
