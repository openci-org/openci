import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { after, test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/webhooks-admin";
import {
  ConflictingWebhookDeliveryError,
  enqueueWebhook,
} from "../../lib/functions/webhook_queue.js";

// Fixture writes must never reach a production service.
const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(host ?? "", /^(127\.0\.0\.1|localhost):\d+$/, "Start the SQL Connect emulator first");
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;
const app = initializeApp({ projectId: "demo-openci" });
const dc = getDataConnect(sdk.connectorConfig, app);
after(() => deleteApp(app));

async function graphql(query, variables) {
  const response = await fetch(`${service}:executeGraphql`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ query, variables }),
    signal: AbortSignal.timeout(15000),
  });
  const result = await response.json();
  assert.ok(response.ok && !result.errors?.length, JSON.stringify(result));
  return result.data;
}

function fixture(t) {
  const delivery = {
    deliveryId: randomUUID(),
    eventType: "push",
    payload: '{"ref":"refs/heads/main"}',
  };
  t.after(() =>
    graphql(
      `
        mutation Cleanup($deliveryId: String!) {
          webhookTask_deleteMany(where: { deliveryId: { eq: $deliveryId } })
        }
      `,
      { deliveryId: delivery.deliveryId },
    ),
  );
  return delivery;
}

async function stored(delivery) {
  return (await sdk.getWebhookTaskByDeliveryId(dc, { deliveryId: delivery.deliveryId })).data
    .webhookTask;
}

test("the generated SDK enqueues a pending task with Unix-second timestamps", async (t) => {
  const delivery = fixture(t);
  const before = Math.floor(Date.now() / 1000);
  assert.equal(await enqueueWebhook(dc, delivery), "created");
  const row = await stored(delivery);
  assert.equal(row.deliveryId, delivery.deliveryId);
  assert.equal(row.eventType, delivery.eventType);
  assert.equal(row.payload, delivery.payload);
  assert.equal(row.status, "pending");
  assert.equal(row.retryCount, "0");
  assert.ok(
    Number(row.createdAt) >= before && Number(row.createdAt) <= Math.floor(Date.now() / 1000),
  );
  assert.equal(row.updatedAt, row.createdAt);
});

test("concurrent redeliveries create exactly one task", async (t) => {
  const delivery = fixture(t);
  const results = await Promise.all(Array.from({ length: 8 }, () => enqueueWebhook(dc, delivery)));
  assert.equal(results.filter((result) => result === "created").length, 1);
  assert.equal(results.filter((result) => result === "duplicate").length, 7);
  const rows = await graphql(
    `
      query Count($deliveryId: String!) {
        webhookTasks(where: { deliveryId: { eq: $deliveryId } }) {
          id
        }
      }
    `,
    { deliveryId: delivery.deliveryId },
  );
  assert.equal(rows.webhookTasks.length, 1);
});

test("a duplicate preserves a completed legacy task and its timestamps", async (t) => {
  const delivery = fixture(t);
  const id = randomUUID();
  await graphql(
    `
      mutation Seed($id: String!, $deliveryId: String!, $payload: String!) {
        webhookTask_insert(
          data: {
            id: $id
            deliveryId: $deliveryId
            eventType: "push"
            payload: $payload
            status: "completed"
            retryCount: 3
            createdAt: 1
            updatedAt: 2
          }
        )
      }
    `,
    { id, deliveryId: delivery.deliveryId, payload: delivery.payload },
  );
  const original = await stored(delivery);
  assert.equal(await enqueueWebhook(dc, delivery), "duplicate");
  assert.deepEqual(await stored(delivery), original);
});

test("a delivery ID cannot overwrite another payload or event type", async (t) => {
  const delivery = fixture(t);
  await enqueueWebhook(dc, delivery);
  const original = await stored(delivery);
  for (const change of [{ payload: '{"ref":"refs/heads/other"}' }, { eventType: "pull_request" }]) {
    await assert.rejects(
      enqueueWebhook(dc, { ...delivery, ...change }),
      ConflictingWebhookDeliveryError,
    );
  }
  assert.deepEqual(await stored(delivery), original);
});

