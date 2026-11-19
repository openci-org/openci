import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { test } from "node:test";
import { mkdtemp, mkdir, readFile, rm, stat, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseEnv } from "node:util";
import {
  credentialVariable,
  deployFunctions,
  environmentVariable,
  firebaseToolsVersion,
  lockObject,
  projectId,
  serviceAccount,
  successObject,
} from "../../scripts/deploy-functions.mjs";

const sha = "a".repeat(40);
const tag = "v2.6.0";
const caller = `openci-functions@${projectId}.iam.gserviceaccount.com`;
const encode = (value) => Buffer.from(value).toString("base64");
const context = {
  schemaVersion: 1,
  event: "push",
  branch: `refs/tags/${tag}`,
  repository: { owner: "openci-org", name: "openci", githubBaseUrl: "https://github.com" },
  commitSha: sha,
  checkoutSha: sha,
  runId: "run-123",
  jobId: "job-123",
};

test("CD finds the image's mise Node installation before invoking npm or npx", async (t) => {
  const home = await mkdtemp(path.join(tmpdir(), "functions-cd-node-"));
  t.after(() => rm(home, { recursive: true, force: true }));
  const miseBin = path.join(home, ".local/bin");
  const nodeBin = path.join(home, "installed node/bin");
  await mkdir(miseBin, { recursive: true });
  await mkdir(nodeBin, { recursive: true });
  const repo = new URL("../../../", import.meta.url);
  const pin = (await readFile(new URL(".node-version", repo), "utf8")).trim();
  await writeFile(
    path.join(miseBin, "mise"),
    `#!/bin/sh
[ "$1" = where ] && [ "$2" = "node@${pin}" ] || exit 1
echo "$HOME/installed node"
`,
    { mode: 0o755 },
  );
  for (const tool of ["node", "npm", "npx"]) await symlink("/bin/echo", path.join(nodeBin, tool));
  // Only provide the OS utilities the bootstrap uses. Even the host's npm is unavailable.
  await symlink("/bin/cat", path.join(home, "cat"));
  await symlink("/usr/bin/dirname", path.join(home, "dirname"));
  const result = spawnSync(
    "/bin/bash",
    [
      fileURLToPath(new URL("openci/tool/with_node.sh", repo)),
      "/bin/sh",
      "-c",
      "command -v npm && command -v npx",
    ],
    { env: { HOME: home, PATH: home }, encoding: "utf8" },
  );
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(result.stdout.trim().split("\n"), [
    path.join(nodeBin, "npm"),
    path.join(nodeBin, "npx"),
  ]);
});

test("the deployment script runs directly and refuses execution outside CI", () => {
  const result = spawnSync(
    process.execPath,
    [fileURLToPath(new URL("../../scripts/deploy-functions.mjs", import.meta.url))],
    { env: {}, encoding: "utf8" },
  );
  assert.equal(result.status, 1);
  assert.match(result.stderr, /^Functions CD failed\./);
  assert.equal(result.stdout, "");
});

