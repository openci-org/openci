const { validateAdminArgs } = require("firebase-admin/data-connect");

const connectorConfig = {
  connector: "builds",
  serviceId: "openci-b1b91-service",
  location: "asia-northeast1",
};
exports.connectorConfig = connectorConfig;

function getBuildJobs(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildJobs", inputVars, inputOpts);
}
exports.getBuildJobs = getBuildJobs;

function getBuildJob(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildJob", inputVars, inputOpts);
}
exports.getBuildJob = getBuildJob;
