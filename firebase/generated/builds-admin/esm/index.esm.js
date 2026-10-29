import { validateAdminArgs } from "firebase-admin/data-connect";

export const connectorConfig = {
  connector: "builds",
  serviceId: "openci-b1b91-service",
  location: "asia-northeast1",
};

export function getBuildJobs(dcOrVarsOrOptions, varsOrOptions, options) {
  const {
    dc: dcInstance,
    vars: inputVars,
    options: inputOpts,
  } = validateAdminArgs(connectorConfig, dcOrVarsOrOptions, varsOrOptions, options, true, true);
  dcInstance.useGen(true);
  return dcInstance.executeQuery("GetBuildJobs", inputVars, inputOpts);
}
