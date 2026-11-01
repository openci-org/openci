import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { createServer } from "node:net";
import { createHmac } from "node:crypto";
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { setTimeout as delay } from "node:timers/promises";
import { secret, testKey } from "../test/support/fixtures.mjs";

const require = createRequire(import.meta.url);
const framework = join(dirname(require.resolve("@google-cloud/functions-framework")), "main.js");
const directory = fileURLToPath(new URL("..", import.meta.url));
const env = {
  PATH: process.env.PATH,
  GCLOUD_PROJECT: "demo-stacked-pr",
  FUNCTIONS_EMULATOR: "true",
  STACKED_PR_RUNTIME_SERVICE_ACCOUNT: "stacked-pr-runtime@demo-stacked-pr.iam.gserviceaccount.com",
  STACKED_PR_TASK_SERVICE_ACCOUNT: "stacked-pr-tasks@demo-stacked-pr.iam.gserviceaccount.com",
  STACKED_PR_GITHUB_PRIVATE_KEY: testKey,
  STACKED_PR_WEBHOOK_SECRET: secret,
  GITHUB_URL: "https://git.example.com",
  GITHUB_APP_ID: "7",
  ALLOWED_REPOSITORIES: "org/repo",
};

async function withFunction(target, check) {
  const socket = createServer();
  socket.listen(0, "127.0.0.1");
  await once(socket, "listening");
  const port = socket.address().port;
  await new Promise((resolve) => socket.close(resolve));
  const child = spawn(
    process.execPath,
    [framework, "--source", directory, "--target", target, "--port", String(port)],
    { cwd: directory, env, stdio: ["ignore", "pipe", "pipe"] },
  );
  child.stdout.resume();
  let errors = "";
  child.stderr.on("data", (chunk) => {
    errors = (errors + chunk).slice(-4000);
  });
  const exited = once(child, "exit");
  const url = `http://127.0.0.1:${port}`;
  try {
    let ready = false;
    for (let attempt = 0; attempt < 100; attempt++) {
      if (child.exitCode !== null) throw new Error(`Function failed to load: ${errors}`);
      try {
        await fetch(url, { signal: AbortSignal.timeout(500) });
        ready = true;
        break;
      } catch {
        await delay(100);
      }
    }
    assert.ok(ready, "Functions Framework did not start");
    await check(url);
  } finally {
    child.kill("SIGTERM");
    const timer = setTimeout(() => child.kill("SIGKILL"), 3000);
    await exited;
    clearTimeout(timer);
  }
}

await withFunction("stackedPrWorker", async (url) => {
  const post = (body) =>
    fetch(url, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    });
  assert.equal((await post({})).status, 400);
  assert.equal((await post({ data: {} })).status, 400);
  // No installation means no GitHub/Cloud Tasks access; exercise the real SDK envelope.
  assert.equal(
    (await post({ data: { id: "smoke", event: "reconcile", payload: {} } })).status,
    204,
  );
});
await withFunction("stackedPrWebhook", async (url) => {
  const body = `  ${JSON.stringify({ zen: "こんにちは" })}\n`;
  const headers = {
    "content-type": "application/json",
    "x-github-event": "ping",
    "x-github-delivery": "smoke",
  };
  assert.equal((await fetch(url, { method: "POST", headers, body })).status, 400);
  headers["x-hub-signature-256"] =
    `sha256=${createHmac("sha256", secret).update(body).digest("hex")}`;
  assert.equal((await fetch(url, { method: "POST", headers, body })).status, 200);
  assert.equal((await fetch(url, { method: "POST", headers, body: body + " " })).status, 400);
});

// Exercise the production Git adapter with the Git installed in this runtime.
const gitTests = spawn(process.execPath, ["--test", "integration_test/git.test.mjs"], {
  cwd: directory,
  stdio: "inherit",
});
const [exitCode] = await once(gitTests, "exit");
assert.equal(exitCode, 0, "Runtime Git checks failed");
console.log("Functions Framework HTTP handlers and Git restack checks passed");
