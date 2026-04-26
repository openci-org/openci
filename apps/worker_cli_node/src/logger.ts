import { randomUUID } from "node:crypto";

import { appendLog } from "./dataconnect.js";

type LogLevel = "info" | "warning" | "error";

const queue: Promise<void>[] = [];

async function writeBuildLog(
  buildJobId: string,
  runId: string,
  level: LogLevel,
  message: string,
  stackTrace?: string,
): Promise<void> {
  const task = appendLog({
    buildJobId,
    runId,
    id: randomUUID(),
    message,
    level,
    timestamp: new Date().toISOString(),
    ...(stackTrace ? { stackTrace } : {}),
  }).catch((error: unknown) => {
    console.warn(`[BuildLog] Failed to write log: ${String(error)}`);
  });
  queue.push(task);
}

export async function flushLogs(): Promise<void> {
  while (queue.length > 0) {
    const batch = queue.splice(0, queue.length);
    await Promise.all(batch);
  }
}

export async function logInfo(buildJobId: string, runId: string, message: string): Promise<void> {
  console.log(message);
  await writeBuildLog(buildJobId, runId, "info", message);
}

export async function logWarning(buildJobId: string, runId: string, message: string): Promise<void> {
  console.warn(message);
  await writeBuildLog(buildJobId, runId, "warning", message);
}

export async function logError(
  buildJobId: string,
  runId: string,
  message: string,
  stackTrace?: string,
): Promise<void> {
  console.error(message);
  if (stackTrace) console.error(stackTrace);
  await writeBuildLog(buildJobId, runId, "error", message, stackTrace);
}

