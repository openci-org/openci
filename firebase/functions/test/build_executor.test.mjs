import assert from "node:assert/strict";
import { test } from "node:test";
import { createServer } from "node:http";
import { generateKeyPairSync } from "node:crypto";
import { WebSocketServer } from "ws";
import { ExecutionLogs, StreamingRedactor } from "../../lib/functions/executor/logs.js";
import { checkoutScript, workflowScript, validateJob } from "../../lib/functions/executor/model.js";
import { OrchardExecutor } from "../../lib/functions/executor/orchard.js";
import { paidPeriod } from "../../lib/functions/executor/billing.js";
import {
  loadSecrets,
  secretUrl,
  stopCloudRunExecution,
} from "../../lib/functions/executor/google.js";
import { ExecutionGitHub } from "../../lib/functions/executor/github.js";

const dispatch = {
  id: "dispatch",
  jobId: "job",
  teamId: "team",
  runId: "run-dispatch",
  vmName: "openci-dispatch",
  image: "base-macos",
  cpu: 2,
  memoryMiB: 4096,
  cloudRunJob: "projects/demo-openci/locations/asia-northeast1/jobs/executor",
  executionName:
    "projects/demo-openci/locations/asia-northeast1/jobs/executor/executions/executor-abc",
};
const job = {
  id: "job",
  teamId: "team",
  owner: "org",
  repo: "app",
  installationId: "123",
  workflowName: "Test",
  workflowFileName: "ci/test.dart",
  commitSha: "a".repeat(40),
};

test("scripts quote secrets, pin the commit, and reject unsafe workflow paths", () => {
  validateJob(job, dispatch);
  const token = "token'$(id)";
  const checkout = checkoutScript(job, "https://github.com/org/app.git", token);
  assert.match(checkout, /git checkout --detach 'a{40}'/);
  assert.doesNotMatch(checkout, /https:\/\/.*token/);
  const workflow = workflowScript(job, dispatch, 7, { TEST: "it's $(id)\nnext" });
  assert.ok(workflow.includes("export TEST='it'\\''s $(id)\nnext'"));
  assert.match(workflow, /OPENCI_RUN_NUMBER='7'/);
  assert.match(workflow, /flutter pub run 'openci\/ci\/test.dart'/);
  assert.throws(() => validateJob({ ...job, workflowFileName: "../test.dart" }, dispatch));
  assert.throws(() => workflowScript(job, dispatch, 7, { BASH_ENV: "attack" }));
  assert.throws(() => validateJob({ ...job, commitSha: "main; echo token" }, dispatch));
});

test("redaction covers split tokens, multiline secrets and overlapping values", () => {
  const redactor = new StreamingRedactor(["token-secret", "line1\nline2", "token"]);
  const actual =
    ["first tok", "en-se", "cret and line1\n", "line2 last"]
      .map((part) => redactor.push(part))
      .join("") + redactor.push("", true);
  assert.equal(actual, "first [REDACTED] and [REDACTED] last");
});

test("live log chunks preserve UTF-8 and do not wait for the longest secret", async () => {
  const redactor = new StreamingRedactor(["a".repeat(65000)]);
  assert.equal(redactor.push("ready\n"), "ready\n");
  const logger = new ExecutionLogs({}, "team", "run");
  const messages = [];
  logger.append = async (_step, _stream, message) => {
    messages.push(message);
  };
  const output = logger.output("run_workflow", ["xx"]);
  const first = Buffer.from("b".repeat(8189) + "😀");
  await output.write("stdout", first.subarray(0, first.length - 1));
  await output.write("stdout", first.subarray(first.length - 1));
  await output.write("stdout", Buffer.from("\nfinished\n"));
  await output.flush();
  assert.equal(messages.join(""), first.toString() + "\nfinished\n");
  assert.ok(messages.every((message) => Buffer.byteLength(message) <= 8192));
});

