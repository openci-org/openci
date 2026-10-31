import assert from "node:assert/strict";
import { generateKeyPairSync, randomUUID } from "node:crypto";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { createServer } from "node:net";
import { createServer as createHttpServer } from "node:http";
import { setTimeout as delay } from "node:timers/promises";
import { fileURLToPath } from "node:url";
import { after, before, test } from "node:test";
import { deleteApp, getApps, initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/webhooks-admin";
import { invokeProcessWebhookTask } from "../../lib/functions/build_job_planning.js";
import { enqueueWebhook } from "../../lib/functions/webhook_queue.js";
import { createdBuildJobIds, dispatchBuildJob } from "../../lib/functions/build_dispatch.js";
import {
  DataConnectDispatchStore,
  getDispatchDataConnect,
} from "../../lib/functions/dispatch_store.js";

const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(host ?? "", /^(127\.0\.0\.1|localhost):\d+$/, "Start the SQL Connect emulator first");
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;
const app = initializeApp({ projectId: "demo-openci" });
const dc = getDataConnect(sdk.connectorConfig, app);
const sha = "a".repeat(40);
const installations = new Map();
let dartFunction, dartFunctionUrl, githubServer, githubUrl;

before(async () => {
  githubServer = createHttpServer(async (req, res) => {
    const url = new URL(req.url, "http://localhost");
    const path = decodeURIComponent(url.pathname);
    const tokenMatch = path.match(/^\/app\/installations\/(\d+)\/access_tokens$/);
    const installationId =
      tokenMatch?.[1] ?? req.headers.authorization?.replace("Bearer test-", "");
    const github = installations.get(installationId);
    const respond = (status, body) => {
      res.writeHead(status, { "content-type": "application/json" });
      res.end(JSON.stringify(body));
    };
    if (!github) return respond(404, {});
    if (tokenMatch) {
      let body = "";
      for await (const chunk of req) body += chunk;
      github.tokenRequests.push(JSON.parse(body));
      return respond(201, { token: `test-${installationId}` });
    }
    if (path === "/repos/org/app") return respond(200, { id: 10, owner: { id: 20 } });
    if (path === `/repos/org/app/git/commits/${sha}`) return respond(github.commitStatus, { sha });
    if (url.searchParams.get("ref") !== sha) return respond(400, {});
    if (path === "/repos/org/app/contents/openci") {
      return respond(
        200,
        github.files.map((file) => ({
          name: file.name,
          type: "file",
          size: Buffer.byteLength(file.content),
        })),
      );
    }
    const file = github.files.find(
      (file) => path === `/repos/org/app/contents/openci/${file.name}`,
    );
    if (file) {
      const hook = github.onContents;
      github.onContents = null;
      if (hook) await hook();
      return respond(200, {
        type: "file",
        encoding: "base64",
        content: Buffer.from(file.content).toString("base64"),
      });
    }
    respond(404, {});
  });
  githubServer.listen(0, "127.0.0.1");
  await once(githubServer, "listening");
  githubUrl = `http://127.0.0.1:${githubServer.address().port}`;
  const reservation = createServer();
  reservation.listen(0, "127.0.0.1");
  await once(reservation, "listening");
  const port = reservation.address().port;
  await new Promise((resolve) => reservation.close(resolve));
  dartFunctionUrl = `http://127.0.0.1:${port}/`;
  process.env.FUNCTIONS_EMULATOR = "true";
  const { privateKey } = generateKeyPairSync("rsa", {
    modulusLength: 2048,
    privateKeyEncoding: { type: "pkcs8", format: "pem" },
    publicKeyEncoding: { type: "spki", format: "pem" },
  });
  dartFunction = spawn("dart", ["run", "bin/server.dart"], {
    cwd: fileURLToPath(new URL("../../dart_functions/", import.meta.url)),
    env: {
      ...process.env,
      PORT: String(port),
      GCLOUD_PROJECT: "demo-openci",
      FUNCTION_TARGET: "process-webhook-task",
      GITHUB_APP_ID: "1",
      GITHUB_API_BASE_URL: githubUrl,
      GITHUB_BASE_URL: "https://github.com",
      GITHUB_APP_PRIVATE_KEY: privateKey,
    },
    stdio: ["ignore", "pipe", "pipe"],
  });
  let diagnostics = "";
  for (const stream of [dartFunction.stdout, dartFunction.stderr])
    stream.on("data", (chunk) => {
      diagnostics = (diagnostics + chunk).slice(-4000);
    });
  for (let attempt = 0; attempt < 120; attempt++) {
    try {
      if ((await fetch(`${dartFunctionUrl}__/health`, { signal: AbortSignal.timeout(1000) })).ok)
        return;
    } catch {
      /* Wait for the local Dart Function. */
    }
    if (dartFunction.exitCode != null) throw new Error(`Dart Function exited: ${diagnostics}`);
    await delay(250);
  }
  throw new Error(`Dart Function startup timed out: ${diagnostics}`);
});
after(async () => {
  if (dartFunction && dartFunction.exitCode == null) {
    dartFunction.kill();
    await once(dartFunction, "exit");
  }
  if (githubServer) await new Promise((resolve) => githubServer.close(resolve));
  await Promise.all(getApps().map((app) => deleteApp(app)));
});

async function graphql(query, variables) {
  const response = await fetch(`${service}:executeGraphql`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ query, variables }),
  });
  const result = await response.json();
  assert.ok(response.ok && !result.errors?.length, JSON.stringify(result));
  return result.data;
}

