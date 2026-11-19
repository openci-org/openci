import { spawn } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { fileURLToPath, pathToFileURL } from "node:url";
import { parseEnv } from "node:util";
import { GoogleAuth } from "google-auth-library";

export const projectId = "openci-b1b91";
export const serviceAccount = `openci-functions-cd@${projectId}.iam.gserviceaccount.com`;
export const lockBucket = `${projectId}-functions-cd`;
export const lockObject = "production/openci/lock.json";
export const successObject = "production/openci/last-success.json";
export const credentialVariable = "FIREBASE_FUNCTIONS_CD_SERVICE_ACCOUNT_JSON_BASE64";
export const environmentVariable = "FIREBASE_FUNCTIONS_CD_ENV_BASE64";
export const firebaseToolsVersion = "15.37.0";

function decoded(value) {
  if (typeof value !== "string" || !/^[A-Za-z0-9+/]+={0,2}$/.test(value)) {
    throw new Error("Functions CD credentials and runtime configuration are required");
  }
  const text = new TextDecoder("utf-8", { fatal: true }).decode(Buffer.from(value, "base64"));
  if (!text.trim() || text.includes("\0")) throw new Error("Invalid Functions CD configuration");
  return text;
}

export function deploymentContext(environment) {
  const context = JSON.parse(environment.OPENCI_CONTEXT ?? "null");
  if (
    context?.schemaVersion !== 1 ||
    context.event !== "push" ||
    context.branch !== "develop" ||
    context.repository?.owner !== "openci-org" ||
    context.repository?.name !== "openci" ||
    context.repository?.githubBaseUrl !== "https://github.com" ||
    !/^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(context.commitSha ?? "") ||
    context.commitSha !== context.checkoutSha ||
    typeof context.runId !== "string" ||
    !context.runId ||
    context.runId !== environment.OPENCI_RUN_ID ||
    typeof context.jobId !== "string" ||
    !context.jobId ||
    context.jobId !== environment.OPENCI_BUILD_JOB_ID
  ) {
    throw new Error("Functions CD requires a verified OpenCI develop push");
  }
  return context;
}

function uploadUrl(object, createOnly = false) {
  const url = new URL(`https://storage.googleapis.com/upload/storage/v1/b/${lockBucket}/o`);
  url.searchParams.set("uploadType", "media");
  url.searchParams.set("name", object);
  if (createOnly) url.searchParams.set("ifGenerationMatch", "0");
  return url.toString();
}

function command(executable, args, { cwd, env, capture = false }) {
  return new Promise((resolve, reject) => {
    const child = spawn(executable, args, {
      cwd,
      env,
      stdio: ["ignore", capture ? "pipe" : "inherit", "inherit"],
    });
    let output = "";
    child.stdout?.on("data", (data) => {
      output = (output + data.toString()).slice(-4096);
    });
    child.on("error", () => reject(new Error("CD command could not start")));
    child.on("close", (code) => {
      if (code === 0) resolve(output.trim());
      else reject(new Error("CD command failed"));
    });
  });
}

function deploymentCodebase(entries, codebase, source, runtime) {
  const matches = entries.filter((entry) => entry.codebase === codebase);
  if (matches.length !== 1 || matches[0].source !== source || matches[0].runtime !== runtime) {
    throw new Error(`Unexpected configuration for Functions codebase ${codebase}`);
  }
  const entry = matches[0];
  const ignore = new Set([
    ...(entry.ignore ?? []),
    ".env*",
    ".secret.local",
    ".deploy",
    "firebase.*.local.json",
  ]);
  if (source === ".") ignore.add("dart_functions");
  return { ...entry, ignore: [...ignore] };
}

function plannerDotenv(values, invoker) {
  // The planner shares the GitHub App and Data Connect service with Node.
  const settings = {
    GITHUB_APP_ID: values.GITHUB_APP_ID,
    GITHUB_API_BASE_URL: values.GITHUB_API_BASE_URL,
    GITHUB_BASE_URL: values.GITHUB_BASE_URL,
    OPENCI_DATA_CONNECT_SERVICE_ID: values.OPENCI_DATA_CONNECT_SERVICE_ID,
    OPENCI_PLANNER_SERVICE_ACCOUNT: values.OPENCI_PLANNER_SERVICE_ACCOUNT,
    OPENCI_PLANNER_INVOKER: invoker,
  };
  return (
    Object.entries(settings)
      .filter(([, value]) => value !== undefined)
      .map(([name, value]) => `${name}=${JSON.stringify(value)}`)
      .join("\n") + "\n"
  );
}

