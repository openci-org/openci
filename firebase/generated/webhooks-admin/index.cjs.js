const { validateAdminArgs } = require("firebase-admin/data-connect");

const connectorConfig = {
  connector: "webhooks",
  serviceId: "openci-b1b91-service",
  location: "asia-northeast1",
};
exports.connectorConfig = connectorConfig;

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