async function invoke(taskId) {
  const response = await fetch(dartFunctionUrl, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ taskId }),
    signal: AbortSignal.timeout(30000),
  });
  assert.equal(response.status, 200, await response.clone().text());
  return (await response.json()).result;
}

const source = (name, branch = "develop", trigger = "push") => `void main() {
  OpenCI.init(workflowName: '${name}', ciTriggers: [CITrigger.${trigger}(branch: '${branch}')]);
}`;

async function fixture(t, payloadChange = {}, eventType = "push") {
  const teamId = randomUUID(),
    connectionId = randomUUID(),
    deliveryId = randomUUID();
  const installationId = Number.parseInt(teamId.replaceAll("-", "").slice(0, 12), 16);
  const payload = {
    installation: { id: installationId },
    repository: { id: 10, name: "app", owner: { id: 20, login: "org" } },
    ref: "refs/heads/develop",
    after: sha,
    head_commit: { id: sha, message: "Commit\nBody" },
    ...payloadChange,
  };
  await graphql(
    `
      mutation Seed(
        $teamId: String!
        $connectionId: String!
        $installationId: Int64!
        $apiUrl: String!
      ) {
        team_insert(data: { id: $teamId, name: "Planner test", createdAt: 1, updatedAt: 1 })
        gitHubConnection_insert(
          data: {
            id: $connectionId
            teamId: $teamId
            githubApiBaseUrl: $apiUrl
            githubAppId: 1
            installationId: $installationId
            accountId: 20
            accountType: "Organization"
            accountLogin: "org"
            verifiedByUserId: "tester"
            verifiedByGitHubUserId: 1
            verifiedAt: 1
            status: "active"
          }
        )
      }
    `,
    { teamId, connectionId, installationId: String(installationId), apiUrl: githubUrl },
  );
  const github = {
    files: [
      { name: "first.dart", content: source("First") },
      { name: "second.dart", content: source("Second") },
      { name: "release.dart", content: source("Release", "release/*") },
    ],
    commitStatus: 200,
    tokenRequests: [],
    onContents: null,
  };
  installations.set(String(installationId), github);
  await enqueueWebhook(dc, { deliveryId, eventType, payload: JSON.stringify(payload) });
  const task = (await sdk.getWebhookTaskByDeliveryId(dc, { deliveryId })).data.webhookTask;
  t.after(async () => {
    installations.delete(String(installationId));
    await graphql(
      `
        mutation Cleanup($teamId: String!, $connectionId: String!, $taskId: String!) {
          buildJob_deleteMany(where: { teamId: { eq: $teamId } })
          webhookTask_delete(id: $taskId)
          gitHubConnection_delete(id: $connectionId)
          team_delete(id: $teamId)
        }
      `,
      { teamId, connectionId, taskId: task.id },
    );
  });
  const state = () =>
    graphql(
      `
        query State($taskId: String!, $teamId: String!) {
          webhookTask(id: $taskId) {
            status
            errorMessage
          }
          buildJobs(where: { teamId: { eq: $teamId } }, orderBy: { workflowFileName: ASC }) {
            id
            status
            owner
            repo
            teamId
            workflowName
            workflowFileName
            commitSha
            branch
            commitMessage
            pullRequestNumber
            runsOn
            runCount
            latestRunId
            installationId
            githubBaseUrl
            createdAt
            updatedAt
          }
        }
      `,
      { taskId: task.id, teamId },
    );
  return { taskId: task.id, teamId, connectionId, installationId, github, state };
}

