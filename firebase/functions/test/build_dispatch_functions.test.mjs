import assert from "node:assert/strict";
import { after, test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getFunctions } from "firebase-admin/functions";
import { queueBuildJobs, dispatchBuildJob } from "../../lib/functions/build_dispatch_functions.js";
import { dispatchTaskId } from "../../lib/functions/build_dispatch.js";

const app = initializeApp({ projectId: "demo-openci" });
after(() => deleteApp(app));
const event = (data, errors) => ({
  id: "event",
  authType: "admin",
  data: { payload: { data, errors, variables: { jobsJson: "private metadata" } } },
});

test("mutation retries complete a partially enqueued batch without duplicating tasks", async (t) => {
  const saved = new Map();
  let outage = true;
  t.mock.method(getFunctions(app), "taskQueue", (queue) => {
    assert.equal(queue, "locations/asia-northeast1/functions/dispatchBuildJob");
    return {
      enqueue: async (data, options) => {
        assert.deepEqual(Object.keys(data), ["jobId"]);
        assert.equal(options.id, dispatchTaskId(data.jobId));
        if (saved.has(options.id)) throw { code: "functions/task-already-exists" };
        if (data.jobId === "second" && outage) throw new Error("private SDK error");
        saved.set(options.id, data.jobId);
      },
    };
  });
  const input = event({ jobs: [{ id: "first" }, { id: "second" }, { id: "third" }] });
  await assert.rejects(queueBuildJobs.run(input), {
    message: "Build dispatch enqueue failed; retry required",
  });
  assert.deepEqual([...saved.values()], ["first"]);
  outage = false;
  await queueBuildJobs.run(input);
  await queueBuildJobs.run(input);
  assert.deepEqual([...saved.values()], ["first", "second", "third"]);
});

test("empty or failed mutations enqueue nothing and non-admin events are rejected", async (t) => {
  t.mock.method(getFunctions(app), "taskQueue", () => assert.fail("must not enqueue"));
  await queueBuildJobs.run(event({ jobs: [] }));
  await queueBuildJobs.run(event(null, [{ message: "failed" }]));
  await assert.rejects(
    queueBuildJobs.run({ ...event({ jobs: [{ id: "job" }] }), authType: "unknown" }),
  );
});

test("malformed task payloads are acknowledged without accessing configured services", async () => {
  for (const data of [null, {}, { jobId: "" }, { jobId: "job", url: "https://example.test" }]) {
    await dispatchBuildJob.run({ data });
  }
});
