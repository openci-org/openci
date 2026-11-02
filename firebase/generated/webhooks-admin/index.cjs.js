const { validateAdminArgs } = require("firebase-admin/data-connect");

const connectorConfig = {
  connector: "webhooks",
  serviceId: "openci-b1b91-service",
  location: "asia-northeast1",
};
exports.connectorConfig = connectorConfig;

function completeWebhookTask(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CompleteWebhookTask", inputVars, inputOpts);
}
exports.completeWebhookTask = completeWebhookTask;

function rejectWebhookTask(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("RejectWebhookTask", inputVars, inputOpts);
}
exports.rejectWebhookTask = rejectWebhookTask;

function createWebhookTask(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CreateWebhookTask", inputVars, inputOpts);
}
exports.createWebhookTask = createWebhookTask;

function requestWebhookTaskPlanning(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("RequestWebhookTaskPlanning", inputVars, inputOpts);
}
exports.requestWebhookTaskPlanning = requestWebhookTaskPlanning;

function getWebhookTaskByDeliveryId(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetWebhookTaskByDeliveryId", inputVars, inputOpts);
}
exports.getWebhookTaskByDeliveryId = getWebhookTaskByDeliveryId;

function getWebhookTask(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetWebhookTask", inputVars, inputOpts);
}
exports.getWebhookTask = getWebhookTask;

function getSkippedWorkflowCheck(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetSkippedWorkflowCheck", inputVars, inputOpts);
}
exports.getSkippedWorkflowCheck = getSkippedWorkflowCheck;

function getPendingSkippedWorkflowChecks(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetPendingSkippedWorkflowChecks", undefined, inputOpts);
}
exports.getPendingSkippedWorkflowChecks = getPendingSkippedWorkflowChecks;

function claimSkippedWorkflowCheck(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ClaimSkippedWorkflowCheck", inputVars, inputOpts);
}
exports.claimSkippedWorkflowCheck = claimSkippedWorkflowCheck;

function completeSkippedWorkflowCheck(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CompleteSkippedWorkflowCheck", inputVars, inputOpts);
}
exports.completeSkippedWorkflowCheck = completeSkippedWorkflowCheck;

function retrySkippedWorkflowCheck(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("RetrySkippedWorkflowCheck", inputVars, inputOpts);
}
exports.retrySkippedWorkflowCheck = retrySkippedWorkflowCheck;