async function fixture(t) {
  const root = await mkdtemp(path.join(tmpdir(), "functions-cd-test-"));
  t.after(() => rm(root, { recursive: true, force: true }));
  await mkdir(path.join(root, "firebase/dart_functions"), { recursive: true });
  await writeFile(
    path.join(root, "firebase/firebase.json"),
    JSON.stringify({
      functions: [
        { codebase: "openci", source: ".", runtime: "nodejs22", ignore: [".env*"] },
        { codebase: "openci-planner", source: "dart_functions", runtime: "dart3" },
        { codebase: "unrelated", source: "other", runtime: "nodejs22" },
      ],
      hosting: { site: "dashboard-openci" },
      dataconnect: { source: "dataconnect" },
    }),
  );
  const environment = {
    OPENCI_CONTEXT: JSON.stringify(context),
    OPENCI_RUN_ID: context.runId,
    OPENCI_BUILD_JOB_ID: context.jobId,
    FIREBASE_TOKEN: "must-not-be-used",
    FIREBASE_CLI_EXPERIMENTS: "unrelated",
    [credentialVariable]: encode(
      JSON.stringify({
        type: "service_account",
        project_id: projectId,
        client_email: serviceAccount,
        private_key: "test-private-key",
      }),
    ),
    [environmentVariable]: encode(
      [
        "GITHUB_APP_ID=1",
        "GITHUB_BASE_URL=https://github.com",
        "PROCESS_WEBHOOK_TASK_URL=https://planner.example",
        "ORCHARD_API_URL=https://orchard.example",
        "ORCHARD_SERVICE_ACCOUNT_NAME=ci",
        "BUILD_EXECUTOR_JOB=projects/openci-b1b91/locations/asia-northeast1/jobs/executor",
      ].join("\n"),
    ),
  };
  const f = {
    root,
    environment,
    actions: [],
    requests: [],
    latest: { tag_name: tag, draft: false, prerelease: false },
    releaseStatus: 200,
    tagSha: sha,
    annotatedTagSha: null,
    head: sha,
    conflicts: 0,
    waits: 0,
    bindings: [{ role: "roles/run.invoker", members: [`serviceAccount:${caller}`] }],
    credentialFile: undefined,
    fail: undefined,
  };
  f.options = {
    root,
    environment,
    lockAttempts: 3,
    log() {},
    async wait() {
      f.waits++;
    },
    async run(executable, args, options) {
      if (executable === "git") {
        if (args[0] === "rev-parse") return f.head;
        const ref = context.branch;
        assert.deepEqual(args, [
          "ls-remote",
          "--exit-code",
          "https://github.com/openci-org/openci.git",
          ref,
          `${ref}^{}`,
        ]);
        f.actions.push("tag");
        return f.annotatedTagSha
          ? `${f.annotatedTagSha}\t${ref}\n${f.tagSha}\t${ref}^{}`
          : `${f.tagSha}\t${ref}`;
      }
      assert.equal(executable, "npm");
      f.actions.push("deploy");
      const configPath = path.join(root, "firebase/firebase.functions-cd.local.json");
      assert.deepEqual(args, [
        "exec",
        "--yes",
        `--package=firebase-tools@${firebaseToolsVersion}`,
        "--",
        "firebase",
        "deploy",
        "--config",
        configPath,
        "--project",
        projectId,
        "--only",
        "functions:openci,functions:openci-planner",
        "--non-interactive",
      ]);
      assert.equal(options.cwd, root);
      f.credentialFile = options.env.GOOGLE_APPLICATION_CREDENTIALS;
      assert.equal(
        JSON.parse(await readFile(f.credentialFile, "utf8")).client_email,
        serviceAccount,
      );
      assert.equal((await stat(f.credentialFile)).mode & 0o777, 0o600);
      assert.equal(options.env[credentialVariable], undefined);
      assert.equal(options.env[environmentVariable], undefined);
      assert.equal(options.env.FIREBASE_TOKEN, undefined);
      assert.equal(options.env.FIREBASE_CLI_EXPERIMENTS, "dartfunctions");
      assert.equal(options.env.FIREBASE_SKIP_INFORMATIONAL_IAM, "true");
      const config = JSON.parse(await readFile(configPath, "utf8"));
      assert.deepEqual(Object.keys(config), ["functions"]);
      assert.deepEqual(
        config.functions.map((entry) => entry.codebase),
        ["openci", "openci-planner"],
      );
      assert.ok(config.functions[0].ignore.includes("dart_functions"));
      assert.ok(config.functions[1].ignore.includes(".env*"));
      assert.ok(config.functions[0].ignore.includes(".env*"));
      assert.ok(config.functions[0].ignore.includes("firebase.*.local.json"));
      assert.match(
        await readFile(path.join(root, `firebase/.env.${projectId}`), "utf8"),
        /GITHUB_APP_ID=1/,
      );
      const dotenv = path.join(root, `firebase/dart_functions/.env.${projectId}`);
      assert.equal((await stat(dotenv)).mode & 0o777, 0o600);
      f.plannerSettings = parseEnv(await readFile(dotenv, "utf8"));
      if (f.fail === "deploy") throw new Error("deployment failed");
      return "";
    },
    async request(options) {
      f.requests.push(options);
      assert.equal(options.retry, false);
      const url = new URL(options.url);
      if (options.method === "GET") {
        assert.equal(
          url.href,
          `https://run.googleapis.com/v2/projects/${projectId}/locations/asia-northeast1/services/process-webhook-task:getIamPolicy?options.requestedPolicyVersion=3`,
        );
        f.actions.push("policy");
        return { data: { bindings: f.bindings } };
      }
      if (options.method === "DELETE") {
        assert.equal(url.searchParams.get("ifGenerationMatch"), "123");
        assert.ok(decodeURIComponent(url.pathname).endsWith(lockObject));
        f.actions.push("unlock");
        return { data: {} };
      }
      if (url.searchParams.get("name") === lockObject) {
        assert.equal(url.searchParams.get("ifGenerationMatch"), "0");
        if (f.conflicts-- > 0)
          throw Object.assign(new Error("busy"), { response: { status: 412 } });
        f.actions.push("lock");
        return { data: { generation: "123" } };
      }
      assert.equal(url.searchParams.get("name"), successObject);
      if (f.fail === "record") throw new Error("record failed");
      f.actions.push("record");
      const { completedAt, ...record } = JSON.parse(options.data);
      assert.deepEqual(record, { sha, tag, runId: context.runId, jobId: context.jobId });
      assert.ok(Number.isFinite(Date.parse(completedAt)));
      return { data: {} };
    },
    async get(url, options) {
      assert.equal(options.method, "GET");
      assert.equal(options.redirect, "error");
      if (url === "https://api.github.com/repos/openci-org/openci/releases/latest") {
        assert.equal(options.cache, "no-store");
        f.actions.push("latest");
        return f.releaseStatus === 200
          ? Response.json(f.latest)
          : new Response(null, { status: f.releaseStatus });
      }
      assert.equal(options.headers, undefined);
      if (url === "https://planner.example") {
        f.actions.push("planner");
        return new Response(null, { status: f.fail === "planner" ? 405 : 403 });
      }
      assert.equal(url, `https://asia-northeast1-${projectId}.cloudfunctions.net/githubWebhookFsc`);
      f.actions.push("webhook");
      return new Response(null, { status: f.fail === "webhook" ? 500 : 405 });
    },
  };
  f.run = () => deployFunctions(f.options);
  f.cleaned = async () => {
    for (const file of [
      f.credentialFile,
      path.join(root, `firebase/.env.${projectId}`),
      path.join(root, `firebase/dart_functions/.env.${projectId}`),
      path.join(root, "firebase/firebase.functions-cd.local.json"),
    ].filter(Boolean)) {
      await assert.rejects(stat(file), { code: "ENOENT" });
    }
  };
  return f;
}

