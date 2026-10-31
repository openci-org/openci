const { validateAdminArgs } = require("firebase-admin/data-connect");

const connectorConfig = {
  connector: "billing",
  serviceId: "openci-b1b91-service",
  location: "asia-northeast1",
};
exports.connectorConfig = connectorConfig;

function getBillingAdmission(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBillingAdmission", inputVars, inputOpts);
}
exports.getBillingAdmission = getBillingAdmission;

function createBillingAdmission(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CreateBillingAdmission", inputVars, inputOpts);
}
exports.createBillingAdmission = createBillingAdmission;

function bindBillingAdmissionRun(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("BindBillingAdmissionRun", inputVars, inputOpts);
}
exports.bindBillingAdmissionRun = bindBillingAdmissionRun;

function expireBillingAdmission(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ExpireBillingAdmission", inputVars, inputOpts);
}
exports.expireBillingAdmission = expireBillingAdmission;

function createBillingCheckoutCreation(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CreateBillingCheckoutCreation", inputVars, inputOpts);
}
exports.createBillingCheckoutCreation = createBillingCheckoutCreation;

function recordBillingCheckoutSession(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("RecordBillingCheckoutSession", inputVars, inputOpts);
}
exports.recordBillingCheckoutSession = recordBillingCheckoutSession;

function closeBillingCheckoutCreation(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CloseBillingCheckoutCreation", inputVars, inputOpts);
}
exports.closeBillingCheckoutCreation = closeBillingCheckoutCreation;

function getBillingContext(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBillingContext", inputVars, inputOpts);
}
exports.getBillingContext = getBillingContext;

function getBillingMembership(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBillingMembership", inputVars, inputOpts);
}
exports.getBillingMembership = getBillingMembership;

function getBillingCustomerByStripeId(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBillingCustomerByStripeId", inputVars, inputOpts);
}
exports.getBillingCustomerByStripeId = getBillingCustomerByStripeId;

function getBillingCheckoutCreation(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBillingCheckoutCreation", inputVars, inputOpts);
}
exports.getBillingCheckoutCreation = getBillingCheckoutCreation;

function getBillingPeriod(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBillingPeriod", inputVars, inputOpts);
}
exports.getBillingPeriod = getBillingPeriod;

function createBillingCustomerCreation(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CreateBillingCustomerCreation", inputVars, inputOpts);
}
exports.createBillingCustomerCreation = createBillingCustomerCreation;

function recordBillingCustomer(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("RecordBillingCustomer", inputVars, inputOpts);
}
exports.recordBillingCustomer = recordBillingCustomer;

function deleteBillingTeam(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("DeleteBillingTeam", inputVars, inputOpts);
}
exports.deleteBillingTeam = deleteBillingTeam;

function getBillingTeamDeletion(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBillingTeamDeletion", inputVars, inputOpts);
}
exports.getBillingTeamDeletion = getBillingTeamDeletion;

function getDueBillingTeamDeletions(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetDueBillingTeamDeletions", undefined, inputOpts);
}
exports.getDueBillingTeamDeletions = getDueBillingTeamDeletions;

function completeBillingTeamCleanup(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CompleteBillingTeamCleanup", inputVars, inputOpts);
}
exports.completeBillingTeamCleanup = completeBillingTeamCleanup;

function acknowledgeBillingCredentialCleanup(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("AcknowledgeBillingCredentialCleanup", inputVars, inputOpts);
}
exports.acknowledgeBillingCredentialCleanup = acknowledgeBillingCredentialCleanup;

function deferBillingTeamCleanup(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("DeferBillingTeamCleanup", inputVars, inputOpts);
}
exports.deferBillingTeamCleanup = deferBillingTeamCleanup;

function getBillingExecution(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBillingExecution", inputVars, inputOpts);
}
exports.getBillingExecution = getBillingExecution;

function startBillingExecution(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("StartBillingExecution", inputVars, inputOpts);
}
exports.startBillingExecution = startBillingExecution;

function heartbeatBillingExecution(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("HeartbeatBillingExecution", inputVars, inputOpts);
}
exports.heartbeatBillingExecution = heartbeatBillingExecution;

function finishBillingExecution(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("FinishBillingExecution", inputVars, inputOpts);
}
exports.finishBillingExecution = finishBillingExecution;

function expireBillingExecution(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ExpireBillingExecution", inputVars, inputOpts);
}
exports.expireBillingExecution = expireBillingExecution;

function getBillingJob(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBillingJob", inputVars, inputOpts);
}
exports.getBillingJob = getBillingJob;

function createBillingPeriod(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CreateBillingPeriod", inputVars, inputOpts);
}
exports.createBillingPeriod = createBillingPeriod;

function getBillingStripeState(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBillingStripeState", inputVars, inputOpts);
}
exports.getBillingStripeState = getBillingStripeState;

function getBillingStripeEvent(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBillingStripeEvent", inputVars, inputOpts);
}
exports.getBillingStripeEvent = getBillingStripeEvent;

function initializeBillingStripeState(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("InitializeBillingStripeState", inputVars, inputOpts);
}
exports.initializeBillingStripeState = initializeBillingStripeState;

function recordBillingStripeEvent(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("RecordBillingStripeEvent", inputVars, inputOpts);
}
exports.recordBillingStripeEvent = recordBillingStripeEvent;

function getBillingPeriodUsage(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBillingPeriodUsage", inputVars, inputOpts);
}
exports.getBillingPeriodUsage = getBillingPeriodUsage;
