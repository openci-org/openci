import assert from "node:assert/strict";
import { generateKeyPairSync, randomUUID } from "node:crypto";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { createServer } from "node:net";
import { createServer as createHttpServer } from "node:http";
import { setTimeout as delay } from "node:timers/promises";
import { fileURLToPath } from "node:url";
import { readFile } from "node:fs/promises";
import { after, before, test } from "node:test";
import { deleteApp, getApps, initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/webhooks-admin";
import { invokeProcessWebhookTask } from "../../lib/functions/build_job_planning.js";
import { enqueueWebhook } from "../../lib/functions/webhook_queue.js";
import { createdBuildJobIds, dispatchBuildJob } from "../../lib/functions/build_dispatch.js";
import { reportSkippedCheck, recoverSkippedChecks } from "../../lib/functions/skipped_checks.js";
import { DataConnectSkippedCheckStore } from "../../lib/functions/skipped_check_store.js";
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
const beforeSha = "b".repeat(40);
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
    if (path === "/repos/org/app/pulls/7") {
      return respond(200, {
        ...github.pullRequest,
        number: 7,
        changed_files: github.changedFiles.length,
      });
    }
    if (path === "/repos/org/app/pulls/7/files") {
      github.changedFilesCalls++;
      const start = (Number(url.searchParams.get("page")) - 1) * 100;
      return respond(200, github.changedFiles.slice(start, start + 100));
    }
    if (path.startsWith("/repos/org/app/compare/")) {
      github.changedFilesCalls++;
      return respond(github.comparisonStatus, {
        status: "ahead",
        base_commit: { sha: beforeSha },
        merge_base_commit: { sha: beforeSha },
        files: github.changedFiles,
      });
    }
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
    before: beforeSha,
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
    comparisonStatus: 200,
    changedFilesCalls: 0,
    changedFiles: [{ filename: "apps/stacked_pr/src/index.ts", status: "modified" }],
    pullRequest: payload.pull_request,
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
      syncQueuedCheck: async () => {},
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
        "void main() { OpenCI.init(workflowName: 'Bad', ciTriggers: [CITrigger.push(branch: '*', paths: [])]); }",
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

async function configurePathWorkflows(f) {
  const names = [
    "stacked_pr_ci",
    "website_ci",
    "genuineci_cli_ci",
    "openci_workflow_ci",
    "openci_shared_ci",
    "dart_functions_ci",
  ];
  f.github.files = await Promise.all(
    names.map(async (name) => ({
      name: name + ".dart",
      content: await readFile(
        new URL("../../../openci/" + name + ".dart", import.meta.url),
        "utf8",
      ),
    })),
  );
}

async function skippedState(f) {
  return graphql(
    "query Skips($id: String!) { webhookTask(id: $id) { status pathFilterReason } skippedWorkflowChecks(where: { webhookTaskId: { eq: $id } }, orderBy: { workflowFileName: ASC }) { id status workflowName workflowFileName commitSha comparisonBaseSha leaseOwner checkRunId } }",
    { id: f.taskId },
  );
}

async function makeDue(id) {
  await graphql(
    'mutation Due($id: String!) { skippedWorkflowCheck_update(id: $id, data: { nextAttemptAt: "2000-01-01T00:00:00Z", leaseExpiresAt: "2000-01-01T00:00:00Z" }) }',
    { id },
  );
}

test("real planner atomically selects one of six workflows, persists five skips and handles concurrent redelivery", async (t) => {
  const f = await fixture(t);
  await configurePathWorkflows(f);
  const results = await Promise.all([invoke(f.taskId), invoke(f.taskId)]);
  assert.ok(results.includes("created"));
  const state = await f.state();
  assert.deepEqual(
    state.buildJobs.map((j) => j.workflowName),
    ["Stacked PR CI"],
  );
  const skips = await skippedState(f);
  assert.equal(skips.skippedWorkflowChecks.length, 5);
  assert.equal(skips.webhookTask.pathFilterReason, null);
  for (const check of skips.skippedWorkflowChecks) {
    assert.equal(check.status, "pending");
    assert.equal(check.commitSha, sha);
    assert.equal(check.comparisonBaseSha, beforeSha);
  }
  assert.equal(await invoke(f.taskId), "duplicate");
  assert.deepEqual(await skippedState(f), skips);
  assert.ok(
    f.github.changedFilesCalls >= 1 && f.github.changedFilesCalls <= 2,
    "one comparison per attempted planner, never per workflow",
  );
});

test("all-skipped planning creates no jobs and transient comparisons instead run every applicable workflow", async (t) => {
  for (const unavailable of [false, true]) {
    const f = await fixture(t);
    await configurePathWorkflows(f);
    f.github.changedFiles = [{ filename: "README.md", status: "modified" }];
    f.github.comparisonStatus = unavailable ? 503 : 200;
    await invoke(f.taskId);
    const state = await f.state();
    const skips = await skippedState(f);
    assert.equal(state.buildJobs.length, unavailable ? 6 : 0);
    assert.equal(skips.skippedWorkflowChecks.length, unavailable ? 0 : 6);
    assert.equal(skips.webhookTask.pathFilterReason, unavailable ? "github_unavailable" : null);
    if (!unavailable) assert.deepEqual(createdBuildJobIds({ data: { jobs: [] } }), []);
    assert.equal(f.github.changedFilesCalls, 1);
  }
});

test("invalid skipped batches roll back jobs and task completion together", async (t) => {
  const f = await fixture(t);
  await assert.rejects(
    sdk.completeWebhookTask(dc, {
      id: f.taskId,
      connectionId: f.connectionId,
      owner: "org",
      repo: "app",
      commitSha: sha,
      branch: "develop",
      githubBaseUrl: "https://github.com",
      comparisonBaseSha: beforeSha,
      jobsJson: JSON.stringify([{ id: "job-" + f.taskId, name: "CI", file: "ci.dart" }]),
      jobCount: 1,
      skippedJson: JSON.stringify([{ id: "skip-" + f.taskId, name: "CI", file: "ci.dart" }]),
      skippedCount: 1,
    }),
  );
  assert.equal((await f.state()).webhookTask.status, "pending");
  assert.deepEqual((await f.state()).buildJobs, []);
  assert.deepEqual((await skippedState(f)).skippedWorkflowChecks, []);
});

test("skipped Check leases fence concurrent senders, expire, and reject unauthenticated access", async (t) => {
  const f = await fixture(t);
  await configurePathWorkflows(f);
  await invoke(f.taskId);
  const [row] = (await skippedState(f)).skippedWorkflowChecks;
  const claims = await Promise.all(
    ["one", "two"].map((leaseOwner) =>
      sdk.claimSkippedWorkflowCheck(dc, { id: row.id, leaseOwner }),
    ),
  );
  assert.equal(claims.filter((r) => r.data.claimed === 1).length, 1);
  await assert.rejects(
    sdk.completeSkippedWorkflowCheck(dc, { id: row.id, leaseOwner: "wrong", checkRunId: "42" }),
  );
  await makeDue(row.id);
  assert.equal(
    (await sdk.claimSkippedWorkflowCheck(dc, { id: row.id, leaseOwner: "recovery" })).data.claimed,
    1,
  );
  await sdk.completeSkippedWorkflowCheck(dc, {
    id: row.id,
    leaseOwner: "recovery",
    checkRunId: "42",
  });
  const reported = (await sdk.getSkippedWorkflowCheck(dc, { id: row.id })).data.check;
  assert.equal(reported.status, "reported");
  assert.equal(reported.checkRunId, "42");
  assert.equal(
    (await sdk.claimSkippedWorkflowCheck(dc, { id: row.id, leaseOwner: "later" })).data.claimed,
    0,
  );
  for (const impersonate of [
    { unauthenticated: true },
    { authClaims: { sub: "user", firebase: { sign_in_provider: "password" } } },
  ]) {
    await assert.rejects(sdk.getSkippedWorkflowCheck(dc, { id: row.id }, { impersonate }));
    await assert.rejects(sdk.getPendingSkippedWorkflowChecks(dc, { impersonate }));
    await assert.rejects(
      sdk.claimSkippedWorkflowCheck(dc, { id: row.id, leaseOwner: "user" }, { impersonate }),
    );
    await assert.rejects(
      sdk.completeSkippedWorkflowCheck(
        dc,
        { id: row.id, leaseOwner: "user", checkRunId: "9" },
        { impersonate },
      ),
    );
    await assert.rejects(
      sdk.retrySkippedWorkflowCheck(dc, { id: row.id, leaseOwner: "user" }, { impersonate }),
    );
  }
});

test("failed skipped reporting is recovered from SQL without replanning or creating jobs", async (t) => {
  const f = await fixture(t);
  await configurePathWorkflows(f);
  f.github.changedFiles = [{ filename: "README.md" }];
  await invoke(f.taskId);
  const [row] = (await skippedState(f)).skippedWorkflowChecks;
  const deps = {
    store: new DataConnectSkippedCheckStore(dc),
    report: async () => {
      throw new Error("GitHub unavailable");
    },
  };
  await assert.rejects(reportSkippedCheck(row.id, deps));
  assert.equal(
    (await sdk.getSkippedWorkflowCheck(dc, { id: row.id })).data.check.status,
    "pending",
  );
  assert.equal(
    (await sdk.getPendingSkippedWorkflowChecks(dc)).data.checks.some((c) => c.id === row.id),
    false,
  );
  await makeDue(row.id);
  deps.report = async () => "42";
  const errors = [];
  await recoverSkippedChecks(deps, (id) => errors.push(id));
  assert.deepEqual(errors, []);
  assert.equal(
    (await sdk.getSkippedWorkflowCheck(dc, { id: row.id })).data.check.status,
    "reported",
  );
  assert.deepEqual((await f.state()).buildJobs, []);
  assert.equal(f.github.changedFilesCalls, 1);
});

test("PR filtering and base retargets use the full PR diff with scoped PR-read permissions", async (t) => {
  for (const action of ["synchronize", "edited"]) {
    const f = await fixture(
      t,
      {
        action,
        number: 7,
        changes: { base: { ref: { from: "old-parent" } } },
        pull_request: {
          title: "Stacked PR",
          head: { sha, ref: "stack-child", repo: { id: 10 } },
          base: { sha: beforeSha, ref: "stack-parent", repo: { id: 10 } },
        },
      },
      "pull_request",
    );
    await configurePathWorkflows(f);
    await invoke(f.taskId);
    const jobs = (await f.state()).buildJobs;
    assert.deepEqual(
      jobs.map((j) => j.workflowName),
      ["Stacked PR CI"],
    );
    assert.equal(jobs[0].branch, "stack-child");
    assert.equal(jobs[0].pullRequestNumber, "7");
    assert.equal((await skippedState(f)).skippedWorkflowChecks.length, 5);
    assert.equal(f.github.changedFilesCalls, 1);
    assert.deepEqual(f.github.tokenRequests.at(-1), {
      repository_ids: [10],
      permissions: { contents: "read", pull_requests: "read" },
    });
  }
});