test("billing entitlement requires matching Stripe mode, customer, plan and current paid period", () => {
  const now = Date.now();
  const context = {
    team: { id: "team" },
    customer: { stripeCustomerId: "cus_1", livemode: true },
    stripe: {
      stripeCustomerId: "cus_1",
      livemode: true,
      stripeSubscriptionId: "sub_1",
      subscriptionStatus: "active",
      planId: "pro",
      paidPeriodId: "period",
      paidPeriod: {
        id: "period",
        teamId: "team",
        planId: "pro",
        periodType: "paid",
        startsAt: String(Math.floor(now / 1000) - 10),
        endsAt: String(Math.floor(now / 1000) + 100),
      },
    },
  };
  assert.equal(paidPeriod(context, "team", true, now), "period");
  assert.equal(paidPeriod(context, "team", false, now), undefined);
  assert.equal(
    paidPeriod(
      { ...context, customer: { ...context.customer, stripeCustomerId: "other" } },
      "team",
      true,
      now,
    ),
    undefined,
  );
  assert.equal(paidPeriod(context, "other-team", true, now), undefined);
  assert.equal(paidPeriod(context, "team", true, now + 200000), undefined);
});

test("Secret Manager only reads pinned versions in the configured project", async () => {
  assert.equal(
    secretUrl(
      "projects/demo-openci/locations/asia-northeast1/secrets/key/versions/2",
      "demo-openci",
    ),
    "https://secretmanager.asia-northeast1.rep.googleapis.com/v1/projects/demo-openci/locations/asia-northeast1/secrets/key/versions/2:access",
  );
  assert.throws(() => secretUrl("projects/other/secrets/key/versions/2", "demo-openci"));
  assert.throws(() => secretUrl("projects/demo-openci/secrets/key/versions/latest", "demo-openci"));
  const result = await loadSecrets(
    [{ name: "TOKEN", secretVersionPath: "projects/demo-openci/secrets/key/versions/2" }],
    "demo-openci",
    async () => ({ data: { payload: { data: Buffer.from("secret").toString("base64") } } }),
  );
  assert.equal(result.TOKEN, "secret");
});

test("recovery waits for confirmed Cloud Run termination and rejects a foreign execution", async () => {
  const calls = [];
  await assert.rejects(
    stopCloudRunExecution(dispatch, dispatch.cloudRunJob, async (request) => {
      calls.push(request.method);
      return { data: {} };
    }),
    /pending/,
  );
  assert.deepEqual(calls, ["GET", "POST", "GET"]);
  await stopCloudRunExecution(dispatch, dispatch.cloudRunJob, async () => ({
    data: { completionTime: new Date().toISOString() },
  }));
  await assert.rejects(
    stopCloudRunExecution(
      {
        ...dispatch,
        executionName: dispatch.executionName.replace("executor/executions", "other/executions"),
      },
      dispatch.cloudRunJob,
      async () => {
        assert.fail("Must not send request");
      },
    ),
  );
});

