import assert from "node:assert/strict";
import { once } from "node:events";
import { createServer } from "node:http";
import { test } from "node:test";
import {
  createdBuildJobIds,
  dispatchTaskId,
  dispatchFailureReason,
} from "../../lib/functions/build_dispatch.js";
import { launchCloudRunJob } from "../../lib/functions/cloud_run_job.js";
import { hasOrchardCapacity, OrchardCapacityClient } from "../../lib/functions/orchard_capacity.js";

const now = Date.now();
const size = { cpu: 2, memoryMiB: 4096 };
const resources = (cpu = 8, memory = 16384, slots = 2) => ({
  "org.cirruslabs.logical-cores": cpu,
  "org.cirruslabs.memory-mib": memory,
  "org.cirruslabs.tart-vms": slots,
});
const worker = (overrides = {}) => ({
  name: "mac-1",
  runtime: "tart",
  arch: "arm64",
  last_seen: new Date(now).toISOString(),
  resources: resources(),
  ...overrides,
});
const vm = (name, overrides = {}) => ({
  name,
  worker: "mac-1",
  resources: resources(2, 4096, 1),
  ...overrides,
});
const reserved = (vmName) => ({ vmName, ...size });

test("dispatch diagnostics omit SDK payloads and unrecognized error fields", () => {
  const failure = Object.assign(new Error("private payload and credentials"), {
    code: "data-connect/permission-denied",
    cause: { authorization: "private token" },
  });
  assert.equal(dispatchFailureReason(failure), "data-connect/permission-denied");
  assert.equal(dispatchFailureReason(new Error("Orchard request timed out")), "orchard_timeout");
  for (const value of [
    null,
    "private value",
    new Error("private payload"),
    new Error("constructor"),
    { code: "private-code", message: "Orchard request timed out" },
  ])
    assert.equal(dispatchFailureReason(value), "unknown");
});

test("only committed CompleteWebhookTask results enqueue distinct job IDs", () => {
  assert.deepEqual(
    createdBuildJobIds({ data: { jobs: [{ id: "one" }, { id: "one" }, { id: "two" }] } }),
    ["one", "two"],
  );
  assert.deepEqual(createdBuildJobIds({ data: { jobs: [] } }), []);
  assert.deepEqual(createdBuildJobIds({ data: null, errors: [{}] }), []);
  for (const data of [
    null,
    {},
    { jobs: null },
    { jobs: [null] },
    { jobs: [{ id: "" }] },
    { jobs: [{ id: "\n" }] },
  ]) {
    assert.throws(() => createdBuildJobIds({ data }));
  }
  assert.throws(() =>
    createdBuildJobIds({ data: { jobs: Array.from({ length: 101 }, () => ({ id: "job" })) } }),
  );
});

test("task IDs deduplicate redelivery and keep each recovery attempt distinct", () => {
  assert.equal(dispatchTaskId("job"), dispatchTaskId("job"));
  assert.match(dispatchTaskId("job"), /^[0-9a-f]{64}$/);
  assert.notEqual(dispatchTaskId("job"), dispatchTaskId("job", "dispatch-1"));
  assert.notEqual(dispatchTaskId("job", "dispatch-1"), dispatchTaskId("job", "dispatch-2"));
});

test("capacity includes other VMs and pending reservations without counting a VM twice", () => {
  assert.equal(hasOrchardCapacity({ workers: [worker()], vms: [] }, [], size, now), true);
  assert.equal(
    hasOrchardCapacity({ workers: [worker()], vms: [] }, [reserved("a"), reserved("b")], size, now),
    false,
  );
  assert.equal(
    hasOrchardCapacity({ workers: [worker()], vms: [vm("a")] }, [reserved("a")], size, now),
    true,
  );
  assert.equal(
    hasOrchardCapacity({ workers: [worker()], vms: [vm("a")] }, [reserved("b")], size, now),
    false,
  );
  assert.equal(
    hasOrchardCapacity(
      { workers: [worker()], vms: [vm("outside", { assignedCPU: 8 })] },
      [],
      size,
      now,
    ),
    false,
  );
});

test("offline, paused and incompatible workers contribute no capacity", () => {
  for (const override of [
    { scheduling_paused: true },
    { arch: "amd64" },
    { runtime: "vetu" },
    { last_seen: new Date(now - 180001).toISOString() },
    { last_seen: "bad" },
    { resources: {} },
  ])
    assert.equal(
      hasOrchardCapacity({ workers: [worker(override)], vms: [] }, [], size, now),
      false,
    );
});

