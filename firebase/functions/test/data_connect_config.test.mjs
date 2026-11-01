import assert from "node:assert/strict";
import { test } from "node:test";
import { initializeApp, deleteApp } from "firebase-admin/app";
import { dataConnectServiceId } from "../../lib/functions/data_connect_config.js";
import { isolatedConnector } from "../../lib/functions/executor/store.js";

test("service selection keeps the existing deployment and rejects path injection", () => {
  assert.equal(dataConnectServiceId({}), "openci-b1b91-service");
  assert.equal(
    dataConnectServiceId({ OPENCI_DATA_CONNECT_SERVICE_ID: "separate-service" }),
    "separate-service",
  );
  for (const value of ["", "../other", "projects/another/services/main", "x".repeat(64)]) {
    assert.throws(() => dataConnectServiceId({ OPENCI_DATA_CONNECT_SERVICE_ID: value }));
  }
});

test("runtime connector overrides stay within the selected Firebase app", async (t) => {
  const previous = process.env.OPENCI_DATA_CONNECT_SERVICE_ID;
  process.env.OPENCI_DATA_CONNECT_SERVICE_ID = "separate-service";
  const app = initializeApp({ projectId: "demo-isolated" }, "isolation-test");
  const generated = {
    location: "asia-northeast1",
    serviceId: "openci-b1b91-service",
    connector: "teams",
  };
  const teams = isolatedConnector(generated, app);
  const logs = isolatedConnector({ ...generated, connector: "logs" }, app);
  t.after(async () => {
    if (previous === undefined) delete process.env.OPENCI_DATA_CONNECT_SERVICE_ID;
    else process.env.OPENCI_DATA_CONNECT_SERVICE_ID = previous;
    await Promise.all([deleteApp(teams.app), deleteApp(logs.app), deleteApp(app)]);
  });
  assert.equal(teams.app.options.projectId, "demo-isolated");
  assert.equal(teams.connectorConfig.serviceId, "separate-service");
  assert.equal(logs.connectorConfig.connector, "logs");
  assert.notEqual(teams.app, logs.app);
  assert.equal(generated.serviceId, "openci-b1b91-service");
});