test("ID dispatcher -> Dart Function -> GitHub -> atomic FSC jobs", async (t) => {
  const f = await fixture(t);
  await invokeProcessWebhookTask(dartFunctionUrl, f.taskId);
  const { webhookTask, buildJobs } = await f.state();
  assert.equal(webhookTask.status, "completed");
  assert.deepEqual(
    buildJobs.map((job) => job.workflowFileName),
    ["first.dart", "second.dart"],
  );
  assert.deepEqual(f.github.tokenRequests, [
    { repository_ids: [10], permissions: { contents: "read" } },
  ]);
  for (const job of buildJobs) {
    assert.equal(job.status, "QUEUED");
    assert.equal(job.teamId, f.teamId);
    assert.equal(job.commitSha, sha);
    assert.equal(job.branch, "develop");
    assert.equal(job.commitMessage, "Commit");
    assert.equal(job.runsOn, "macos-latest");
    assert.equal(job.runCount, "0");
    assert.equal(job.latestRunId, null);
    assert.equal(job.installationId, String(f.installationId));
    assert.equal(job.githubBaseUrl, "https://github.com");
    assert.ok(Number(job.createdAt) > 0);
    assert.equal(job.createdAt, job.updatedAt);
  }
});

test("concurrent Dart invocations publish one batch", async (t) => {
  const f = await fixture(t);
  const results = await Promise.all(Array.from({ length: 6 }, () => invoke(f.taskId)));
  assert.equal(results.filter((r) => r === "created").length, 1);
  assert.equal(results.filter((r) => r === "duplicate").length, 5);
  assert.equal((await f.state()).buildJobs.length, 2);
});

test("CompleteWebhookTask result hands created IDs to the capacity dispatcher", async (t) => {
  const f = await fixture(t);
  const jobId = randomUUID();
  const result = await sdk.completeWebhookTask(dc, {
    id: f.taskId,
    jobCount: 1,
    connectionId: f.connectionId,
    jobsJson: JSON.stringify([{ id: jobId, name: "Build", file: "ci.dart" }]),
    owner: "org",
    repo: "app",
    commitSha: sha,
    branch: "develop",
  });
  assert.deepEqual(createdBuildJobIds(result), [jobId]);
  const dispatchStore = new DataConnectDispatchStore(getDispatchDataConnect(app));
  try {
    let launched;
    await dispatchBuildJob(jobId, {
      store: dispatchStore,
      configuration: {
        cpu: 2,
        memoryMiB: 4096,
        image: "base-macos",
        cloudRunJob: "projects/demo-openci/locations/asia-northeast1/jobs/build-executor",
      },
      snapshot: async () => ({
        workers: [
          {
            name: "mac-1",
            last_seen: new Date().toISOString(),
            resources: {
              "org.cirruslabs.logical-cores": 2,
              "org.cirruslabs.memory-mib": 4096,
              "org.cirruslabs.tart-vms": 1,
            },
          },
        ],
        vms: [],
      }),
      enqueueRecovery: async () => {},
      launch: async (dispatch) => {
        launched = dispatch;
        return "test-operation";
      },
    });
    assert.equal(launched.jobId, jobId);
    assert.equal((await f.state()).buildJobs[0].status, "QUEUED");
  } finally {
    await graphql(
      `
        mutation CleanupDispatch($id: String!) {
          buildJobDispatch_deleteMany(where: { jobId: { eq: $id } })
        }
      `,
      { id: jobId },
    );
  }
});

test("redelivery after completion never resets a running job", async (t) => {
  const f = await fixture(t);
  await invoke(f.taskId);
  await graphql(
    `
      mutation Advance($teamId: String!) {
        buildJob_updateMany(
          where: { teamId: { eq: $teamId } }
          data: { status: "IN_PROGRESS", updatedAt: 42 }
        )
      }
    `,
    { teamId: f.teamId },
  );
  const state = await f.state();
  assert.equal(await invoke(f.taskId), "duplicate");
  assert.deepEqual(await f.state(), state);
});

test("bulk insert failures roll back both rows and task completion", async (t) => {
  const f = await fixture(t);
  await assert.rejects(
    sdk.completeWebhookTask(dc, {
      id: f.taskId,
      jobCount: 2,
      connectionId: f.connectionId,
      jobsJson: JSON.stringify([
        { id: "duplicate", name: "A", file: "a.dart" },
        { id: "duplicate", name: "B", file: "b.dart" },
      ]),
      owner: "org",
      repo: "app",
      commitSha: sha,
      branch: "develop",
    }),
  );
  assert.deepEqual(await f.state(), {
    webhookTask: { status: "pending", errorMessage: null },
    buildJobs: [],
  });
  assert.equal(await invoke(f.taskId), "created");
});

test("revoking a connection during GitHub access prevents publication", async (t) => {
  const f = await fixture(t);
  f.github.onContents = () =>
    graphql(
      `
        mutation Suspend($id: String!) {
          gitHubConnection_update(id: $id, data: { status: "suspended" })
        }
      `,
      { id: f.connectionId },
    );
  await assert.rejects(invokeProcessWebhookTask(dartFunctionUrl, f.taskId));
  assert.equal((await f.state()).webhookTask.status, "pending");
  assert.equal((await f.state()).buildJobs.length, 0);
});