test("per-worker CPU/memory limits and unscheduled VMs are respected", () => {
  const workers = [
    worker({ resources: resources(2, 4096) }),
    worker({ name: "mac-2", resources: resources(2, 4096) }),
  ];
  assert.equal(
    hasOrchardCapacity({ workers, vms: [vm("pending", { worker: "" })] }, [], size, now),
    true,
  );
  assert.equal(
    hasOrchardCapacity(
      { workers, vms: [vm("pending", { worker: "" })] },
      [reserved("future")],
      size,
      now,
    ),
    false,
  );
  assert.equal(
    hasOrchardCapacity({ workers, vms: [] }, [], { cpu: 4, memoryMiB: 4096 }, now),
    false,
  );
});

test("unknown or malformed resource usage fails closed", () => {
  assert.throws(() =>
    hasOrchardCapacity({ workers: [worker()], vms: [{ name: "unknown" }] }, [], size, now),
  );
  assert.throws(() =>
    hasOrchardCapacity({ workers: [worker(), worker()], vms: [] }, [], size, now),
  );
  assert.throws(() =>
    hasOrchardCapacity({ workers: [], vms: [] }, [], { cpu: 0, memoryMiB: 4096 }, now),
  );
});

test("Orchard authenticates both inventory reads and rejects redirects and unsafe URLs", async (t) => {
  let redirect = false;
  let redirectHits = 0;
  const server = createServer((req, res) => {
    if (req.url === "/redirect") redirectHits++;
    assert.equal(
      req.headers.authorization,
      `Basic ${Buffer.from("account:token").toString("base64")}`,
    );
    if (redirect) {
      res.writeHead(302, { location: "/redirect" });
      res.end();
      return;
    }
    res.writeHead(200, { "content-type": "application/json" });
    res.end(JSON.stringify(req.url === "/v1/workers" ? [worker()] : [vm("busy")]));
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const url = `http://127.0.0.1:${server.address().port}`;
  const config = { url, account: "account", token: "token" };
  assert.throws(() => new OrchardCapacityClient(config));
  assert.throws(
    () => new OrchardCapacityClient({ ...config, url: "http://remote.test", allowLocalHttp: true }),
  );
  assert.throws(
    () => new OrchardCapacityClient({ ...config, url: "https://user:password@orchard.test" }),
  );
  const client = new OrchardCapacityClient({ ...config, allowLocalHttp: true });
  const snapshot = await client.snapshot();
  assert.equal(snapshot.workers[0].name, "mac-1");
  assert.equal(snapshot.vms[0].name, "busy");
  redirect = true;
  await assert.rejects(client.snapshot());
  assert.equal(redirectHits, 0);
});

test("Cloud Run launches one task with only durable IDs and disables automatic POST retry", async () => {
  const cloudRunJob = "projects/demo-openci/locations/asia-northeast1/jobs/build-executor";
  const operation = "projects/demo-openci/locations/asia-northeast1/operations/op-1";
  const dispatch = { id: "dispatch", jobId: "job", cloudRunJob };
  let calls = 0;
  const result = await launchCloudRunJob(dispatch, async (request) => {
    calls++;
    assert.equal(request.url, `https://run.googleapis.com/v2/${cloudRunJob}:run`);
    assert.equal(request.method, "POST");
    assert.equal(request.retry, false);
    assert.equal(request.maxRedirects, 0);
    assert.deepEqual(request.data, {
      overrides: {
        taskCount: 1,
        containerOverrides: [
          {
            env: [
              { name: "BUILD_JOB_ID", value: "job" },
              { name: "BUILD_DISPATCH_ID", value: "dispatch" },
            ],
          },
        ],
      },
    });
    return { data: { name: operation } };
  });
  assert.equal(result, operation);
  assert.equal(calls, 1);
  await assert.rejects(
    launchCloudRunJob({ ...dispatch, cloudRunJob: "https://attacker.test" }, async () =>
      assert.fail(),
    ),
  );
  await assert.rejects(
    launchCloudRunJob(dispatch, async () => ({
      data: { name: "https://example.test/operations/o" },
    })),
  );
  await assert.rejects(
    launchCloudRunJob(dispatch, async () => ({
      data: { name: operation, done: true, error: { code: 13 } },
    })),
  );
  const numericOperation = "projects/123456789/locations/asia-northeast1/operations/op-1";
  assert.equal(
    await launchCloudRunJob(dispatch, async () => ({ data: { name: numericOperation } })),
    numericOperation,
  );
});
