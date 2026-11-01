import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { HttpsError } from "firebase-functions/v2/https";
import { configFromEnvironment, type Environment } from "./config.js";
import { Deadline } from "./deadline.js";
import { GitException } from "./git.js";
import { ApiException, GitHubApi } from "./github.js";
import { type Job, object, RetryException } from "./models.js";
import { TaskQueue } from "./queue.js";
import { Reporter } from "./report.js";
import { Service } from "./service.js";

export async function processTask(
  data: unknown,
  process: (job: Job) => Promise<void>,
): Promise<void> {
  const value = object(data);
  if (
    typeof value.id !== "string" ||
    !/^[\w-]{1,160}$/.test(value.id) ||
    typeof value.event !== "string" ||
    value.payload === null ||
    typeof value.payload !== "object" ||
    Array.isArray(value.payload)
  ) {
    throw new HttpsError("invalid-argument", "Invalid task");
  }
  if (Buffer.byteLength(JSON.stringify(value)) > 128 * 1024)
    throw new HttpsError("invalid-argument", "Task too large");
  try {
    await process({ id: value.id, event: value.event, payload: object(value.payload) });
  } catch (error) {
    // Only our sanitized error types may contribute diagnostics. SDK errors can
    // retain tokens, request bodies, and repository contents.
    const failure =
      error instanceof GitException
        ? { source: "git", command: error.command, reason: error.reason }
        : error instanceof ApiException
          ? { source: "github", method: error.method, status: error.status }
          : error instanceof RetryException
            ? { source: "retry", reason: error.message }
            : { source: "runtime" };
    console.error(JSON.stringify({ event: "stack_task_failed", delivery: value.id, ...failure }));
    // Prevent the SDK from logging transport exceptions containing credentials/payloads.
    throw new HttpsError("unavailable", "Retry task");
  }
}
export async function runJob(job: Job, env: Environment): Promise<void> {
  const directory = await mkdtemp(join(tmpdir(), "stacked-pr-"));
  let api: GitHubApi | undefined;
  let queue: TaskQueue | undefined;
  try {
    const deadline = new Deadline(420_000),
      config = configFromEnvironment(env, directory);
    if (!config.allowedRepos.size)
      throw new Error("ALLOWED_REPOSITORIES must name the target repositories");
    api = new GitHubApi(config, { deadline, environment: env });
    await new Service({
      config,
      api,
      reporter: new Reporter(api),
      deadline,
      enqueue: (job) => {
        const timeout = deadline.limit(8000);
        queue ??= TaskQueue.fromEnvironment(env);
        return queue.enqueue(job, timeout);
      },
    }).handle(job);
  } finally {
    try {
      await api?.close();
    } finally {
      await rm(directory, { recursive: true, force: true });
    }
  }
}
