import assert from "node:assert/strict";
import { createHash, generateKeyPairSync, randomUUID } from "node:crypto";
import { execFileSync, spawn } from "node:child_process";
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
import { getBuildExecution, getSupersededBuildJobs } from "@openci/dispatch-admin";
import { invokeProcessWebhookTask } from "../../lib/functions/build_job_planning.js";
import { enqueueWebhook } from "../../lib/functions/webhook_queue.js";
import { reportCompletedPullRequest } from "../../lib/functions/pull_request_result_function.js";
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
    if (req.method === "DELETE" && path === "/installation/token") {
      res.writeHead(204);
      return res.end();
    }
    if (tokenMatch) {
      let body = "";
      for await (const chunk of req) body += chunk;
      github.tokenRequests.push(JSON.parse(body));
      return respond(201, { token: `test-${installationId}` });
    }
    if (path === "/repos/org/app") return respond(200, { id: 10, owner: { id: 20 } });
    if (path === "/repos/org/app/git/ref/tags/v1.2.0") {
      return respond(200, {
        ref: "refs/tags/v1.2.0",
        object: { type: "tag", sha: "c".repeat(40) },
      });
    }
    if (path === `/repos/org/app/git/tags/${"c".repeat(40)}`) {
      return respond(200, { sha: "c".repeat(40), object: { type: "commit", sha } });
    }
    if (path === "/repos/org/app/pulls/7") {
      const pullRequest = structuredClone(github.pullRequest);
      const hook = github.onPullRequest;
      github.onPullRequest = null;
      if (hook) await hook();
      return respond(200, {
        ...pullRequest,
        number: 7,
        changed_files: github.changedFiles.length,
      });
    }
    if (path === "/repos/org/app/pulls/7/files") {
      github.changedFilesCalls++;
      const start = (Number(url.searchParams.get("page")) - 1) * 100;
      return respond(200, github.changedFiles.slice(start, start + 100));
    }
    if (path === "/repos/org/app/git/ref/heads/main" && github.baseTip) {
      return respond(200, {
        ref: "refs/heads/main",
        object: { type: "commit", sha: github.baseTip },
      });
    }
    if (path.startsWith("/repos/org/app/compare/")) {
      github.changedFilesCalls++;
      return respond(github.comparisonStatus, {
        status: github.baseTip ? "diverged" : "ahead",
        base_commit: { sha: github.baseTip ? path.split("/").at(-1).split("...")[0] : beforeSha },
        merge_base_commit: { sha: beforeSha },
        files: github.changedFiles,
      });
    }
    if (
      path.startsWith("/repos/org/app/git/commits/") &&
      github.revisions.has(path.split("/").at(-1))
    )
      return respond(github.commitStatus, {
        sha: path.split("/").at(-1),
        tree: { sha: "1".repeat(40) },
      });
    if (path === `/repos/org/app/git/trees/${"1".repeat(40)}`) {
      return respond(200, {
        truncated: false,
        tree: [{ path: "openci", type: "tree", sha: "2".repeat(40) }],
      });
    }
    if (
      path === `/repos/org/app/git/trees/${"2".repeat(40)}` &&
      url.searchParams.get("recursive") === "1"
    ) {
      return respond(200, {
        truncated: false,
        tree: github.files.map((file) => ({
          path: file.name,
          type: "blob",
          mode: "100644",
          size: Buffer.byteLength(file.content),
        })),
      });
    }
    if (!github.revisions.has(url.searchParams.get("ref"))) return respond(400, {});
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
    revisions: new Set([sha]),
    tokenRequests: [],
    onContents: null,
    comparisonStatus: 200,
    changedFilesCalls: 0,
    changedFiles: [{ filename: "apps/website/src/components/Pricing.astro", status: "modified" }],
    pullRequest: payload.pull_request ? { state: "open", ...payload.pull_request } : null,
  };
  installations.set(String(installationId), github);
  await enqueueWebhook(dc, { deliveryId, eventType, payload: JSON.stringify(payload) });
  const task = (await sdk.getWebhookTaskByDeliveryId(dc, { deliveryId })).data.webhookTask;
  const taskIds = [task.id];
  t.after(async () => {
    installations.delete(String(installationId));
    await graphql(
      `
        mutation Cleanup($teamId: String!, $connectionId: String!, $taskIds: [String!]!) {
          buildJob_deleteMany(where: { teamId: { eq: $teamId } })
          webhookTask_deleteMany(where: { id: { in: $taskIds } })
          gitHubConnection_delete(id: $connectionId)
          team_delete(id: $teamId)
        }
      `,
      { teamId, connectionId, taskIds },
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
            cancelPreviousRuns
            supersededByTaskId
            completedAt
            flutterVersion
            commitSha
            branch
            tagName
            commitMessage
            pullRequestNumber
            runsOn
            runCount
            latestRunId
            installationId
            repositoryId
            githubBaseUrl
            createdAt
            updatedAt
          }
        }
      `,
      { taskId: task.id, teamId },
    );
  return { taskId: task.id, taskIds, payload, teamId, connectionId, installationId, github, state };
}

test("ID dispatcher -> Dart Function -> GitHub -> atomic FSC jobs", async (t) => {
  const f = await fixture(t);
  f.github.files[0].name = "dashboard/ios/build.dart";
  f.github.files[1].name = "sdk/build.dart";
  f.github.files[0].content = `void main() {
    OpenCI.init(workflowName: 'First', ciTriggers: [CITrigger.push(branch: 'develop')], machine: MachineType.linuxSmall);
  }`;
  f.github.files[1].content = `void main() {
    OpenCI.init(workflowName: 'Second', ciTriggers: [CITrigger.push(branch: 'develop')], machine: MachineType.linuxMedium);
  }`;
  f.github.files.push({
    name: "android/aab.dart",
    content: `void main() {
      OpenCI.init(workflowName: 'AAB', ciTriggers: [CITrigger.push(branch: 'develop')], machine: MachineType.linuxLarge);
    }`,
  });
  await invokeProcessWebhookTask(dartFunctionUrl, f.taskId);
  const { webhookTask, buildJobs } = await f.state();
  assert.equal(webhookTask.status, "completed");
  assert.deepEqual(
    buildJobs.map((job) => [job.workflowFileName, job.runsOn]),
    [
      ["android/aab.dart", "linux-large"],
      ["dashboard/ios/build.dart", "linux-small"],
      ["sdk/build.dart", "linux-medium"],
    ],
  );
  assert.deepEqual(f.github.tokenRequests, [
    { repository_ids: [10], permissions: { contents: "read" } },
  ]);
  for (const job of buildJobs) {
    assert.equal(job.status, "QUEUED");
    assert.equal(job.teamId, f.teamId);
    assert.equal(job.commitSha, sha);
    assert.equal(job.branch, "develop");
    assert.equal(job.tagName, null);
    assert.equal(job.commitMessage, "Commit");
    assert.equal(job.runCount, "0");
    assert.equal(job.latestRunId, null);
    assert.equal(job.installationId, String(f.installationId));
    assert.equal(job.githubBaseUrl, "https://github.com");
    assert.ok(Number(job.createdAt) > 0);
    assert.equal(job.createdAt, job.updatedAt);
  }
});

test("published release -> annotated tag commit -> only release CD jobs", async (t) => {
  const f = await fixture(
    t,
    {
      action: "published",
      release: { id: 40, tag_name: "v1.2.0", draft: false, target_commitish: "moving-main" },
    },
    "release",
  );
  await configurePathWorkflows(f);
  assert.equal(await invoke(f.taskId), "created");
  assert.equal(await invoke(f.taskId), "duplicate");
  const { webhookTask, buildJobs } = await f.state();
  assert.equal(webhookTask.status, "completed");
  assert.deepEqual(
    buildJobs.map((job) => job.workflowFileName),
    [
      "dashboard/android/play_aab.dart",
      "dashboard/ios/testflight.dart",
      "firebase/functions_cd.dart",
    ],
  );
  for (const job of buildJobs) {
    assert.equal(job.commitSha, sha);
    assert.equal(job.branch, "refs/tags/v1.2.0");
    assert.equal(job.tagName, "v1.2.0");
    assert.equal(job.pullRequestNumber, null);
    assert.equal(job.status, "QUEUED");
  }
  const cd = buildJobs.find((job) => job.workflowFileName === "firebase/functions_cd.dart");
  const execution = await getBuildExecution(getDispatchDataConnect(), {
    id: "missing",
    jobId: cd.id,
    runId: "missing",
  });
  assert.equal(execution.data.job.tagName, "v1.2.0");
  assert.equal(f.github.changedFilesCalls, 0);
  assert.equal(f.github.tokenRequests.length, 2);
  assert.ok(
    f.github.tokenRequests.every(
      (r) =>
        JSON.stringify(r) ===
        JSON.stringify({ repository_ids: [10], permissions: { contents: "read" } }),
    ),
  );
});

test("repository-scoped connections plan only their selected repository", async (t) => {
  const f = await fixture(t);
  await graphql(
    'mutation Scope($id:String!) { gitHubConnection_update(id:$id,data:{repositoryId:10,repositoryName:"app"}) }',
    { id: f.connectionId },
  );
  await invoke(f.taskId);
  const { buildJobs } = await f.state();
  assert.equal(buildJobs.length, 2);
  assert.ok(buildJobs.every((job) => job.teamId === f.teamId && job.repositoryId === "10"));
  const job = (
    await getBuildExecution(getDispatchDataConnect(), {
      id: "missing",
      jobId: buildJobs[0].id,
      runId: "missing",
    })
  ).data.job;
  assert.equal(job.repositoryId, "10");
});

test("an installed but unconnected repository never obtains a planning token or creates jobs", async (t) => {
  const f = await fixture(t);
  await graphql(
    'mutation Scope($id:String!) { gitHubConnection_update(id:$id,data:{repositoryId:11,repositoryName:"another"}) }',
    { id: f.connectionId },
  );
  await assert.rejects(
    sdk.completeWebhookTask(dc, {
      id: f.taskId,
      jobCount: 1,
      connectionId: f.connectionId,
      repositoryId: "10",
      jobsJson: JSON.stringify([{ id: randomUUID(), name: "Unconnected", file: "ci.dart" }]),
      owner: "org",
      repo: "app",
      commitSha: sha,
      branch: "develop",
    }),
    /no longer active/,
  );
  assert.equal((await f.state()).webhookTask.status, "pending");
  await invoke(f.taskId);
  assert.deepEqual((await f.state()).buildJobs, []);
  assert.deepEqual(f.github.tokenRequests, []);
  assert.equal((await f.state()).webhookTask.status, "completed");
});

test("concurrent Dart invocations publish one batch", async (t) => {
  const f = await fixture(t);
  const results = await Promise.all(Array.from({ length: 6 }, () => invoke(f.taskId)));
  assert.equal(results.filter((r) => r === "created").length, 1);
  assert.equal(results.filter((r) => r === "duplicate").length, 5);
  assert.equal((await f.state()).buildJobs.length, 2);
});

test("workflow Flutter pins survive planning, SQL persistence and executor reads", async (t) => {
  const f = await fixture(t);
  f.github.files[0].content = `void main() {
    OpenCI.init(workflowName: 'First', ciTriggers: [CITrigger.push(branch: 'develop')], flutterVersion: FlutterVersion.v3_47_8.value);
  }`;
  await invoke(f.taskId);
  const { buildJobs } = await f.state();
  assert.deepEqual(
    buildJobs.map((job) => job.flutterVersion),
    ["3.47.8", null],
  );
  for (const job of buildJobs) {
    const execution = await getBuildExecution(getDispatchDataConnect(), {
      id: "unused-dispatch",
      jobId: job.id,
      runId: "unused-run",
    });
    assert.equal(execution.data.job.flutterVersion, job.flutterVersion);
  }
});

test("new plans reject the retired Linux machine", async (t) => {
  const f = await fixture(t);
  await assert.rejects(
    sdk.completeWebhookTask(dc, {
      id: f.taskId,
      jobCount: 1,
      connectionId: f.connectionId,
      jobsJson: JSON.stringify([
        { id: randomUUID(), name: "Build", file: "ci.dart", runsOn: "linux-latest" },
      ]),
      owner: "org",
      repo: "app",
      commitSha: sha,
      branch: "develop",
    }),
    /Invalid build job batch/,
  );
  assert.deepEqual((await f.state()).buildJobs, []);
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
    await dispatchBuildJob({
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

test("empty plans complete while unrelated builds and dispatches remain active", async (t) => {
  const active = await autoCancelFixture(t);
  await invoke(active.taskId);
  const [running] = (await active.state()).buildJobs;
  const dispatchId = randomUUID();
  // Different revisions force both cancellation queries to evaluate the job IDs.
  await graphql(
    `
      mutation StartUnrelatedBuild($jobId: String!, $dispatchId: String!, $newest: BuildJob_Data!) {
        buildJob_insert(data: $newest)
        buildJob_update(id: $jobId, data: { status: "IN_PROGRESS" })
        buildJobDispatch_insert(
          data: {
            id: $dispatchId
            jobId: $jobId
            activeJobId: $jobId
            vmName: $dispatchId
            cpu: 2
            memoryMiB: 4096
            image: "base-macos"
            cloudRunJob: "test-executor"
            state: "running"
            startDeadline: "2099-01-01T00:00:00Z"
            createdAt: "2026-01-01T00:00:00Z"
            updatedAt: "2026-01-01T00:00:00Z"
          }
        )
      }
    `,
    {
      jobId: running.id,
      dispatchId,
      newest: { ...running, id: randomUUID(), commitSha: "c".repeat(40) },
    },
  );
  const before = await active.state();
  const dispatchState = () =>
    graphql(
      `
        query Dispatch($id: String!) {
          buildJobDispatch(id: $id) {
            activeJobId
            state
            updatedAt
            finishedAt
          }
        }
      `,
      { id: dispatchId },
    );
  const beforeDispatch = await dispatchState();
  try {
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
      assert.equal(await invoke(f.taskId), "duplicate");
      assert.deepEqual(await active.state(), before);
      assert.deepEqual(await dispatchState(), beforeDispatch);
    }
  } finally {
    await graphql("mutation CleanupDispatch($id: String!) { buildJobDispatch_delete(id: $id) }", {
      id: dispatchId,
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

// Keep the expected job and skip lists independent of the planner output.
const pushWorkflowFiles = [
  "cli/publish.dart",
  "dashboard/android/patch.dart",
  "dashboard/ios/patch.dart",
  "dashboard/ios/patrol.dart",
  "dashboard/macos/publish.dart",
  "dashboard/web/hosting.dart",
  "firebase/dart_functions_ci.dart",
  "firebase/functions_ci.dart",
  "repo/dart_format.dart",
  "repo/workflow_scripts_ci.dart",
  "sdk/shared_ci.dart",
  "sdk/virtual_ble_ci.dart",
  "sdk/workflow_cd.dart",
  "sdk/workflow_ci.dart",
  "website/ci.dart",
];
const prWorkflowFiles = [
  "dashboard/android/patch.dart",
  "dashboard/ios/patch.dart",
  "dashboard/ios/patrol.dart",
  "dashboard/macos/ci.dart",
  "dashboard/web/hosting.dart",
  "firebase/dart_functions_ci.dart",
  "firebase/functions_ci.dart",
  "repo/dart_format.dart",
  "repo/workflow_scripts_ci.dart",
  "sdk/shared_ci.dart",
  "sdk/virtual_ble_ci.dart",
  "sdk/workflow_ci.dart",
  "website/ci.dart",
];

async function configurePathWorkflows(f, workflowFiles) {
  const directory = new URL("../../../openci/", import.meta.url);
  const names =
    workflowFiles ??
    execFileSync("git", ["ls-files", "-z", "--", "*.dart"], { cwd: directory, encoding: "utf8" })
      .split("\0")
      .filter(Boolean);
  f.github.files = await Promise.all(
    names.map(async (name) => ({
      name,
      content: await readFile(new URL(name, directory), "utf8"),
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

test("a website push queues Website CI once under concurrent redelivery", async (t) => {
  const f = await fixture(t);
  await configurePathWorkflows(f);
  const results = await Promise.all([invoke(f.taskId), invoke(f.taskId)]);
  assert.ok(results.includes("created"));
  const state = await f.state();
  const expectedJobs = ["website/ci.dart"];
  assert.deepEqual(
    state.buildJobs.map((job) => job.workflowFileName),
    expectedJobs,
  );
  const skips = await skippedState(f);
  assert.deepEqual(
    skips.skippedWorkflowChecks.map((check) => check.workflowFileName),
    pushWorkflowFiles.filter((file) => !expectedJobs.includes(file)),
  );
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

test("docs-only pushes skip builds and unavailable comparisons run every push workflow", async (t) => {
  for (const unavailable of [false, true]) {
    const f = await fixture(t);
    await configurePathWorkflows(f);
    f.github.changedFiles = [{ filename: "README.md", status: "modified" }];
    f.github.comparisonStatus = unavailable ? 503 : 200;
    await invoke(f.taskId);
    const state = await f.state();
    const skips = await skippedState(f);
    assert.deepEqual(
      state.buildJobs.map((job) => job.workflowFileName),
      unavailable ? pushWorkflowFiles : [],
    );
    assert.deepEqual(
      skips.skippedWorkflowChecks.map((check) => check.workflowFileName),
      unavailable ? [] : pushWorkflowFiles,
    );
    assert.equal(skips.webhookTask.pathFilterReason, unavailable ? "github_unavailable" : null);
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

test("skipped patch checks recover from SQL without replanning or creating jobs", async (t) => {
  const f = await fixture(t);
  const patchFiles = ["dashboard/android/patch.dart", "dashboard/ios/patch.dart"];
  await configurePathWorkflows(f, patchFiles);
  f.github.changedFiles = [{ filename: "README.md" }];
  await invoke(f.taskId);
  const { skippedWorkflowChecks } = await skippedState(f);
  assert.deepEqual(
    skippedWorkflowChecks.map((check) => check.workflowFileName),
    patchFiles,
  );
  const [row] = skippedWorkflowChecks;
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
  const { buildJobs } = await f.state();
  assert.deepEqual(buildJobs, []);
  assert.deepEqual(createdBuildJobIds({ data: { jobs: buildJobs } }), []);
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
          title: "Update website pricing",
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
      ["Website CI"],
    );
    assert.equal(jobs[0].branch, "stack-child");
    assert.equal(jobs[0].pullRequestNumber, "7");
    assert.deepEqual(
      (await skippedState(f)).skippedWorkflowChecks.map((check) => check.workflowFileName),
      prWorkflowFiles.filter((file) => file !== "website/ci.dart"),
    );
    assert.equal(f.github.changedFilesCalls, 1);
    assert.ok(
      f.github.tokenRequests.some(
        (request) =>
          request.repository_ids[0] === 10 &&
          request.permissions.contents === "read" &&
          request.permissions.pull_requests === "read",
      ),
    );
  }
});

async function autoCancelFixture(t, payloadChange = {}) {
  const f = await fixture(
    t,
    {
      action: "synchronize",
      number: 7,
      pull_request: {
        title: "PR",
        state: "open",
        head: { sha, ref: "feature", repo: { id: 10 } },
        base: { sha: beforeSha, ref: "main", repo: { id: 10 } },
      },
      ...payloadChange,
    },
    "pull_request",
  );
  f.github.files = [
    {
      name: "ci.dart",
      content:
        "void main() { OpenCI.init(workflowName: 'CI', ciTriggers: [CITrigger.pullRequest(branch: '*')], cancelPreviousRuns: true); }",
    },
    { name: "deploy.dart", content: source("Deploy", "*", "pullRequest") },
  ];
  return f;
}

async function nextRevision(f, headSha, makeCurrent = true) {
  const payload = structuredClone(f.payload);
  payload.action = "synchronize";
  delete payload.changes;
  payload.pull_request.head.sha = headSha;
  f.github.revisions.add(headSha);
  if (makeCurrent) f.github.pullRequest = payload.pull_request;
  const deliveryId = randomUUID();
  await enqueueWebhook(dc, {
    deliveryId,
    eventType: "pull_request",
    payload: JSON.stringify(payload),
  });
  const taskId = (await sdk.getWebhookTaskByDeliveryId(dc, { deliveryId })).data.webhookTask.id;
  f.taskIds.push(taskId);
  return taskId;
}

async function beginPlanning(f, taskId) {
  const id = createHash("sha256")
    .update(JSON.stringify([f.connectionId, 10, 7]))
    .digest("hex");
  const token = randomUUID();
  await sdk.beginPullRequestPlanning(dc, {
    id,
    token,
    taskId,
    connectionId: f.connectionId,
    repositoryId: "10",
    pullRequestNumber: "7",
  });
  return { planningId: id, planningToken: token };
}

function completion(f, taskId, fence, headSha = "c".repeat(40)) {
  return {
    id: taskId,
    ...fence,
    jobCount: 1,
    connectionId: f.connectionId,
    owner: "org",
    repo: "app",
    commitSha: headSha,
    branch: "feature",
    pullRequestNumber: "7",
    githubBaseUrl: "https://github.com",
    jobsJson: JSON.stringify([
      { id: randomUUID(), name: "CI", file: "ci.dart", cancelPreviousRuns: true },
    ]),
  };
}

test("new PR revisions cancel only older opted-in jobs in the exact scope", async (t) => {
  const f = await autoCancelFixture(t);
  await invoke(f.taskId);
  const old = (await f.state()).buildJobs.find((j) => j.workflowFileName === "ci.dart");
  const headSha = "c".repeat(40);
  const protectedRows = [
    { workflowFileName: "other.dart" },
    { pullRequestNumber: "8" },
    { pullRequestNumber: null },
    { commitSha: headSha },
    { status: "SUCCESS" },
    { status: "FAILURE" },
    { status: "CANCELLED" },
    { cancelPreviousRuns: false },
    { owner: "other" },
    { repo: "other" },
    { githubBaseUrl: "https://enterprise.test" },
    { installationId: "999999" },
  ].map((patch) => ({ ...old, id: randomUUID(), ...patch }));
  const running = { ...old, id: randomUUID(), status: "IN_PROGRESS" };
  await graphql("mutation Seed($jobs: [BuildJob_Data!]!) { buildJob_insertMany(data: $jobs) }", {
    jobs: [...protectedRows, running],
  });
  const taskId = await nextRevision(f, headSha);
  await invoke(taskId);
  const rows = (await f.state()).buildJobs;
  for (const id of [old.id, running.id]) {
    const cancelled = rows.find((j) => j.id === id);
    assert.equal(cancelled.status, "CANCELLED");
    assert.equal(cancelled.supersededByTaskId, taskId);
  }
  assert.ok(rows.find((j) => j.id === old.id).completedAt);
  for (const expected of protectedRows)
    assert.deepEqual(
      rows.find((j) => j.id === expected.id),
      expected,
    );
  assert.equal(
    rows.filter((j) => j.workflowFileName === "deploy.dart").every((j) => j.status === "QUEUED"),
    true,
  );
  const notifications = await new DataConnectDispatchStore(getDispatchDataConnect()).superseded(
    taskId,
    "",
  );
  assert.deepEqual(new Set(notifications.map((j) => j.id)), new Set([old.id, running.id]));
  assert.equal(await invoke(taskId), "duplicate");
  assert.deepEqual((await f.state()).buildJobs, rows);
});

test("delayed old PR deliveries cannot cancel or enqueue an opted-in obsolete revision", async (t) => {
  const f = await autoCancelFixture(t);
  const latestTask = await nextRevision(f, "c".repeat(40));
  await invoke(latestTask);
  await invoke(f.taskId);
  const rows = (await f.state()).buildJobs;
  const ci = rows.filter((j) => j.workflowFileName === "ci.dart");
  assert.equal(ci.length, 1);
  assert.equal(ci[0].commitSha, "c".repeat(40));
  assert.equal(ci[0].status, "QUEUED");
  assert.equal(rows.filter((j) => j.workflowFileName === "deploy.dart").length, 1);
});

test("concurrent deliveries of the same PR revision complete without a 503 or duplicate jobs", async (t) => {
  const f = await autoCancelFixture(t);
  const observed = Promise.withResolvers();
  const release = Promise.withResolvers();
  f.github.onPullRequest = async () => {
    observed.resolve();
    await release.promise;
  };
  const firstRequest = fetch(dartFunctionUrl, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ taskId: f.taskId }),
  });
  let expected;
  try {
    await Promise.race([
      observed.promise,
      firstRequest.then(() => assert.fail("first request completed before observation")),
    ]);
    await invoke(await nextRevision(f, sha));
    expected = (await f.state()).buildJobs;
    assert.equal(expected.length, 2);
  } finally {
    release.resolve();
  }
  const response = await firstRequest;
  assert.equal(response.status, 200, await response.text());
  assert.equal((await f.state()).webhookTask.status, "completed");
  assert.deepEqual((await f.state()).buildJobs, expected);
});

test("a stale in-flight GitHub response cannot overwrite a newer completed PR plan", async (t) => {
  const f = await autoCancelFixture(t);
  const observed = Promise.withResolvers();
  const release = Promise.withResolvers();
  f.github.onPullRequest = async () => {
    observed.resolve();
    await release.promise;
  };
  const oldRequest = fetch(dartFunctionUrl, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ taskId: f.taskId }),
  });
  try {
    await Promise.race([
      observed.promise,
      oldRequest.then(() => assert.fail("old request completed before observation")),
    ]);
    await invoke(await nextRevision(f, "c".repeat(40)));
  } finally {
    release.resolve();
  }
  assert.equal(
    (await oldRequest).status,
    200,
    "lost observation must be refreshed in this request",
  );
  assert.equal((await f.state()).webhookTask.status, "completed");
  assert.equal(await invoke(f.taskId), "duplicate");
  const ci = (await f.state()).buildJobs.filter((j) => j.workflowFileName === "ci.dart");
  assert.deepEqual(
    ci.map((j) => [j.commitSha, j.status]),
    [["c".repeat(40), "QUEUED"]],
  );
});

test("a stale base change completes while the force-pushed revision still owns the fence", async (t) => {
  const f = await autoCancelFixture(t, {
    action: "edited",
    changes: { base: { ref: { from: "stack-parent" } } },
  });
  const currentSha = "c".repeat(40);
  let currentCompletion;
  // GitHub has captured the old head for this read. Acquire the new revision's
  // fence before delivering that response to the first planner.
  f.github.onPullRequest = async () => {
    const currentTask = await nextRevision(f, currentSha);
    const fence = await beginPlanning(f, currentTask);
    currentCompletion = completion(f, currentTask, fence, currentSha);
  };

  assert.equal(await invoke(f.taskId), "created");
  const before = await f.state();
  assert.equal(before.webhookTask.status, "completed");
  assert.deepEqual(before.buildJobs, []);

  await sdk.completeWebhookTask(dc, currentCompletion);
  assert.equal(await invoke(f.taskId), "duplicate");
  const { buildJobs } = await f.state();
  assert.deepEqual(
    buildJobs.map((job) => job.commitSha),
    [currentSha],
  );
});

test("cancellation rolls back with an invalid plan, and unfenced PR writes cannot opt in", async (t) => {
  const f = await autoCancelFixture(t);
  await invoke(f.taskId);
  const before = (await f.state()).buildJobs;
  const taskId = await nextRevision(f, "c".repeat(40));
  const fence = await beginPlanning(f, taskId);
  const vars = completion(f, taskId, fence);
  await assert.rejects(
    sdk.completeWebhookTask(dc, {
      ...vars,
      skippedCount: 1,
      comparisonBaseSha: beforeSha,
      skippedJson: JSON.stringify([{ id: randomUUID(), name: "CI", file: "ci.dart" }]),
    }),
  );
  assert.deepEqual((await f.state()).buildJobs, before);
  await assert.rejects(
    sdk.completeWebhookTask(dc, { ...vars, planningId: null, planningToken: null }),
  );
  assert.deepEqual((await f.state()).buildJobs, before);
  const result = await sdk.completeWebhookTask(dc, vars);
  assert.equal(result.data.cancelled, 1);
});

test("same-SHA deliveries coalesce and returning to an automatically cancelled revision validates again", async (t) => {
  const f = await autoCancelFixture(t);
  await invoke(f.taskId);
  await invoke(await nextRevision(f, sha));
  assert.equal(
    (await f.state()).buildJobs.filter(
      (j) => j.workflowFileName === "ci.dart" && j.status === "QUEUED",
    ).length,
    1,
  );
  const taskId = await nextRevision(f, "c".repeat(40));
  await invoke(taskId);
  assert.equal((await f.state()).buildJobs.filter((j) => j.status === "CANCELLED").length, 1);
  await invoke(await nextRevision(f, sha));
  const ci = (await f.state()).buildJobs.filter(
    (j) => j.workflowFileName === "ci.dart" && j.status === "QUEUED",
  );
  assert.equal(ci.length, 1);
  assert.equal(ci[0].commitSha, sha);
});

test("returning to a successful PR revision reuses it and cancels the intervening job", async (t) => {
  const f = await autoCancelFixture(t);
  await invoke(f.taskId);
  const first = (await f.state()).buildJobs.find((job) => job.workflowFileName === "ci.dart");
  await graphql(
    'mutation Succeed($id: String!) { buildJob_update(id: $id, data: { status: "SUCCESS", completedAt: 42 }) }',
    { id: first.id },
  );

  const interveningSha = "c".repeat(40);
  await invoke(await nextRevision(f, interveningSha));
  const returnTask = await nextRevision(f, sha);
  await invoke(returnTask);

  const jobs = (await f.state()).buildJobs.filter((job) => job.workflowFileName === "ci.dart");
  assert.equal(jobs.length, 2);
  assert.equal(jobs.find((job) => job.id === first.id).status, "SUCCESS");
  const intervening = jobs.find((job) => job.commitSha === interveningSha);
  assert.equal(intervening.status, "CANCELLED");
  assert.equal(intervening.supersededByTaskId, returnTask);
});

test("planning fences and cancellation notifications deny direct client access", async (t) => {
  const f = await autoCancelFixture(t);
  for (const impersonate of [{ unauthenticated: true }, { authClaims: { sub: "user" } }]) {
    await assert.rejects(
      sdk.beginPullRequestPlanning(
        dc,
        {
          id: randomUUID(),
          token: randomUUID(),
          taskId: f.taskId,
          connectionId: f.connectionId,
          repositoryId: "10",
          pullRequestNumber: "7",
        },
        { impersonate },
      ),
    );
    await assert.rejects(
      getSupersededBuildJobs(getDispatchDataConnect(), { taskId: f.taskId }, { impersonate }),
    );
  }
});

test("path-skipped revisions and disabled new workflows preserve existing PR runs", async (t) => {
  for (const disabled of [false, true]) {
    const f = await autoCancelFixture(t);
    await invoke(f.taskId);
    const old = (await f.state()).buildJobs.find((j) => j.workflowFileName === "ci.dart");
    f.github.files = [
      {
        name: "ci.dart",
        content: disabled
          ? source("CI", "*", "pullRequest")
          : "void main() { OpenCI.init(workflowName: 'CI', ciTriggers: [CITrigger.pullRequest(branch: '*', paths: ['mobile/**'])], cancelPreviousRuns: true); }",
      },
    ];
    await invoke(await nextRevision(f, "c".repeat(40)));
    assert.equal((await f.state()).buildJobs.find((j) => j.id === old.id).status, "QUEUED");
  }
});

test("one team's opted-in PR cannot cancel an identical job in another team", async (t) => {
  const one = await autoCancelFixture(t),
    two = await autoCancelFixture(t);
  await invoke(one.taskId);
  await invoke(two.taskId);
  const before = (await two.state()).buildJobs;
  await invoke(await nextRevision(one, "c".repeat(40)));
  assert.deepEqual((await two.state()).buildJobs, before);
});

for (const status of ["QUEUED", "IN_PROGRESS", "SUCCESS", "FAILURE", "CANCELLED"]) {
  test(`equivalent delivery reuses ${status} jobs without resetting results or Checks`, async (t) => {
    const f = await autoCancelFixture(t);
    await invoke(f.taskId);
    await graphql(
      'mutation Advance($teamId: String!, $status: String!) { buildJob_updateMany(where: { teamId: { eq: $teamId } }, data: { status: $status, runCount: 2, latestRunId: "existing-run", checkRunId: "existing-check", completedAt: 42 }) }',
      { teamId: f.teamId, status },
    );
    const before = (await f.state()).buildJobs;
    const taskId = await nextRevision(f, sha);
    await invoke(taskId);
    assert.deepEqual((await f.state()).buildJobs, before);
    assert.equal(await invoke(taskId), "duplicate");
  });
}

test("concurrent different delivery IDs converge on one execution per workflow", async (t) => {
  const f = await autoCancelFixture(t);
  const tasks = [f.taskId, await nextRevision(f, sha), await nextRevision(f, sha)];
  const results = await Promise.all(
    tasks.map((taskId) =>
      fetch(dartFunctionUrl, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ taskId }),
      }),
    ),
  );
  assert.ok(results.some((response) => response.status === 200));
  for (const [index, response] of results.entries()) {
    assert.ok([200, 503].includes(response.status));
    if (response.status === 503) await invoke(tasks[index]);
  }
  const rows = (await f.state()).buildJobs;
  assert.equal(rows.length, 2);
  assert.ok(rows.every((job) => job.status === "QUEUED" && job.runCount === "0"));
  assert.deepEqual(
    new Set(rows.map((job) => job.workflowFileName)),
    new Set(["ci.dart", "deploy.dart"]),
  );
});

test("deduplicated completion returns the original job ID for Check and dispatch synchronization", async (t) => {
  const f = await autoCancelFixture(t);
  await invoke(f.taskId);
  const old = (await f.state()).buildJobs.find((job) => job.workflowFileName === "ci.dart");
  const { buildJob } = await graphql(
    "query Key($id: String!) { buildJob(id: $id) { webhookExecutionKey } }",
    { id: old.id },
  );
  const taskId = await nextRevision(f, sha);
  const fence = await beginPlanning(f, taskId);
  const vars = completion(f, taskId, fence, sha);
  const jobs = JSON.parse(vars.jobsJson);
  jobs[0].webhookExecutionKey = buildJob.webhookExecutionKey;
  const result = await sdk.completeWebhookTask(dc, { ...vars, jobsJson: JSON.stringify(jobs) });
  assert.deepEqual(createdBuildJobIds({ data: result.data }), [old.id]);
  assert.equal(result.data.cancelled, 0);
  assert.equal((await f.state()).buildJobs.length, 2);
});

test("explicit same-SHA jobs without a webhook key remain independent of duplicate notifications", async (t) => {
  const f = await autoCancelFixture(t);
  await invoke(f.taskId);
  const taskId = await nextRevision(f, sha);
  const fence = await beginPlanning(f, taskId);
  const result = await sdk.completeWebhookTask(dc, completion(f, taskId, fence, sha));
  assert.equal(result.data.jobs.length, 1);
  const before = (await f.state()).buildJobs;
  assert.equal(before.filter((job) => job.workflowFileName === "ci.dart").length, 2);
  await invoke(await nextRevision(f, sha));
  assert.deepEqual((await f.state()).buildJobs, before);
});

async function changedContext(f, change) {
  const payload = structuredClone(f.payload);
  change(payload);
  f.github.pullRequest = payload.pull_request;
  const deliveryId = randomUUID();
  await enqueueWebhook(dc, {
    deliveryId,
    eventType: "pull_request",
    payload: JSON.stringify(payload),
  });
  const taskId = (await sdk.getWebhookTaskByDeliveryId(dc, { deliveryId })).data.webhookTask.id;
  f.taskIds.push(taskId);
  return taskId;
}

test("a stale completion replans the current base once and coalesces with a real PR delivery", async (t) => {
  const f = await autoCancelFixture(t);
  f.github.files = ["website", "android"].map((name) => ({
    name: name + ".dart",
    content: `void main() { OpenCI.init(workflowName: '${name}', ciTriggers: [CITrigger.pullRequest(branch: '*', paths: ['apps/${name}/**'])]); }`,
  }));
  await invoke(f.taskId);
  const [original] = (await f.state()).buildJobs;
  assert.equal(original.workflowName, "website");
  await graphql(
    'mutation Finish($id: String!) { buildJob_update(id: $id, data: {status: "SUCCESS", runCount: 1, latestRunId: "original"}) }',
    { id: original.id },
  );
  const [finished] = (await f.state()).buildJobs;
  const latest = {
    id: "dispatch",
    teamId: f.teamId,
    runId: "original",
    outcome: "success",
    finishedAt: "2026-01-02T00:01:00Z",
    pullRequestBaseBranch: "main",
    pullRequestBaseSha: beforeSha,
  };
  const store = {
    pullRequestCommentExecution: async () => ({ job: finished, latest }),
    context: async () => ({ connection: { accountId: "20" } }),
  };
  const baseAtCompletion = "c".repeat(40);
  const github = {
    options: { apiBaseUrl: githubUrl, appId: "1" },
    currentPullRequestRevision: async () => ({
      number: 7,
      repositoryId: 10,
      head: { ref: "feature", sha },
      base: { ref: "main", sha: baseAtCompletion },
    }),
  };
  const deliveries = new Set();
  const persist = async (delivery) => {
    await enqueueWebhook(dc, delivery);
    deliveries.add(delivery.deliveryId);
  };
  await Promise.all(
    [1, 2].map(() => reportCompletedPullRequest(original.id, latest.id, store, github, persist)),
  );
  assert.equal(deliveries.size, 1);
  const recovery = (await sdk.getWebhookTaskByDeliveryId(dc, { deliveryId: [...deliveries][0] }))
    .data.webhookTask;
  f.taskIds.push(recovery.id);

  // The base advances again while the task waits. PR metadata still shows the
  // original base; the authoritative branch and the pinned diff select the new validation.
  f.github.baseTip = "d".repeat(40);
  await invoke(recovery.id);
  assert.equal(await invoke(recovery.id), "duplicate");
  const { buildJobs } = await f.state();
  assert.deepEqual(
    buildJobs.find((j) => j.id === original.id),
    finished,
  );
  assert.deepEqual(
    buildJobs
      .filter((j) => j.id !== original.id)
      .map((j) => [j.workflowName, j.status, j.commitSha]),
    [["website", "QUEUED", sha]],
  );
  const skips = (await skippedState({ taskId: recovery.id })).skippedWorkflowChecks;
  assert.deepEqual(
    skips.map((check) => [check.workflowName, check.comparisonBaseSha]),
    [["android", f.github.baseTip]],
  );
  await invoke(
    await changedContext(f, (payload) => {
      payload.pull_request.base.sha = f.github.baseTip;
    }),
  );
  assert.deepEqual((await f.state()).buildJobs, buildJobs);
});

test("returning to a planned base replaces only a terminal job that actually tested a different base", async (t) => {
  const f = await autoCancelFixture(t);
  await invoke(f.taskId);
  const jobs = (await f.state()).buildJobs;
  const at = "2026-01-02T00:01:00Z";
  for (const job of jobs) {
    const id = randomUUID();
    t.after(() =>
      graphql("mutation Cleanup($id: String!) { buildJobDispatch_delete(id:$id) }", { id }),
    );
    await graphql(
      `
        mutation Finished($job: String!, $run: String!, $data: BuildJobDispatch_Data!) {
          buildJob_update(id: $job, data: { status: "SUCCESS", runCount: 1, latestRunId: $run })
          buildJobDispatch_insert(data: $data)
        }
      `,
      {
        job: job.id,
        run: id,
        data: {
          id,
          runId: id,
          jobId: job.id,
          teamId: f.teamId,
          vmName: id,
          cpu: 2,
          memoryMiB: 4096,
          image: "base-macos",
          cloudRunJob: "test-executor",
          state: "completed",
          outcome: "success",
          startDeadline: at,
          createdAt: at,
          updatedAt: at,
          finishedAt: at,
          pullRequestBaseBranch: "main",
          pullRequestBaseSha: job.workflowFileName === "ci.dart" ? "c".repeat(40) : beforeSha,
        },
      },
    );
  }
  f.github.baseTip = beforeSha;
  const recovery = async (teamId = f.teamId) => {
    const deliveryId = randomUUID();
    await enqueueWebhook(dc, {
      deliveryId,
      eventType: "pull_request",
      payload: JSON.stringify({
        ...f.payload,
        action: "openci_base_changed",
        openci_team_id: teamId,
      }),
    });
    const task = (await sdk.getWebhookTaskByDeliveryId(dc, { deliveryId })).data.webhookTask;
    f.taskIds.push(task.id);
    await invoke(task.id);
  };
  await recovery("previous-team");
  assert.ok((await f.state()).buildJobs.every((j) => j.status === "SUCCESS"));
  await recovery();
  await recovery();
  const rows = (await f.state()).buildJobs;
  assert.deepEqual(
    rows.filter((j) => j.status === "QUEUED").map((j) => j.workflowFileName),
    ["ci.dart"],
  );
  assert.deepEqual(
    rows
      .filter((j) => j.status === "SUCCESS")
      .map((j) => j.id)
      .sort(),
    jobs.map((j) => j.id).sort(),
  );
});

test("same-head base SHA, target and SDK changes require new validation", async (t) => {
  const f = await autoCancelFixture(t);
  await invoke(f.taskId);
  await invoke(
    await changedContext(f, (payload) => {
      payload.pull_request.base.sha = "d".repeat(40);
    }),
  );
  await invoke(
    await changedContext(f, (payload) => {
      payload.pull_request.base.ref = "release";
    }),
  );
  f.github.files[0].content = f.github.files[0].content.replace(
    "OpenCI.init(",
    "OpenCI.init(flutterVersion: '3.47.8', ",
  );
  await invoke(await nextRevision(f, sha));
  const rows = (await f.state()).buildJobs;
  assert.equal(rows.filter((job) => job.workflowFileName === "ci.dart").length, 4);
  assert.equal(rows.filter((job) => job.workflowFileName === "deploy.dart").length, 3);
});

test("equivalent skipped plans retain one outbox row and its reported Check", async (t) => {
  const f = await autoCancelFixture(t);
  f.github.files = [
    {
      name: "ci.dart",
      content:
        "void main() { OpenCI.init(workflowName: 'CI', ciTriggers: [CITrigger.pullRequest(branch: '*', paths: ['mobile/**'])]); }",
    },
  ];
  await invoke(f.taskId);
  const [row] = (await skippedState(f)).skippedWorkflowChecks;
  await sdk.claimSkippedWorkflowCheck(dc, { id: row.id, leaseOwner: "reporter" });
  await sdk.completeSkippedWorkflowCheck(dc, {
    id: row.id,
    leaseOwner: "reporter",
    checkRunId: "42",
  });
  const before = (await skippedState(f)).skippedWorkflowChecks;
  await invoke(await nextRevision(f, sha));
  const state = await graphql(
    "query Skips($connectionId: String!) { skippedWorkflowChecks(where: { connectionId: { eq: $connectionId } }) { id status workflowName workflowFileName commitSha comparisonBaseSha leaseOwner checkRunId } }",
    { connectionId: f.connectionId },
  );
  assert.deepEqual(state.skippedWorkflowChecks, before);
  assert.deepEqual((await f.state()).buildJobs, []);
});

test("execution keys require fenced PR plans and reject malformed batches atomically", async (t) => {
  const f = await autoCancelFixture(t);
  const fence = await beginPlanning(f, f.taskId);
  const vars = completion(f, f.taskId, fence, sha);
  const baseJob = JSON.parse(vars.jobsJson)[0];
  for (const patch of [
    { planningId: null, planningToken: null },
    { pullRequestNumber: null },
    { jobsJson: JSON.stringify([{ ...baseJob, webhookExecutionKey: "bad-key" }]) },
  ])
    await assert.rejects(
      sdk.completeWebhookTask(dc, {
        ...vars,
        jobsJson: JSON.stringify([{ ...baseJob, webhookExecutionKey: "f".repeat(64) }]),
        ...patch,
      }),
    );
  assert.equal((await f.state()).webhookTask.status, "pending");
  assert.deepEqual((await f.state()).buildJobs, []);
});

async function prAction(f, action, { merged = false, makeCurrent = true } = {}) {
  const payload = structuredClone(f.payload);
  payload.action = action;
  payload.pull_request.state = action === "closed" ? "closed" : "open";
  payload.pull_request.merged = merged;
  if (makeCurrent) f.github.pullRequest = structuredClone(payload.pull_request);
  const deliveryId = randomUUID();
  await enqueueWebhook(dc, {
    deliveryId,
    eventType: "pull_request",
    payload: JSON.stringify(payload),
  });
  const taskId = (await sdk.getWebhookTaskByDeliveryId(dc, { deliveryId })).data.webhookTask.id;
  f.taskIds.push(taskId);
  return taskId;
}

for (const merged of [false, true]) {
  test(`PR close (merged=${merged}) cancels all active workflows once within its scope`, async (t) => {
    const f = await autoCancelFixture(t);
    const other = await autoCancelFixture(t);
    await invoke(f.taskId);
    await invoke(other.taskId);
    const otherRows = (await other.state()).buildJobs;
    const old = (await f.state()).buildJobs[0];
    const protectedRows = [
      { pullRequestNumber: "8" },
      { pullRequestNumber: null },
      { status: "SUCCESS" },
      { status: "FAILURE" },
      { status: "CANCELLED" },
      { owner: "other" },
      { repo: "other" },
      { githubBaseUrl: "https://enterprise.test" },
      { installationId: "999999" },
    ].map((patch) => ({ ...old, id: randomUUID(), ...patch }));
    const running = { ...old, id: randomUUID(), status: "IN_PROGRESS", cancelPreviousRuns: false };
    await graphql("mutation Seed($jobs: [BuildJob_Data!]!) { buildJob_insertMany(data: $jobs) }", {
      jobs: [...protectedRows, running],
    });
    // A close must work even if the original commit/workflow is inaccessible.
    f.github.commitStatus = 404;
    const taskId = await prAction(f, "closed", { merged });
    const beforeRequests = f.github.tokenRequests.length;
    await invoke(taskId);
    assert.deepEqual(f.github.tokenRequests.slice(beforeRequests), [
      { repository_ids: [10], permissions: { pull_requests: "read" } },
    ]);
    const rows = (await f.state()).buildJobs;
    const changed = rows.filter((job) => job.supersededByTaskId === taskId);
    assert.equal(changed.length, 3, "all workflows, SHAs and cancellation settings are covered");
    assert.ok(changed.every((job) => job.status === "CANCELLED"));
    assert.equal(changed.find((job) => job.id === running.id).completedAt, null);
    for (const expected of protectedRows)
      assert.deepEqual(
        rows.find((j) => j.id === expected.id),
        expected,
      );
    assert.deepEqual((await other.state()).buildJobs, otherRows);
    const notifications = await new DataConnectDispatchStore(getDispatchDataConnect()).superseded(
      taskId,
      "",
    );
    assert.deepEqual(new Set(notifications.map((j) => j.id)), new Set(changed.map((j) => j.id)));
    assert.equal(await invoke(taskId), "duplicate");
    await invoke(await prAction(f, "closed", { merged }));
    assert.deepEqual((await f.state()).buildJobs, rows);
  });
}

test("delayed close after reopen preserves valid jobs, while delayed planning after close publishes nothing", async (t) => {
  const f = await autoCancelFixture(t);
  const closeTask = await prAction(f, "closed");
  await invoke(await prAction(f, "reopened"));
  const before = (await f.state()).buildJobs;
  await invoke(closeTask);
  assert.deepEqual((await f.state()).buildJobs, before);
  await invoke(await prAction(f, "closed"));
  await invoke(f.taskId);
  const rows = (await f.state()).buildJobs;
  assert.equal(rows.length, before.length);
  assert.ok(rows.every((j) => j.status === "CANCELLED"));
});

test("a close observation overtaken by a reopen cannot cancel its new jobs", async (t) => {
  const f = await autoCancelFixture(t);
  await invoke(f.taskId);
  const closeTask = await prAction(f, "closed");
  const observed = Promise.withResolvers(),
    release = Promise.withResolvers();
  f.github.onPullRequest = async () => {
    observed.resolve();
    await release.promise;
  };
  const request = fetch(dartFunctionUrl, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ taskId: closeTask }),
  });
  let before;
  try {
    await Promise.race([
      observed.promise,
      request.then(() => assert.fail("observation not reached")),
    ]);
    await invoke(await prAction(f, "reopened"));
    before = (await f.state()).buildJobs;
  } finally {
    release.resolve();
  }
  assert.equal((await request).status, 200);
  assert.deepEqual((await f.state()).buildJobs, before);
  assert.equal(await invoke(closeTask), "duplicate");
  assert.deepEqual((await f.state()).buildJobs, before);
});

test("a close event fences an older planner that has already observed an open PR", async (t) => {
  const f = await autoCancelFixture(t);
  const observed = Promise.withResolvers(),
    release = Promise.withResolvers();
  f.github.onPullRequest = async () => {
    observed.resolve();
    await release.promise;
  };
  const request = fetch(dartFunctionUrl, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ taskId: f.taskId }),
  });
  try {
    await Promise.race([
      observed.promise,
      request.then(() => assert.fail("observation not reached")),
    ]);
    await invoke(await prAction(f, "closed"));
  } finally {
    release.resolve();
  }
  assert.equal((await request).status, 200);
  assert.equal(await invoke(f.taskId), "duplicate");
  assert.deepEqual((await f.state()).buildJobs, []);
});

test("closure cancellation requires an active connection and a valid fence with no planned work", async (t) => {
  const f = await autoCancelFixture(t);
  await invoke(f.taskId);
  const before = (await f.state()).buildJobs;
  const taskId = await prAction(f, "closed");
  const fence = await beginPlanning(f, taskId);
  const vars = {
    ...completion(f, taskId, fence),
    cancelClosedPullRequest: true,
    jobCount: 0,
    jobsJson: "[]",
  };
  for (const patch of [
    { planningId: null, planningToken: null },
    { pullRequestNumber: null },
    { ...completion(f, taskId, fence) },
  ])
    await assert.rejects(sdk.completeWebhookTask(dc, { ...vars, ...patch }));
  await graphql(
    'mutation Suspend($id: String!) { gitHubConnection_update(id: $id, data: { status: "suspended" }) }',
    { id: f.connectionId },
  );
  await assert.rejects(sdk.completeWebhookTask(dc, vars));
  assert.deepEqual((await f.state()).buildJobs, before);
});

test("reopening a cancelled PR creates one fresh validation and deduplicates its redeliveries", async (t) => {
  const f = await autoCancelFixture(t);
  await invoke(f.taskId);
  const original = (await f.state()).buildJobs;
  await invoke(await prAction(f, "closed"));
  await invoke(await prAction(f, "reopened"));
  const rows = (await f.state()).buildJobs;
  assert.equal(rows.length, 4);
  for (const job of original) assert.equal(rows.find((j) => j.id === job.id).status, "CANCELLED");
  assert.equal(rows.filter((job) => job.status === "QUEUED").length, 2);
  await invoke(await nextRevision(f, sha));
  assert.deepEqual((await f.state()).buildJobs, rows);
});