test("CD deploys both codebases and verifies the private planner before recording success", async (t) => {
  const f = await fixture(t);
  f.annotatedTagSha = "c".repeat(40);
  assert.equal(await f.run(), "deployed");
  assert.deepEqual(f.actions, [
    "lock",
    "latest",
    "tag",
    "deploy",
    "webhook",
    "planner",
    "policy",
    "record",
    "unlock",
  ]);
  assert.deepEqual(f.plannerSettings, {
    GITHUB_APP_ID: "1",
    GITHUB_BASE_URL: "https://github.com",
    OPENCI_PLANNER_INVOKER: caller,
  });
  await f.cleaned();
});

test("only a release tag context can reach production", async (t) => {
  for (const change of [
    { event: "pull_request" },
    { branch: "feature/cd" },
    { branch: "develop" },
    { branch: "refs/tags/" },
    { checkoutSha: "b".repeat(40) },
    { repository: { ...context.repository, name: "other" } },
    { runId: "another-run" },
  ]) {
    const f = await fixture(t);
    f.environment.OPENCI_CONTEXT = JSON.stringify({ ...context, ...change });
    await assert.rejects(f.run(), /requires an OpenCI release tag/);
    assert.equal(f.requests.length, 0);
  }
  const f = await fixture(t);
  f.head = "b".repeat(40);
  await assert.rejects(f.run(), /Checkout does not match/);
  assert.equal(f.requests.length, 0);
  delete f.environment.OPENCI_CONTEXT;
  await assert.rejects(f.run(), /requires an OpenCI release tag/);
});

