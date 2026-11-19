import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { test } from "node:test";
import { mkdtemp, mkdir, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
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
const encode = (value) => Buffer.from(value).toString("base64");
const context = {
  schemaVersion: 1,
  event: "push",
  branch: "develop",
  repository: { owner: "openci-org", name: "openci", githubBaseUrl: "https://github.com" },
  commitSha: sha,
  checkoutSha: sha,
  runId: "run-123",
  jobId: "job-123",
};

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
  await mkdir(path.join(root, "firebase"));
  await writeFile(
    path.join(root, "firebase/firebase.json"),
    JSON.stringify({
      functions: [
        { codebase: "openci", source: ".", runtime: "nodejs22", ignore: [".env*"] },
        { codebase: "openci-planner", source: "dart_functions", runtime: "dart3" },
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
    FIREBASE_CLI_EXPERIMENTS: "dartfunctions",
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
    latest: sha,
    head: sha,
    conflicts: 0,
    waits: 0,
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
      if (executable === "git")
        return args[0] === "rev-parse" ? f.head : `${f.latest}\trefs/heads/develop`;
      assert.equal(executable, "npx");
      f.actions.push("deploy");
      assert.deepEqual(args, [
        "--yes",
        `firebase-tools@${firebaseToolsVersion}`,
        "deploy",
        "--config",
        path.join(root, "firebase/firebase.functions-cd.local.json"),
        "--project",
        projectId,
        "--only",
        "functions:openci",
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
      assert.equal(options.env.FIREBASE_CLI_EXPERIMENTS, undefined);
      const config = JSON.parse(await readFile(args[4], "utf8"));
      assert.deepEqual(Object.keys(config), ["functions"]);
      assert.equal(config.functions.length, 1);
      assert.equal(config.functions[0].codebase, "openci");
      assert.ok(config.functions[0].ignore.includes(".env*"));
      assert.ok(config.functions[0].ignore.includes("firebase.*.local.json"));
      assert.match(
        await readFile(path.join(root, `firebase/.env.${projectId}`), "utf8"),
        /GITHUB_APP_ID=1/,
      );
      if (f.fail === "deploy") throw new Error("deployment failed");
      return "";
    },
    async request(options) {
      f.requests.push(options);
      assert.equal(options.retry, false);
      const url = new URL(options.url);
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
      assert.equal(JSON.parse(options.data).sha, sha);
      return { data: {} };
    },
    async probe() {
      f.actions.push("probe");
      if (f.fail === "probe") throw new Error("smoke failed");
    },
  };
  f.run = () => deployFunctions(f.options);
  f.cleaned = async () => {
    for (const file of [
      f.credentialFile,
      path.join(root, `firebase/.env.${projectId}`),
      path.join(root, "firebase/firebase.functions-cd.local.json"),
    ].filter(Boolean)) {
      await assert.rejects(stat(file), { code: "ENOENT" });
    }
  };
  return f;
}

test("CD deploys only TS with private ADC, probes, records success, then unlocks and removes credentials", async (t) => {
  const f = await fixture(t);
  assert.equal(await f.run(), "deployed");
  assert.deepEqual(f.actions, ["lock", "deploy", "probe", "record", "unlock"]);
  await f.cleaned();
});

test("production credentials are never used for PRs, local runs or a different checkout", async (t) => {
  for (const change of [
    { event: "pull_request" },
    { branch: "feature/cd" },
    { checkoutSha: "b".repeat(40) },
    { repository: { ...context.repository, name: "other" } },
    { runId: "another-run" },
  ]) {
    const f = await fixture(t);
    f.environment.OPENCI_CONTEXT = JSON.stringify({ ...context, ...change });
    await assert.rejects(f.run(), /verified OpenCI develop push/);
    assert.equal(f.requests.length, 0);
  }
  const f = await fixture(t);
  f.head = "b".repeat(40);
  await assert.rejects(f.run(), /Checkout does not match/);
  assert.equal(f.requests.length, 0);
  delete f.environment.OPENCI_CONTEXT;
  await assert.rejects(f.run(), /verified OpenCI develop push/);
});

test("superseded pushes skip deployment after acquiring the lock", async (t) => {
  const f = await fixture(t);
  f.latest = "b".repeat(40);
  assert.equal(await f.run(), "superseded");
  assert.deepEqual(f.actions, ["lock", "unlock"]);
  await f.cleaned();
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
  for (const failure of ["deploy", "probe", "record"]) {
    const f = await fixture(t);
    f.fail = failure;
    await assert.rejects(f.run());
    assert.ok(!f.actions.includes("unlock"));
    assert.ok(!f.actions.includes("record"));
    await f.cleaned();
  }
});

test("pre-existing runtime files are preserved and a failure before deploying releases the lock", async (t) => {
  const f = await fixture(t);
  const file = path.join(f.root, `firebase/.env.${projectId}`);
  await writeFile(file, "existing configuration");
  await assert.rejects(f.run(), { code: "EEXIST" });
  assert.equal(await readFile(file, "utf8"), "existing configuration");
  assert.deepEqual(f.actions, ["lock", "unlock"]);
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
