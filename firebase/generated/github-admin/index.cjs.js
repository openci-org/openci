const { validateAdminArgs } = require("firebase-admin/data-connect");

const connectorConfig = {
  connector: "github",
  serviceId: "openci-b1b91-service",
  location: "asia-northeast1",
};
exports.connectorConfig = connectorConfig;

function getExpiredGitHubConnectionCredentials(dcOrOptions, options) {
  const { dc: dcInstance, options: inputOpts } = validateAdminArgs(
    connectorConfig,
    dcOrOptions,
    options,
    undefined,
  );
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetExpiredGitHubConnectionCredentials", undefined, inputOpts);
}
exports.getExpiredGitHubConnectionCredentials = getExpiredGitHubConnectionCredentials;

function deleteExpiredGitHubConnectionRequest(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("DeleteExpiredGitHubConnectionRequest", inputVars, inputOpts);
}
exports.deleteExpiredGitHubConnectionRequest = deleteExpiredGitHubConnectionRequest;

function deleteExpiredGitHubConnectionSession(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("DeleteExpiredGitHubConnectionSession", inputVars, inputOpts);
}
exports.deleteExpiredGitHubConnectionSession = deleteExpiredGitHubConnectionSession;

function confirmGitHubConnection(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ConfirmGitHubConnection", inputVars, inputOpts);
}
exports.confirmGitHubConnection = confirmGitHubConnection;

function getGitHubConnections(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetGitHubConnections", inputVars, inputOpts);
}
exports.getGitHubConnections = getGitHubConnections;

function getActiveGitHubConnection(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetActiveGitHubConnection", inputVars, inputOpts);
}
exports.getActiveGitHubConnection = getActiveGitHubConnection;

function createGitHubConnectionRequest(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CreateGitHubConnectionRequest", inputVars, inputOpts);
}
exports.createGitHubConnectionRequest = createGitHubConnectionRequest;

function consumeGitHubConnectionRequest(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("ConsumeGitHubConnectionRequest", inputVars, inputOpts);
}
exports.consumeGitHubConnectionRequest = consumeGitHubConnectionRequest;

function createGitHubConnectionSession(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeMutation("CreateGitHubConnectionSession", inputVars, inputOpts);
}
exports.createGitHubConnectionSession = createGitHubConnectionSession;

function getGitHubConnectionSession(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetGitHubConnectionSession", inputVars, inputOpts);
}
exports.getGitHubConnectionSession = getGitHubConnectionSession;
