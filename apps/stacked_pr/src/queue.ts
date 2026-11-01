import { createHash } from "node:crypto";
import { getApps, initializeApp } from "firebase-admin/app";
import { getFunctions, type TaskOptions } from "firebase-admin/functions";
import { type Environment, required } from "./config.js";
import { taskDeadlineSeconds } from "./limits.js";
import { type Job, object, RetryException } from "./models.js";

export const region = "asia-northeast1";
export const workerName = "stackedPrWorker";
interface QueueBackend {
  enqueue(data: Job, options: TaskOptions): Promise<void>;
}
export class TaskQueue {
  constructor(
    readonly backend: QueueBackend,
    readonly namespace: string,
    readonly notBefore?: Date,
  ) {
    if (notBefore && !Number.isFinite(notBefore.getTime()))
      throw new Error("Invalid STACKED_PR_RESUME_AT");
  }
  static fromEnvironment(env: Environment): TaskQueue {
    const projectId = env.GCLOUD_PROJECT || required(env, "GOOGLE_CLOUD_PROJECT");
    const serviceAccountId = required(env, "STACKED_PR_TASK_SERVICE_ACCOUNT");
    const appName = "stacked-pr-queue";
    // serviceAccountId selects the OIDC identity; ADC still authenticates the enqueuer.
    const app =
      getApps().find((a) => a.name === appName) ??
      initializeApp({ projectId, serviceAccountId }, appName);
    const queue = getFunctions(app).taskQueue<Job>(`locations/${region}/functions/${workerName}`);
    const resumeAt = env.STACKED_PR_RESUME_AT?.trim();
    return new TaskQueue(
      queue,
      `${required(env, "GITHUB_URL")}:${required(env, "GITHUB_APP_ID")}`,
      resumeAt ? new Date(resumeAt) : undefined,
    );
  }
  async enqueue(job: Job, timeoutMs = 8000): Promise<boolean> {
    if (Buffer.byteLength(JSON.stringify(job)) > 128 * 1024) throw new Error("Task too large");
    const id = createHash("sha256").update(`${this.namespace}:${job.id}`).digest("hex");
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {
      await Promise.race([
        this.backend.enqueue(job, {
          id,
          dispatchDeadlineSeconds: taskDeadlineSeconds,
          ...(this.notBefore && this.notBefore.getTime() > Date.now()
            ? { scheduleTime: this.notBefore }
            : {}),
        }),
        // A lost enqueue response is safe to retry because the task ID is stable.
        new Promise<never>((_, reject) => {
          timer = setTimeout(() => reject(new RetryException("Task enqueue timed out")), timeoutMs);
        }),
      ]);
      return true;
    } catch (error) {
      if (object(error).code === "functions/task-already-exists") return false;
      throw new RetryException("Task enqueue failed");
    } finally {
      clearTimeout(timer);
    }
  }
}