test("temporary failures remain retryable; invalid source is terminal", async (t) => {
  const f = await fixture(t);
  f.github.commitStatus = 503;
  await assert.rejects(invokeProcessWebhookTask(dartFunctionUrl, f.taskId));
  assert.equal((await f.state()).webhookTask.status, "pending");
  f.github.commitStatus = 200;
  f.github.files = [
    {
      name: "bad.dart",
      content:
        "void main() { OpenCI.init(workflowName: 'Bad', ciTriggers: [CITrigger.push(branch: '*', whenChanged: [])]); }",
    },
  ];
  assert.equal(await invoke(f.taskId), "failed");
  assert.deepEqual(await f.state(), {
    webhookTask: { status: "failed", errorMessage: "invalid_workflow" },
    buildJobs: [],
  });
});

test("deleted refs, unconnected installations and unmatched workflows complete with zero jobs", async (t) => {
  for (const mode of ["deleted", "unconnected", "unmatched"]) {
    const f = await fixture(t, mode === "deleted" ? { deleted: true } : {});
    if (mode === "unconnected")
      await graphql(
        `
          mutation Suspend($id: String!) {
            gitHubConnection_update(id: $id, data: { status: "suspended" })
          }
        `,
        { id: f.connectionId },
      );
    if (mode === "unmatched")
      f.github.files = [{ name: "main.dart", content: source("Main", "main") }];
    assert.equal(await invoke(f.taskId), "created");
    assert.deepEqual(await f.state(), {
      webhookTask: { status: "completed", errorMessage: null },
      buildJobs: [],
    });
  }
});

test("PR plans persist the head SHA/branch while matching the base branch", async (t) => {
  const f = await fixture(
    t,
    {
      action: "opened",
      number: 7,
      pull_request: {
        title: "PR title",
        head: { sha, ref: "feature", repo: { id: 10 } },
        base: { ref: "develop", repo: { id: 10 } },
      },
    },
    "pull_request",
  );
  f.github.files = [{ name: "pr.dart", content: source("PR", "develop", "pullRequest") }];
  assert.equal(await invoke(f.taskId), "created");
  const [job] = (await f.state()).buildJobs;
  assert.equal(job.branch, "feature");
  assert.equal(job.commitSha, sha);
  assert.equal(job.pullRequestNumber, "7");
  assert.equal(job.commitMessage, "PR title");
});

test("fork or unknown PR sources are rejected before token issuance, workflow fetching or job creation", async (t) => {
  for (const headRepo of [{ id: 99 }, null, undefined, {}, { id: "10" }, { id: -10 }]) {
    const f = await fixture(
      t,
      {
        action: "synchronize",
        number: 7,
        pull_request: {
          title: "Untrusted PR",
          head: { sha, ref: "feature", repo: headRepo },
          base: { ref: "develop", repo: { id: 10 } },
        },
      },
      "pull_request",
    );
    f.github.files = [{ name: "pr.dart", content: source("PR", "develop", "pullRequest") }];
    assert.equal(await invoke(f.taskId), "failed");
    assert.equal(f.github.tokenRequests.length, 0);
    assert.deepEqual(await f.state(), {
      webhookTask: {
        status: "failed",
        errorMessage: headRepo?.id === 99 ? "untrusted_pull_request" : "invalid_payload",
      },
      buildJobs: [],
    });
    assert.equal(await invoke(f.taskId), "duplicate", "Redelivery must not bypass rejection");
    assert.equal(f.github.tokenRequests.length, 0);
  }
});

test("invalid payloads fail without contacting GitHub", async (t) => {
  const f = await fixture(t, { after: "main" });
  assert.equal(await invoke(f.taskId), "failed");
  assert.equal(f.github.tokenRequests.length, 0);
  assert.deepEqual(await f.state(), {
    webhookTask: { status: "failed", errorMessage: "invalid_payload" },
    buildJobs: [],
  });
});

test("end users cannot read tasks, publish builds, or fail tasks", async (t) => {
  const f = await fixture(t);
  for (const impersonate of [
    { unauthenticated: true },
    { authClaims: { sub: "user", firebase: { sign_in_provider: "password" } } },
  ]) {
    await assert.rejects(sdk.getWebhookTask(dc, { id: f.taskId }, { impersonate }));
    await assert.rejects(
      sdk.completeWebhookTask(dc, { id: f.taskId, jobsJson: "[]", jobCount: 0 }, { impersonate }),
    );
    await assert.rejects(
      sdk.rejectWebhookTask(dc, { id: f.taskId, reason: "invalid_payload" }, { impersonate }),
    );
  }
});
