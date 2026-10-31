import assert from "node:assert/strict";
import { createHmac, randomUUID } from "node:crypto";
import { after, test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import { connectorConfig, getWebhookTaskByDeliveryId } from "@openci/webhooks-admin";

const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(host ?? "", /^(127\.0\.0\.1|localhost):\d+$/, "Start the SQL Connect emulator first");
const secret = process.env.GITHUB_WEBHOOK_TEST_SECRET;
assert.ok(secret, "Set GITHUB_WEBHOOK_TEST_SECRET to the dummy emulator secret");
const endpoint = "http://127.0.0.1:5001/demo-openci/asia-northeast1/githubWebhookFsc";
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;
const app = initializeApp({ projectId: "demo-openci" });
const dc = getDataConnect(connectorConfig, app);
after(() => deleteApp(app));

async function deliver(deliveryId, payload, eventType = "push", signature) {
  return fetch(endpoint, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-github-delivery": deliveryId,
      "x-github-event": eventType,
      "x-hub-signature-256":
        signature ?? `sha256=${createHmac("sha256", secret).update(payload).digest("hex")}`,
    },
    body: payload,
    signal: AbortSignal.timeout(15000),
  });
}

function fixture(t) {
  const deliveryId = randomUUID();
  t.after(async () => {
    const response = await fetch(`${service}:executeGraphql`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        query: `mutation Cleanup($deliveryId: String!) {
          webhookTask_deleteMany(where: { deliveryId: { eq: $deliveryId } })
        }`,
        variables: { deliveryId },
      }),
      signal: AbortSignal.timeout(15000),
    });
    const result = await response.json();
    assert.ok(response.ok && !result.errors?.length, JSON.stringify(result));
  });
  return deliveryId;
}

test("the deployed emulator Function verifies original bytes and persists via its Admin SDK", async (t) => {
  const deliveryId = fixture(t);
  const payload = '{\n "ref": "refs/heads/main", "message": "日本語 🚀"\n}\n';
  const response = await deliver(deliveryId, payload);
  assert.equal(response.status, 200, await response.text());
  const row = (await getWebhookTaskByDeliveryId(dc, { deliveryId })).data.webhookTask;
  assert.equal(row.payload, payload);
  assert.equal(row.status, "pending");

  const duplicate = await deliver(deliveryId, payload);
  assert.equal(duplicate.status, 200);
  assert.equal(await duplicate.text(), "OK");
  assert.deepEqual((await getWebhookTaskByDeliveryId(dc, { deliveryId })).data.webhookTask, row);
});

test("the HTTP endpoint rejects invalid signatures and acknowledges ignored events without writes", async (t) => {
  const deliveryId = fixture(t);
  const payload = '{"action":"closed"}';
  assert.equal(
    (await deliver(deliveryId, payload, "push", `sha256=${"0".repeat(64)}`)).status,
    400,
  );
  assert.equal((await deliver(deliveryId, payload, "ping")).status, 200);
  assert.equal((await deliver(deliveryId, payload, "pull_request")).status, 200);
  assert.equal((await getWebhookTaskByDeliveryId(dc, { deliveryId })).data.webhookTask, null);
});