async function controller(t, onSocket, handler) {
  const requests = [];
  const server = createServer(
    handler ??
      ((_request, response) => {
        response.writeHead(404).end();
      }),
  );
  const sockets = new WebSocketServer({ server });
  sockets.on("connection", (socket, request) => {
    requests.push(request);
    onSocket(socket, request);
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(async () => {
    for (const socket of sockets.clients) socket.terminate();
    await new Promise((resolve) => sockets.close(resolve));
    await new Promise((resolve) => server.close(resolve));
  });
  return {
    client: new OrchardExecutor({
      url: `http://127.0.0.1:${server.address().port}`,
      account: "account",
      token: "credential",
      allowLocalHttp: true,
    }),
    requests,
  };
}

test("Orchard sends script over stdin, streams both channels and requires an exit frame", async (t) => {
  let stdin = "";
  const f = await controller(t, (socket) =>
    socket.on("message", (raw) => {
      const frame = JSON.parse(raw);
      assert.equal(frame.type, "stdin");
      if (frame.data) stdin += Buffer.from(frame.data, "base64").toString();
      else {
        socket.send(
          JSON.stringify({ type: "stdout", data: Buffer.from("hello").toString("base64") }),
        );
        socket.send(
          JSON.stringify({ type: "stderr", data: Buffer.from("error").toString("base64") }),
        );
        socket.send(JSON.stringify({ type: "exit", exit: { code: 17 } }));
      }
    }),
  );
  const output = [];
  assert.equal(
    await f.client.exec(
      "vm",
      "secret-script\n",
      async (stream, data) => {
        output.push([stream, data.toString()]);
      },
      new AbortController().signal,
    ),
    17,
  );
  assert.equal(stdin, "secret-script\n");
  assert.deepEqual(output, [
    ["stdout", "hello"],
    ["stderr", "error"],
  ]);
  assert.equal(
    new URL(f.requests[0].url, "http://localhost").searchParams.get("command"),
    "/bin/bash -s",
  );
  assert.doesNotMatch(f.requests[0].url, /secret/);
});

test("Orchard disconnect does not replay a command and abort closes the connection", async (t) => {
  const f = await controller(t, (socket) => socket.close());
  await assert.rejects(
    f.client.exec("vm", "workflow", async () => {}, new AbortController().signal),
    /without exit/,
  );
  assert.equal(f.requests.length, 1);
  const g = await controller(t, () => {});
  const abort = new AbortController();
  const running = g.client.exec("vm", "workflow", async () => {}, abort.signal);
  abort.abort();
  await assert.rejects(running, /interrupted/);
});

test("VM deletion keeps the reservation until Orchard GET confirms absence", async (t) => {
  const f = await controller(
    t,
    () => {},
    (request, response) => {
      response.writeHead(200, { "content-type": "application/json" });
      response.end(request.method === "GET" ? JSON.stringify({ name: "vm" }) : "{}");
    },
  );
  await assert.rejects(f.client.remove("vm"), /not yet confirmed/);
});

test("Orchard reconciles a lost VM create response without issuing a second POST", async (t) => {
  let posts = 0;
  const f = await controller(
    t,
    () => {},
    (request, response) => {
      if (request.method === "POST") {
        posts++;
        request.resume();
        request.on("end", () => request.socket.destroy());
      } else {
        response.writeHead(200, { "content-type": "application/json" });
        response.end(JSON.stringify({ name: dispatch.vmName, image: dispatch.image }));
      }
    },
  );
  await f.client.create(dispatch, new AbortController().signal);
  assert.equal(posts, 1);
});

test("Octokit scopes checkout/check tokens and reconciles a lost check creation response", async (t) => {
  const { privateKey } = generateKeyPairSync("rsa", {
    modulusLength: 2048,
    privateKeyEncoding: { type: "pkcs8", format: "pem" },
    publicKeyEncoding: { type: "spki", format: "pem" },
  });
  const calls = [];
  let created = false;
  const original = globalThis.fetch;
  t.after(() => {
    globalThis.fetch = original;
  });
  globalThis.fetch = async (url, init) => {
    const path = new URL(url).pathname;
    const body = init?.body ? JSON.parse(init.body) : undefined;
    calls.push({ path, method: init.method, body });
    assert.equal(new URL(url).origin, "https://api.github.com");
    if (path.endsWith("/access_tokens"))
      return Response.json({
        token: body.permissions.contents ? "contents-token" : "checks-token",
        expires_at: new Date(Date.now() + 3600000).toISOString(),
        repositories: [{ id: 101, name: "app" }],
        permissions: body.permissions,
        repository_selection: "selected",
      });
    if (path === "/repos/org/app")
      return Response.json({ id: 101, full_name: "org/app", owner: { id: 10 } });
    if (path === "/installation/token") return new Response(null, { status: 204 });
    if (path.includes("/commits/"))
      return Response.json({
        total_count: created ? 1 : 0,
        check_runs: created ? [{ id: 42, external_id: dispatch.runId, app: { id: 1 } }] : [],
      });
    if (path === "/repos/org/app/check-runs" && init.method === "POST") {
      created = true;
      throw new Error("Lost creation response");
    }
    if (path === "/repos/org/app/check-runs/42" && init.method === "PATCH")
      return Response.json({ id: 42 });
    assert.fail(`Unexpected GitHub request: ${path}`);
  };
  const github = new ExecutionGitHub({
    appId: "1",
    privateKey,
    apiBaseUrl: "https://api.github.com",
    baseUrl: "https://github.com",
  });
  const checkout = await github.checkout(job, "10");
  assert.equal(checkout.cloneUrl, "https://github.com/org/app.git");
  assert.equal(checkout.token, "contents-token");
  await checkout.revoke();
  await assert.rejects(github.check(job, dispatch));
  const done = { ...dispatch, resultAt: new Date().toISOString() };
  assert.equal(await github.check(job, done, "failure"), "42");
  assert.equal(calls.filter((call) => call.path === "/repos/org/app/check-runs").length, 1);
  const tokens = calls.filter((call) => call.path.endsWith("/access_tokens"));
  assert.deepEqual(tokens[0].body.repositories, ["app"]);
  assert.deepEqual(tokens[0].body.permissions, { contents: "read" });
  assert.deepEqual(tokens[1].body.permissions, { checks: "write" });
  await assert.rejects(github.checkout(job, "other-account"), /connected installation/);
});