test("a newer stable release published while waiting supersedes deployment", async (t) => {
  const f = await fixture(t);
  f.conflicts = 1;
  f.options.wait = async () => {
    f.latest.tag_name = "v2.6.1";
  };
  assert.equal(await f.run(), "superseded");
  assert.deepEqual(f.actions, ["lock", "latest", "unlock"]);
  await f.cleaned();
});

test("a moved tag or failed release lookup stops deployment and releases the lock", async (t) => {
  const moved = await fixture(t);
  moved.tagSha = "b".repeat(40);
  await assert.rejects(moved.run(), /Release tag does not match the tested commit/);
  assert.deepEqual(moved.actions, ["lock", "latest", "tag", "unlock"]);
  const unavailable = await fixture(t);
  unavailable.releaseStatus = 503;
  await assert.rejects(unavailable.run(), /Could not read the latest OpenCI release/);
  assert.deepEqual(unavailable.actions, ["lock", "latest", "unlock"]);
});

test("concurrent deployments wait for the generation lock and fail closed when it remains held", async (t) => {
  const f = await fixture(t);
  f.conflicts = 2;
  await f.run();
  assert.equal(f.waits, 2);
  const blocked = await fixture(t);
  blocked.conflicts = 4;
  await assert.rejects(blocked.run(), /deployment is locked/);
  assert.deepEqual(blocked.actions, []);
});

test("deployment, smoke and success-record failures retain the lock but remove local secrets", async (t) => {
  for (const failure of ["deploy", "webhook", "planner", "record"]) {
    const f = await fixture(t);
    f.fail = failure;
    await assert.rejects(f.run());
    assert.ok(!f.actions.includes("unlock"));
    assert.ok(!f.actions.includes("record"));
    await f.cleaned();
  }
});

test("missing or public planner caller policies retain the lock", async (t) => {
  for (const members of [[], ["allUsers"], [`serviceAccount:${caller}`, "allAuthenticatedUsers"]]) {
    const f = await fixture(t);
    f.bindings = [{ role: "roles/run.invoker", members }];
    await assert.rejects(f.run(), /private Node caller/);
    assert.ok(!f.actions.includes("unlock"));
    assert.ok(!f.actions.includes("record"));
    await f.cleaned();
  }
});

test("an unexpected planner source or a public caller fails before taking the lock", async (t) => {
  const f = await fixture(t);
  const file = path.join(f.root, "firebase/firebase.json");
  const config = JSON.parse(await readFile(file, "utf8"));
  config.functions[1].source = "other";
  await writeFile(file, JSON.stringify(config));
  await assert.rejects(f.run(), /configuration for Functions codebase openci-planner/);
  const dotenv = Buffer.from(f.environment[environmentVariable], "base64").toString("utf8");
  f.environment[environmentVariable] = encode(`${dotenv}\nOPENCI_API_SERVICE_ACCOUNT=public`);
  await assert.rejects(f.run(), /production API service account/);
  assert.equal(f.requests.length, 0);
});

test("pre-existing runtime files are preserved and a failure before deploying releases the lock", async (t) => {
  const f = await fixture(t);
  const file = path.join(f.root, `firebase/.env.${projectId}`);
  await writeFile(file, "existing configuration");
  await assert.rejects(f.run(), { code: "EEXIST" });
  assert.equal(await readFile(file, "utf8"), "existing configuration");
  assert.deepEqual(f.actions, ["lock", "latest", "tag", "unlock"]);
});

test("missing configuration and unrelated service accounts fail before touching production", async (t) => {
  for (const name of [credentialVariable, environmentVariable]) {
    const f = await fixture(t);
    delete f.environment[name];
    await assert.rejects(f.run());
    assert.equal(f.requests.length, 0);
  }
  const f = await fixture(t);
  f.environment[credentialVariable] = encode(
    JSON.stringify({
      type: "service_account",
      project_id: projectId,
      client_email: "other@example.com",
      private_key: "key",
    }),
  );
  await assert.rejects(f.run(), /dedicated production service account/);
  assert.equal(f.requests.length, 0);
});
