import assert from "node:assert/strict";
import { createServer } from "node:http";
import { once } from "node:events";
import { test } from "node:test";
import {
  requestedWebhookTaskId,
  invokeProcessWebhookTask,
} from "../../lib/functions/build_job_planning.js";

test("only committed mutation results identify work", () => {
  assert.equal(requestedWebhookTaskId({ data: { task: { id: "task" } }, errors: [] }), "task");
  assert.equal(requestedWebhookTaskId({ data: null, errors: [{}] }), null);
  assert.equal(requestedWebhookTaskId({ data: { task: null } }), null);
  assert.equal(requestedWebhookTaskId({ data: { id: "task" } }), null);
  assert.throws(() => requestedWebhookTaskId({ data: { task: { id: 123 } } }));
});

test("the dispatcher sends only the task ID and propagates failures for retry", async (t) => {
  const previous = process.env.FUNCTIONS_EMULATOR;
  process.env.FUNCTIONS_EMULATOR = "true";
  let status = 200;
  let result = "created";
  const received = [];
  const server = createServer(async (req, res) => {
    let body = "";
    for await (const chunk of req) body += chunk;
    received.push(JSON.parse(body));
    res.writeHead(status, { "content-type": "application/json" });
    res.end(JSON.stringify({ result }));
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  t.after(async () => {
    if (previous === undefined) delete process.env.FUNCTIONS_EMULATOR;
    else process.env.FUNCTIONS_EMULATOR = previous;
    await new Promise((resolve) => server.close(resolve));
  });
  const url = `http://127.0.0.1:${server.address().port}/`;
  for (result of ["created", "duplicate", "failed"]) await invokeProcessWebhookTask(url, "task-1");
  assert.deepEqual(
    received,
    Array.from({ length: 3 }, () => ({ taskId: "task-1" })),
  );
  status = 503;
  await assert.rejects(invokeProcessWebhookTask(url, "task-1"));
  status = 200;
  result = "unexpected";
  await assert.rejects(invokeProcessWebhookTask(url, "task-1"));
  delete process.env.FUNCTIONS_EMULATOR;
  await assert.rejects(invokeProcessWebhookTask(url, "task-1"), /HTTPS/);
});