async function smokeCheck(plannerUrl, invoker, send, get) {
  // GET cannot create a webhook or start a planning task.
  const webhookUrl = `https://asia-northeast1-${projectId}.cloudfunctions.net/githubWebhookFsc`;
  for (const [url, expected] of [
    [webhookUrl, 405],
    [plannerUrl, 403],
  ]) {
    const response = await get(url, {
      method: "GET",
      redirect: "error",
      signal: AbortSignal.timeout(30000),
    });
    await response.body?.cancel();
    if (response.status !== expected) throw new Error("Functions smoke check failed");
  }
  const service = `projects/${projectId}/locations/asia-northeast1/services/process-webhook-task`;
  const { data } = await send({
    url: `https://run.googleapis.com/v2/${service}:getIamPolicy?options.requestedPolicyVersion=3`,
    method: "GET",
  });
  const bindings = data.bindings?.filter((binding) => binding.role === "roles/run.invoker") ?? [];
  const [binding] = bindings;
  if (
    bindings.length !== 1 ||
    binding.condition ||
    binding.members?.length !== 1 ||
    binding.members[0] !== `serviceAccount:${invoker}`
  ) {
    throw new Error("Planner is missing its private Node caller binding");
  }
}

/** An interrupted/failed deployment deliberately retains its lock for recovery. */
export async function deployFunctions({
  root,
  environment = process.env,
  run = command,
  request,
  get = fetch,
  wait = delay,
  lockAttempts = 120,
  log = console.log,
}) {
  const context = deploymentContext(environment);
  const gitOptions = { cwd: root, env: environment, capture: true };
  if ((await run("git", ["rev-parse", "HEAD"], gitOptions)) !== context.checkoutSha) {
    throw new Error("Checkout does not match the tested commit");
  }
  const credentialText = decoded(environment[credentialVariable]);
  const credentials = JSON.parse(credentialText);
  if (
    credentials.type !== "service_account" ||
    credentials.project_id !== projectId ||
    credentials.client_email !== serviceAccount ||
    typeof credentials.private_key !== "string" ||
    !credentials.private_key
  ) {
    throw new Error("Functions CD requires its dedicated production service account");
  }
  const runtimeEnvironment = decoded(environment[environmentVariable]);
  const values = parseEnv(runtimeEnvironment);
  for (const name of [
    "GITHUB_APP_ID",
    "PROCESS_WEBHOOK_TASK_URL",
    "ORCHARD_API_URL",
    "ORCHARD_SERVICE_ACCOUNT_NAME",
    "BUILD_EXECUTOR_JOB",
  ]) {
    if (!values[name]?.trim()) {
      throw new Error("Functions CD runtime configuration is incomplete");
    }
  }
  const invoker =
    values.OPENCI_API_SERVICE_ACCOUNT ?? `openci-functions@${projectId}.iam.gserviceaccount.com`;
  if (!/^[a-z][a-z0-9-]*@openci-b1b91\.iam\.gserviceaccount\.com$/.test(invoker)) {
    throw new Error("Functions CD requires a production API service account for the planner");
  }
  const base = JSON.parse(await readFile(path.join(root, "firebase/firebase.json"), "utf8"));
  const configuration = {
    functions: [
      deploymentCodebase(base.functions, "openci", ".", "nodejs22"),
      deploymentCodebase(base.functions, "openci-planner", "dart_functions", "dart3"),
    ],
  };
  const auth = new GoogleAuth({
    credentials,
    scopes: ["https://www.googleapis.com/auth/cloud-platform"],
  });
  const send = (options) =>
    (request ?? ((options) => auth.request(options)))({
      ...options,
      timeout: 30000,
      retry: false,
      maxRedirects: 0,
    });
  const record = { sha: context.checkoutSha, runId: context.runId, jobId: context.jobId };
  let generation;
  log("Waiting for the production Functions deployment lock.");
  for (let attempt = 0; attempt < lockAttempts; attempt++) {
    try {
      const { data } = await send({
        url: uploadUrl(lockObject, true),
        method: "POST",
        headers: { "content-type": "application/json" },
        data: JSON.stringify({ ...record, startedAt: new Date().toISOString() }),
      });
      if (!/^[1-9][0-9]*$/.test(data?.generation ?? "")) {
        throw new Error("Deployment lock ownership could not be confirmed");
      }
      generation = data.generation;
      break;
    } catch (error) {
      if (error?.response?.status !== 412) throw error;
      if (attempt + 1 < lockAttempts) await wait(10000);
    }
  }
  if (!generation) throw new Error("Production deployment is locked; inspect the current run");

  let startedDeployment = false;
  let finishedDeployment = false;
  let temporary;
  const createdFiles = [];
  try {
    const ref = await run(
      "git",
      ["ls-remote", "https://github.com/openci-org/openci.git", "refs/heads/develop"],
      gitOptions,
    );
    const match = /^([a-f0-9]{40}(?:[a-f0-9]{24})?)\s+refs\/heads\/develop$/.exec(ref);
    if (!match) throw new Error("Could not verify the current develop commit");
    if (match[1] !== context.checkoutSha) {
      log("A newer develop commit exists; skipping this deployment.");
      return "superseded";
    }

    temporary = await mkdtemp(path.join(tmpdir(), "openci-functions-cd-"));
    const credentialFile = path.join(temporary, "service-account.json");
    await writeFile(credentialFile, credentialText, { mode: 0o600, flag: "wx" });
    const configurationFile = path.join(root, "firebase/firebase.functions-cd.local.json");
    for (const [file, contents] of [
      [path.join(root, `firebase/.env.${projectId}`), runtimeEnvironment],
      [
        path.join(root, `firebase/dart_functions/.env.${projectId}`),
        plannerDotenv(values, invoker),
      ],
      [configurationFile, JSON.stringify(configuration)],
    ]) {
      await writeFile(file, contents, { mode: 0o600, flag: "wx" });
      createdFiles.push(file);
    }
    const childEnvironment = {
      ...environment,
      GOOGLE_APPLICATION_CREDENTIALS: credentialFile,
      XDG_CONFIG_HOME: path.join(temporary, "config"),
      CI: "true",
      FIREBASE_CLI_EXPERIMENTS: "dartfunctions",
      // The CLI probes the default App Engine account even when every function
      // specifies a runtime identity. Google Cloud checks each actual deployment.
      FIREBASE_SKIP_INFORMATIONAL_IAM: "true",
    };
    delete childEnvironment[credentialVariable];
    delete childEnvironment[environmentVariable];
    delete childEnvironment.FIREBASE_TOKEN;
    log(`Deploying TypeScript and Dart Functions from ${context.checkoutSha}.`);
    // Even a failed CLI can have started asynchronous updates. Never unlock it
    // automatically on an error, timeout, or process interruption after here.
    startedDeployment = true;
    await run(
      "npm",
      [
        "exec",
        "--yes",
        `--package=firebase-tools@${firebaseToolsVersion}`,
        "--",
        "firebase",
        "deploy",
        "--config",
        configurationFile,
        "--project",
        projectId,
        "--only",
        "functions:openci,functions:openci-planner",
        "--non-interactive",
      ],
      { cwd: root, env: childEnvironment },
    );
    await smokeCheck(values.PROCESS_WEBHOOK_TASK_URL, invoker, send, get);
    await send({
      url: uploadUrl(successObject),
      method: "POST",
      headers: { "content-type": "application/json" },
      data: JSON.stringify({ ...record, completedAt: new Date().toISOString() }),
    });
    finishedDeployment = true;
    log(`Functions deployed successfully: ${context.checkoutSha}.`);
    return "deployed";
  } finally {
    try {
      for (const file of createdFiles) await rm(file, { force: true });
      if (temporary) await rm(temporary, { recursive: true, force: true });
    } finally {
      if (!startedDeployment || finishedDeployment) {
        await send({
          url:
            `https://storage.googleapis.com/storage/v1/b/${lockBucket}/o/` +
            `${encodeURIComponent(lockObject)}?ifGenerationMatch=${generation}`,
          method: "DELETE",
        });
      } else {
        log("Production lock retained. Inspect Functions operations before recovery.");
      }
    }
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    await deployFunctions({
      root: path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../.."),
    });
  } catch {
    // Google SDK errors may include request headers. Do not print raw errors.
    console.error("Functions CD failed. Check the preceding stage and production deployment lock.");
    process.exitCode = 1;
  }
}