function interceptMutation(executeMutation) {
  return new Proxy(dc, {
    get(target, property) {
      if (property === "executeMutation") return executeMutation;
      const value = Reflect.get(target, property);
      return typeof value === "function" ? value.bind(target) : value;
    },
  });
}

test("a lost successful insert response is reconciled as a duplicate", async (t) => {
  const delivery = fixture(t);
  const connection = interceptMutation(async (...args) => {
    const result = await dc.executeMutation(...args);
    if (args[0] === "CreateWebhookTask") throw new Error("Simulated response loss after commit");
    return result;
  });
  assert.equal(await enqueueWebhook(connection, delivery), "duplicate");
  assert.equal((await stored(delivery)).status, "pending");
});

test("a failed insert with no stored delivery is not acknowledged as a duplicate", async (t) => {
  const delivery = fixture(t);
  const failure = new Error("Simulated unavailable database");
  const connection = interceptMutation(async () => {
    throw failure;
  });
  await assert.rejects(enqueueWebhook(connection, delivery), (error) => error === failure);
  assert.equal(await stored(delivery), null);
});

test("planning signals contain only an ID even for large private payloads", async (t) => {
  const delivery = { ...fixture(t), payload: JSON.stringify({ private: "x".repeat(600000) }) };
  const signals = [];
  const connection = interceptMutation(async (name, variables, ...rest) => {
    if (name === "RequestWebhookTaskPlanning") signals.push(variables);
    return dc.executeMutation(name, variables, ...rest);
  });
  await enqueueWebhook(connection, delivery);
  const task = await stored(delivery);
  assert.deepEqual(signals, [{ id: task.id }]);
  assert.equal(task.payload, delivery.payload);
});

test("a failed dispatch is not acknowledged; redelivery signals the persisted task", async (t) => {
  const delivery = fixture(t);
  const connection = interceptMutation(async (name, ...args) => {
    if (name === "RequestWebhookTaskPlanning") throw new Error("Dispatch unavailable");
    return dc.executeMutation(name, ...args);
  });
  await assert.rejects(enqueueWebhook(connection, delivery));
  const pending = await stored(delivery);
  assert.equal(pending.status, "pending");
  const signals = [];
  const recovered = interceptMutation(async (name, variables, ...rest) => {
    if (name === "RequestWebhookTaskPlanning") signals.push(variables.id);
    return dc.executeMutation(name, variables, ...rest);
  });
  assert.equal(await enqueueWebhook(recovered, delivery), "duplicate");
  assert.deepEqual(signals, [pending.id]);
  assert.deepEqual(await stored(delivery), pending);
});

test("invalid privileged inserts roll back instead of leaving a queued task", async (t) => {
  const delivery = fixture(t);
  const variables = { id: randomUUID(), ...delivery, receivedAt: "1" };
  for (const change of [{ eventType: "issues" }, { receivedAt: "-1" }, { payload: "" }]) {
    await assert.rejects(sdk.createWebhookTask(dc, { ...variables, ...change }));
    assert.equal(await stored(delivery), null);
  }
});

test("client identities cannot enqueue or read private webhook payloads", async (t) => {
  const delivery = fixture(t);
  await enqueueWebhook(dc, delivery);
  for (const impersonate of [
    { unauthenticated: true },
    { authClaims: { sub: "some-user", firebase: { sign_in_provider: "password" } } },
  ]) {
    await assert.rejects(
      sdk.getWebhookTaskByDeliveryId(dc, { deliveryId: delivery.deliveryId }, { impersonate }),
    );
    await assert.rejects(
      sdk.requestWebhookTaskPlanning(dc, { id: (await stored(delivery)).id }, { impersonate }),
    );
    await assert.rejects(
      sdk.createWebhookTask(
        dc,
        {
          id: randomUUID(),
          ...delivery,
          receivedAt: "1",
        },
        { impersonate },
      ),
    );
  }
});
